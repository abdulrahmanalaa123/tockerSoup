#!/bin/bash

#TODO
# fixing the fucking permissions maybe using makefile at the end adding the user as a step in installing the service
# but as long as its a script this would be the solution
# adding permissions doesnt apply the newgrp to the user and i want to keep
# running the script but using newgrp starts a new shell as well as sudo su -l $USER
# might be a solution here https://superuser.com/questions/272061/reload-a-linux-users-group-assignments-without-logging-out#
# i cant solve changing the current bash shell
# as a group or forking the rest of the script inside the group tocker
# sudo su -l $USER

BASE_DIR=/var/tocker
OUT_PATH=$BASE_DIR/tocker_images
IMAGE_META_PATH=$BASE_DIR/tocker_meta/images
CONT_META_PATH=$BASE_DIR/tocker_meta/containers
CONT_PATH=$BASE_DIR/tocker_containers


#solving permission issues by attaching the sg tocker -c prefix if the user doesnt have the tocker group applied if it is 
#then the prefix is not needed
set_prefix () {
	declare -a group_arr=$(id -nG)
	if [[ ${group_arr[@]} =~ tocker ]]
	then
		#could be /bin/sh for wider protability maybe but this is a hack and not a longterm solution
		PREFIX="bash -c"
	else
		PREFIX="sg tocker -c"
	fi
}

# permission wrapper is done like this to not wrap each command in double quotes to work with
# prefixes enables a better typing experience for me this is building upon the hack but fuck do i knwo w/e
permission_wrapper () {
	required_command="$@"
	$PREFIX "$required_command"
}

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

