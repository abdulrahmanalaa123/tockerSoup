#!/bin/bash

# excessive use of declare to ensure block scoping 
# set the script to exit on error and error on unset vars and return 1 if one pipeline command fail

set -o errexit -o nounset -o pipefail; shopt -s nullglob
#set -o nounset -o pipefail; shopt -s nullglob

. ./helpers.sh
. ./init.sh

# first i was treating images as they are the containers and creating a unique image for each container and seems like a waster
# so i will do the container runtime is extracting the container into a tempfs using the uuid and deleting it using it as well and
# the original image stays the same and keeping the tar file permenantly in tocker_images
tocker_pull() {
	declare image=$1
	#modification because it messes with tar and calls a repo for some reason
	declare image_name_modified=$(image_name_formatter $image)
	
	if [[ -n $(sed -nE '/docker.io/p' ~/.docker/config.json) ]]
	then
		declare out_path="$OUT_PATH/$image_name_modified.tar.gz"
		if [[ -e $out_path ]]
		then
			echo "image $image already exists"
			return 1
		fi
		declare temp_cont=$(docker create $image)
		docker container export $temp_cont |  permission_wrapper tee $out_path > /dev/null 2>&1
		docker container rm $temp_cont > /dev/null
		docker image rm $image		
		
		# assigning an id to given image 
		# removing for cleanup even after failure yet not adding it to the ids if it doesnt work
		permission_wrapper rm .dockerenv > /dev/null 2>&1
	else
		echo "please login into docker first"
	fi
}

#tocker_options () {
#	# options are parsed and put into a declarative array with comma sperated values 
#	# options declarative array {cgroups:",,,,,","namespaces":,,,,,,,"virtual_eth":,,,,,entrypoint_command:{taken as is}}
#	# what would be the options
#	#cgroups using systemd and assigning namespaces in meta as well as virtual network
#}
# image_id is defined in pull using the add image with the var id

tocker_run () {
	#Substring expanision	
	declare input=${@: -1}
       	# if input is part of a valid uuid
	formatted_input=$(image_name_formatter $input)
	declare id=$(get_full_id $formatted_input)
	if [[ -n $id ]]; then
	   #run using id an already existing image
	   echo "bla"
	else
	   declare path="$OUT_PATH/$formatted_input.tar.gz"
	   if [[ ! -e $path ]]
	   then
		   tocker_pull $input
	   fi
	   tocker_create $formatted_input
	fi

}

tocker_create () {
	declare image=$1
	tocker_add_container $image
	# declaring directory by added directory id each unique id specifying unique meta such as creation date last used, etc.
	declare output_dir="$OUT_PATH/$id"
	declare path="$OUT_PATH/$image.tar.gz"
	permission_wrapper mkdir $output_dir
	permission_wrapper tar -mxf $path --directory="$output_dir" --no-same-owner --no-same-permissions
	# cleanup in case of failure 
	if [[ $? -ne 0 ]]
	then
		rmdir $output_dir
		tocker_remove_container $id
	fi
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


set_prefix
tocker_init
tocker_run alpine:latest
