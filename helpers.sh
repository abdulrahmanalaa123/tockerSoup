#!/bin/bash

BASE_DIR=/var/tocker
OUT_PATH=$BASE_DIR/tocker_images
CONTAINER_OUT_PATH=$BASE_DIR/tocker_containers
IMAGE_META_PATH=$BASE_DIR/tocker_meta/images
CONT_META_PATH=$BASE_DIR/tocker_meta/containers
CONT_PATH=$BASE_DIR/tocker_containers
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
	declare -A defaults=(["cpuquota"]="20" ["ioread"]="10M" ["iowrite"]="10M" ["memmin"]="1G" ["memmax"]="2G" ["memhigh"]="2G" ["network"]="bridge")
	declare image=$1
	declare entry=$2
	# left without declare to be defined globally after creation
	id=$(uuidgen)
	for option in ${options[@]}
	do
		if [[ -n ${TOCKER_PARAMS["$option"]} ]]
		then
			echo "$option=${TOCKER_PARAMS["$option"]}" >> $CONT_META_PATH/$id
		else
			# just to exclude the name wont improve ngl
			TOCKER_PARAMS["$option"]=${defaults["$option"]}
			echo "$option=${TOCKER_PARAMS["$option"]}" >> $CONT_META_PATH/$id
		fi
	done

	echo "image=$image" >> $CONT_META_PATH/$id
	[[ -n ${TOCKER_PARAMS["name"]} ]] && echo "name=${TOCKER_PARAMS["name"]}" >> $CONT_META_PATH/$id
	# not adding environmental variables becuase when exporting they are initalized
	echo "ENTRYPOINT=$entry" >> $CONT_META_PATH/$id 	
}

get_network (){
	current_links=$(ip link show)
	# get the current running dns server you're using
	current_dns=$(resolvectl status | grep 'Current DNS' | cut -d':' -f2)
	# get the current device name which is used to connect you to the internet
	main_link=$(ip route get "$current_dns" | sed -n 's/.*dev \([^\ ]*\).*/\1/p')
}

tocker_remove_container () {
	# remove the meta file and delete the directory
	.  $CONT_META_PATH/$1_cleanup.sh
	rm $CONT_META_PATH/$1_cleanup.sh
}

tocker_add_image () {
	declare image=$1
	id=$(uuidgen)
	echo "$image=$id" |  tee -a "$IMAGE_META_PATH/.ids" 
}

tocker_remove_image () {
	declare image=$1
	sed -E -i "/$image/d" "$IMAGE_META_PATH/.ids"
}

get_full_id () {
	declare id_part=$1
	#get all whats after the number if it returns a full uuid then echo and use its value wherever needed
	declare id=$(grep -oP "$1\S+$" $BASE_DIR/.ids)
	if [[ -n $id ]] && [[ $(echo $id | wc -c) -eq 37 ]]
	then
		echo $id
	fi
}

