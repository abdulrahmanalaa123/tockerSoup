#!/bin/bash


BASE_DIR=/var/tocker
OUT_PATH=$BASE_DIR/tocker_images
IMAGE_META_PATH=$BASE_DIR/tocker_meta/images
CONT_META_PATH=$BASE_DIR/tocker_meta/containers
CONT_PATH=$BASE_DIR/tocker_containers
NETWORK_CONFIG=/opt/tocker/network_config

get_network (){
	current_links=$(ip link show)
	# get the current running dns server you're using
	current_dns=$(resolvectl status | grep 'Current DNS' | cut -d':' -f2)
	# get the current device name which is used to connect you to the internet
	main_link=$(ip route get "$current_dns" | sed -n 's/.*dev \([^\ ]*\).*/\1/p')
}



tocker_run () {

	set -x
	declare -A TOCKER_PARAMS=(["cpuquota"]="20%" ["ioread"]="10M" ["iowrite"]="10M" ["memmin"]="1G" ["memmax"]="2G" ["memhigh"]="2G" ["network"]="host")
	# defaults are added inside tocker_create all but the entry_point
	# no need to assign defaults
	# assigning defualt with :- instead of := for positional parameters
	entry="/bin/sh"
	# id is present globally after creation

	id="4ed7c9a3-4877-4c7d-bfe0-062d29b99cf3"
	output_dir="$CONT_PATH/$id"
	CLEANUP="$CONT_META_PATH/"$id"_cleanup.sh"

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


				;;
			*)
				;;
		esac

		echo "sudo ip link delete dev veth0_"$uuid"" >> $CLEANUP
		echo "sudo ip netns delete netns_"$uuid"" >> $CLEANUP
		echo "your entry is $entry"

		sudo systemctl start tocker@$uuid.path
		sudo systemctl start tocker_change@$uuid.path
		# -r remains after exit which is needd when trying to log the status of the container
		sudo systemd-run -t --collect -p CPUQuota=${TOCKER_PARAMS["cpuquota"]} -p MemoryMax=${TOCKER_PARAMS["memmax"]} -p MemoryMin=${TOCKER_PARAMS["memmin"]} -p MemoryHigh=${TOCKER_PARAMS["memhigh"]} \
			--unit="tocker_$uuid" --slice=tocker.slice ip netns exec netns_"$uuid" \
				unshare -fmuip --mount-proc \
				chroot "$output_dir" /bin/sh -c "/bin/mount -t proc proc /proc && $entry" 
				
		echo "all created"
	else
		echo "creating container from $image failed exit status 1"
		return 1
	fi
	set +x


}

tocker_run
