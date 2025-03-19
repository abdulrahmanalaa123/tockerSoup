#!/bin/bash
BASE_DIR=/var/tocker
OUT_PATH=$BASE_DIR/tocker_images
IMAGE_META_PATH=$BASE_DIR/tocker_meta/images
CONT_META_PATH=$BASE_DIR/tocker_meta/containers
CONT_PATH=$BASE_DIR/tocker_containers
LOG_PATH=$BASE_DIR/container_logs
NETWORK_CONFIG=/opt/tocker/network_config

image_name_formatter () {
	if [[ $1 =~ : ]]
	then
	      echo "${1//:/_}"
	else
	      echo "$1_latest"
	fi
}

tocker_add_container () {
	declare -a options=(cpuquota ioread iowrite memmin memmax memhigh)
	declare -A defaults=(["cpuquota"]="20" ["memmin"]="1G" ["memmax"]="2G" ["memhigh"]="2G" ["network"]="host")
	declare image=$1
	declare entry=$2
	# left without declare to be defined globally after creation
	id=$(uuidgen)
	declare meta_file=$CONT_META_PATH/$id.meta
	# check if the name already exists before creating the meta file 
	[[ -n ${TOCKER_PARAMS["name"]} ]] && [[ -z $(get_full_id ${TOCKER_PARAMS["name"]}) ]] && echo "name=${TOCKER_PARAMS["name"]}" >> $meta_file || echo "a container with the name ${TOCKER_PARAMS["name"]} already exists" && return 1
	for option in ${options[@]}
	do
		if [[ -n ${TOCKER_PARAMS["$option"]} ]]
		then
			echo "$option=${TOCKER_PARAMS["$option"]}" >> $meta_file
		else
			# just to exclude the name wont improve ngl
			TOCKER_PARAMS["$option"]=${defaults["$option"]}
			echo "$option=${TOCKER_PARAMS["$option"]}" >> $meta_file
		fi
	done
	echo "image=$image" >> $meta_file
	# not adding environmental variables becuase when exporting the container they are initalized inside the tar file
	echo "ENTRYPOINT=$entry" >> $meta_file
}

get_network (){
	current_links=$(ip link show)
	# get the current running dns server you're using
	current_dns=$(resolvectl status | grep 'Current DNS' | cut -d':' -f2)
	# get the current device name which is used to connect you to the internet
	main_link=$(ip route get "$current_dns" | sed -n 's/.*dev \([^\ ]*\).*/\1/p')
}

tocker_remove_container () {
	status=$(get_status $1)
	if [[ $status = "RUNNING" ]] && [[ $force = false ]]
	then
		echo "cant delete a running a container if you want you can add the option -f to stop and delete the container"
		return 1
	fi
	[[ $status = "RUNNING" ]] && sudo systemctl stop -f tocker_$1

	rm -rf $CONT_PATH/$1
	.  $CONT_META_PATH/$1_cleanup.sh
	rm $CONT_META_PATH/$1_cleanup.sh
	rm $CONT_META_PATH/$1_startup.sh
	rm $CONT_META_PATH/$1.meta
	rm $LOG_PATH/$1.log
}

tocker_add_image () {
	declare image=$1
	id=$(uuidgen)
	echo "$image=$id" |  tee -a "$IMAGE_META_PATH/.ids" 
}

tocker_remove_image () {
	declare image=$(image_name_formatter $1)
	[[ ! -e $OUT_PATH/$image.tar.gz ]] && echo "image $1 doesnt exist" && return 1
		
	declare containers=$(grep -lir "name=$input" $CONT_META_PATH)
	containers=${containers//.meta/}
	# getting the base name for all containers
	containers=${containers//$CONT_META_PATH\//}
	if [[ -n $containers ]] && [[ $force = false ]]
	then
		echo "containers $containers are related to the image $1 are you sure you want to delete it? keep in mind once you delete the containers you cant create them again unless you download hte image"
		echo "0 no"
		echo "1 yes"
		select val in 0 1
		do
			case $val in
				0)
					echo "have a nice day!"
					;;
				1)
				        echo "move on "	
					;;
				*)
					echo "invalid option"
					;;
			esac
		done

	fi

	sed -E -i "/$image/d" "$IMAGE_META_PATH/.ids"
	rm -f "$IMAGE_META_PATH/$image.env"
	rm -f "$OUT_PATH/$image.tar.gz"

}

tocker_add_startup (){
	cat << EOF > "$CONT_META_PATH/"$id"_startup.sh"
#!/bin/bash
sudo systemd-run $addon --collect -p CPUQuota="${TOCKER_PARAMS["cpuquota"]}%" -p MemoryMax=${TOCKER_PARAMS["memmax"]} -p MemoryMin=${TOCKER_PARAMS["memmin"]} -p MemoryHigh=${TOCKER_PARAMS["memhigh"]} \
			--unit="tocker_$id" --slice=tocker.slice ip netns exec netns_"$uuid" \
				unshare -fmuip --mount-proc \
				chroot "$output_dir" /bin/sh -c "/bin/mount -t proc proc /proc && $entry"
EOF
}

# enables you to get the id with the name and id
get_full_id () {
	declare input=$1
	declare presume_id=$(ls $CONT_PATH | grep  "$input")

	#check if its uuid and is not empty
	if [[ -n $presume_id ]] && [[ $presume_id =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]
	then
		echo $presume_id
	else
		declare file_name=$(grep -lir "name=$input" $CONT_META_PATH)
		if [[ -n $file_name ]] 
		then
			file_name=$(basename $file_name)
			declare id=${file_name%.meta}
			echo "$id"
		fi
	fi
}

get_pid () {
	declare id=$1
	declare pid=$(systemctl show --property MainPID --value tocker_$id.service)
	echo $pid
}


get_running () {
	# running containers array
	declare -ga running=$(ls /sys/fs/cgroup/tocker.slice | grep tocker)
}

# get status should be ran with get_running always to define the running variable not taken as an input for reducing handling hte overhead of the running array as an input
get_status () {
	declare id=$1
	# if the running array contains the id
	if [[ $running =~ "$1" ]]
	then
		echo "RUNNING"
	else
		fail_status=$(grep -Eo "code=.*status=.*" $LOG_PATH/$id.log | tail -n 1)
		date=$(grep -E "code=.*status=.*" $LOG_PATH/$id.log | tail -n 1 | cut -d' ' -f1-3)
		[ -n "$fail_status" ] && echo "$(date_difference "$date") $fail_status"
		normal=$(grep "Deactivated" $LOG_PATH/$id.log | tail -n 1)
		date=$(grep "Deactivated" $LOG_PATH/$id.log | tail -n 1 | cut -d' ' -f1-3)
		[ -n "$normal" ] && echo "$(date_difference "$date") exited"
	fi
}


date_difference () {
	# Given date
	given_date=$1
	current_date=$(date +"%Y-%m-%d %H:%M:%S")
	# get the current timestamp in seconds
	given_timestamp=$(date -d "$given_date" +%s)
	current_timestamp=$(date +%s)

	# Calculate the difference in seconds
	diff_seconds=$((current_timestamp - given_timestamp))
	# Check the difference and display the appropriate unit
	if [ $diff_seconds -lt 60 ]; then
	  # Difference in seconds
	  echo "($diff_seconds seconds ago)"
	elif [ $diff_seconds -lt 3600 ]; then
	  # Difference in minutes
	  diff_minutes=$((diff_seconds / 60))
	  echo "($diff_minutes minutes ago)"
	elif [ $diff_seconds -lt 86400 ]; then
	  # Difference in hours
	  diff_hours=$((diff_seconds / 3600))
	  echo "($diff_hours hours ago)"
	else
	  # Difference in days
	  diff_days=$((diff_seconds / 86400))
	  echo "($diff_days days ago)"
	fi
}
