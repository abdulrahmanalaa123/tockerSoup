#!/bin/bash

# excessive use of declare to ensure block scoping 
# set the script to exit on error and error on unset vars and return 1 if one pipeline command fail

set -o errexit -o pipefail; shopt -s nullglob
#set -o nounset -o pipefail; shopt -s nullglob
. ./helpers.sh

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
		declare env_file="$IMAGE_META_PATH/$image_name_modified.env"
		if [[ -e $out_path ]]
		then
			echo "image $image already exists"
			return 1
		fi
		declare temp_cont=$(docker create $image)

		entry_point=$(docker inspect --type=image --format='{{json .Config.Entrypoint}} {{json .Config.Cmd}}' $image)
		#removing nulls and quotations
 		entry_point=${entry_point//[\"\[\]]/}
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

tocker_run () {
	declare image=$1
	formatted_input=$(image_name_formatter $image)
	declare path="$OUT_PATH/$formatted_input.tar.gz"
	echo "$path"
	[[ -e $path ]] || tocker_pull $image

	entry=${2:=$(grep "ENTRYPOINT" $IMAGE_META_PATH/$formatted_input.env | cut -d'=' -f2)}
	# id is present globally after creation
	tocker_create $formatted_input $entry
	
	#TODO
	# cgroups using systemd or the new way in general
	# unsharing with the mount options 
	# adding options in the command
	# adding ps to list all running containers
	# network namesapce
	# default_cgroups defined in init
	# process types isolation as well defined \
	# forking the process would change how you would grep the process id
	# using the -f command
	# -rfpiu --mount-proc=$OUT_PATH/tocker_images/id/proc
	# systemd run unit=$id chroot /$OUT_PATH/tocker_images/id command="/bin/sh -c "given command probably"" 
	# 

}

tocker_create () {
	declare image=$1
	declare entry=$2
	tocker_add_container $image $entry
	# declaring directory by added directory id each unique id specifying unique meta such as creation date last used, etc.
	declare output_dir="$CONT_PATH/$id"
	declare path="$OUT_PATH/$image.tar.gz"
	mkdir $output_dir
	tar -mxf $path --directory="$output_dir" --no-same-owner --no-same-permissions || (rmdir $output_dir && tocker_remove_container $id)
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

