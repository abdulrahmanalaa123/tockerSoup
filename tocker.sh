#!/bin/bash

# excessive use of declare to ensure block scoping 
# set the script to exit on error and error on unset vars and return 1 if one pipeline command fail

set -o errexit -o pipefail; shopt -s nullglob
#set -o nounset -o pipefail; shopt -s nullglob
. ./helpers.sh

tocker_pull() {
	declare image=$1
	#modification because it messes with tar and calls a repo for some reason
	declare image_name_modified=$(image_name_formatter $image)
	
	if [[ -n $(sed -nE '/docker.io/p' ~/.docker/config.json) ]]
	then
		declare out_path="$OUT_PATH/$image_name_modified.tar.gz"
		declare env_file="$IMAGE_META_PATH/$image_name_modified.env"
		if [[ -e $out_path ]]
		then
			echo "image $image already exists"
			return 1
		fi
		declare temp_cont=$(docker create $image)

		entry_point=$(docker inspect --type=image --format='{{json .Config.Entrypoint}} {{json .Config.Cmd}}' $image)
		#removing nulls and quotations
 		#entry_point=${entry_point//[\"\[\]]/}
 		entry_point=${entry_point//^\"[\[\]]\"$/}
		entry_point=${entry_point//null/}
		# get all the environmental variables of the image
		environment_vars=$(docker inspect --type=image --format='{{json .Config.Env}}' $image)
		# remove square brackets and sperate on ", which indicates a new environmental variable to not contradict any variable with commas inside the variable value 
 		environment_vars=${environment_vars//[\[\]]/}
		environment_vars=${environment_vars//\",/ }
		# finally remove extra quotations
		environment_vars=(${environment_vars//\"/})
		docker container export $temp_cont |  tee $out_path > /dev/null 2>&1
		docker container rm $temp_cont && docker image rm $image 

		echo "ENTRYPOINT=$entry_point" > $env_file
		for env in $environment_vars
		do
			echo $env >> $env_file
		done
		tocker_add_image $image_name_modified 
	else
		echo "please login into docker first"
	fi
}

tocker_start () {
	#Substring expanision	
	declare input=${@: -1}
	declare id=$(get_full_id $input)

	if [[ -z $id ]]; then
		echo  "contianer $id doesnt exist probably check youre containers using tocker container ls -a"
	fi
}

# TODO
# systemd run with the parsed options
# alongside unshare with the proper namespaces and checking the service file
# removing by the container_name or the id and completing the id
# to start the container you can start by doing x 
# to execute a command inside the shell idk hwo to do so yet but with systemd probably its easy to get the process id's namespace_name and exec the command inside
# list the containers with its names and proper cleanup for the image
tocker_run () {
	declare image=$1
	formatted_input=$(image_name_formatter $image)
	declare path="$OUT_PATH/$formatted_input.tar.gz"
	echo "$path"
	[[ -e $path ]] || tocker_pull $image

	# defaults are added inside tocker_create all but the entry_point
	# no need to assign defaults
	# assigning defualt with :- instead of := for positional parameters
	entry=${2:-$(grep "ENTRYPOINT" $IMAGE_META_PATH/$formatted_input.env | cut -d'=' -f2)}
	# id is present globally after creation
	tocker_create $formatted_input $entry


	if [[ -e $output_dir ]]
	then
		# creating a randomized ip suffix 
		ip="${id: -3}"
		# extracting the digits only
		ip="${ip//[^0-9]/}"
		# setting the default suffix with 2 in case the last 3 hexa not containing any numbers
		ip="${ip:-2}"
		# taking the remainder of 255 in case of zero to set the default as 2 always
		ip="$((ip % 255))"
		# defaulting to 2 in case of 1 0 255 
		[[ $ip -le 1 ]] && ip="2"
		# mac address
		mac="${id: -3:1}:${id: -2}"
		uuid="${id::5}"

		# creating the container's network namespace
		sudo ip netns add netns_"$uuid"
		# veth_0 is the ehternet interafce on the host and veth_1 is the ethernet interafce inside the container
		sudo ip link add veth0_"$uuid" type veth peer name veth1_"$uuid" 
		sudo ip link set veth1_"$uuid" netns netns_"$uuid"
		# setting the loopback address as up inside the network namepsace
		sudo ip netns exec netns_"$uuid" ip link set dev lo up
		# setting the mac address of the virtual ethernet interface
		sudo ip netns exec netns_"$uuid" ip link set veth1_"$uuid" address 02:42:ac:11:00"$mac"
		# adding the sudo ip address of the veth0 
		sudo ip netns exec netns_"$uuid" ip addr add 10.0.3."$ip"/24 dev veth1_"$uuid" 
		# set the veth0 interafce as up 
		sudo ip link set dev veth0_"$uuid" up
		# setting the state of the veth1 to up
		sudo ip netns exec netns_"$uuid" ip link set veth1_"$uuid" up
		# making veth0 the default gateway
		sudo ip netns exec netns_"$uuid" ip route add default via 10.0.3.1
		# finally enabling the veth1 interface
		network_type=${TOCKER_PARAMS["network"]}
		# getting the current main interface and the current dns server
		get_network

		bridge_name=$(grep 'bridge' "$NETWORK_CONFIG" | cut -d':' -f2)

		mkdir -p /etc/netns/netns_"$uuid"

		# adding the current dns resolver as the default for the created network namespace
		echo nameserver $current_dns | tee /etc/netns/netns_"$uuid"/resolv.conf
		echo "ipv4=10.0.3.$ip" >> $CONT_META_PATH/$id
		echo "gateway=10.0.3.1" >> $CONT_META_PATH/$id
		echo "network_id=$uuid" >> $CONT_META_PATH/$id

		echo "sudo rm -rf /etc/netns/netns_"$uuid"" >> $CLEANUP
		case $network_type in
			bridge)
				sudo ip link set veth0_"$uuid" master "$bridge_name"
				echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
				;;
			host)
				# in case of host its the veth0 but if its a bridge type 
				# the gateway is asisgned the ip of the bridge 
				# would introduce errors when running several containers on the same gateway ip
				sudo ip addr add 10.0.3.1/24 dev veth0_"$uuid"
				# create a routing rule to forward packets from the source of 
				sudo iptables -A FORWARD -o $main_link -i veth0_"$uuid" -j ACCEPT

				echo "sudo iptables -D FORWARD -o $main_link -i veth0_$uuid -j ACCEPT" >> $CLEANUP

				sudo iptables -A FORWARD -i $main_link -o veth0_"$uuid" -j ACCEPT

				echo "sudo iptables -D FORWARD -o $main_link -i veth0_$uuid -j ACCEPT" >> $CLEANUP

				# mask the packets coming out of the veth1_ to be sourced from the main_link coming from the get_network function
				# to enable internet access to the container
				sudo iptables -t nat -A POSTROUTING -s 10.0.3."$ip"/24 -o $main_link -j MASQUERADE

				echo "sudo iptables -t nat -D POSTROUTING -s 10.0.3."$ip"/24 -o $main_link -j MASQUERADE" >> $CLEANUP

				echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

				;;
			*)
				;;
		esac

		echo "sudo ip link delete dev veth0_"$uuid"" >> $CLEANUP
		echo "sudo ip netns delete netns_"$uuid"" >> $CLEANUP
		echo "echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward" >> $CLEANUP
		echo "your entry is $entry"
		echo "sudo systemd run --CPUQuota=${TOCKER_PARAMS["cpuquota"]} --MemoryMax=${TOCKER_PARAMS["memmax"]} --MemoryMin=${TOCKER_PARAMS["memmin"]} --MemoryHigh=${TOCKER_PARAMS["memhigh"]} \
			--IOReadBandwidthMax=${TOCKER_PARAMS["ioread"]} --IOWriteBandwithMax=${TOCKER_PARAMS["iowrite"]}\
			--unit="tocker_$id" --slice=tocker.slice ip netns exec netns_"$uuid" \
				unshare -fmuip --mount-proc="$CONTAINER_OUT_PATH/$id/proc" \
				chroot "$CONTAINER_OUT_PATH/$id" "$entry""
		echo "all created"
	else
		echo "creating container from $image failed exit status 1"
		return 1
	fi


	#${TOCKER_PARAMS["parameter"]}
	#(cpuquota|ioread|iowrite|memmin|memmax|memhigh|network)
	#TODO
	# adding ps to list all running containers
	# forking the process would change how you would grep the process id
	# using the -f command
	# sudo unshare -rfpiu --mount-proc=$OUT_PATH/tocker_images/id/proc
	# sudo systemd run unit=$id chroot /$OUT_PATH/tocker_images/id command="/bin/sh -c "$entry"

}

tocker_create () {
	declare image=$1
	declare entry=$2
	tocker_add_container $image $entry
	CLEANUP="$CONT_META_PATH/"$id"_cleanup.sh"
	# declaring directory by added directory id each unique id specifying unique meta such as creation date last used, etc.
	output_dir="$CONT_PATH/$id"
	declare path="$OUT_PATH/$image.tar.gz"
	mkdir $output_dir
	tar -mxf $path --directory="$output_dir" --no-same-owner --no-same-permissions || (rmdir $output_dir && tocker_remove_container $id)
	# adding the cleanup line to the meta file
	echo "#!/bin/bash" >> $CLEANUP
	echo "rm -rf $output_dir" >> $CLEANUP
}

get_container_procid () {
	declare container_id=$1
	# container image ids are on the 11th fragment so to print running containers
	# just do so and to get all with status running would b
	# bit more complicated
	# ps aux jsut prints the whole thing including the full command using u
	proc_id=$(ps aux | grep unshare | grep -v grep | awk '{if($8 == "S") print $0}' | grep $container_id | awk '{print $2}')
}

tocker_ps () {
	# may be improved for listing containers besides their ids
	# could be done by change the internal file separator and reading them line by line and printing idk how to do it exactly
	# a problem for later first the namespaces
	declare out=$( grep -oP ".+?(?==)" $BASE_DIR/.ids)
	echo -e ${out/$'\n'/$'\t'}
}

