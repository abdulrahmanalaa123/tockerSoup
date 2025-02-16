#!/bin/bash

BASE_DIR=/var/tocker
OUT_PATH=$BASE_DIR/tocker_images
IMAGE_META_PATH=$BASE_DIR/tocker_meta/images
CONT_META_PATH=$BASE_DIR/tocker_meta/containers
CONT_PATH=$BASE_DIR/tocker_containers


image_name_formatter () {
	echo "${1//:/_}"
}

tocker_add_container () {
	declare image=$1
	id=$(uuidgen)
	#TODO
	# get the entry point if not provided	
	# name it using the id 
	# findign the container is by grepping the id for the meta file
	# add the environmental variables and container parameters like cgroups specified
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

