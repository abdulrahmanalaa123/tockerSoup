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

set_permissions () {
	sudo groupadd tocker
	sudo gpasswd -a $USER tocker
	sudo chmod g=rwx $BASE_DIR
	sudo chmod g+s $BASE_DIR
	sudo chown :tocker $BASE_DIR
	# setting the tocker owner of the group and setting the setgid bit doesnt give permission while running sg tocker -c
	# that was because the default permissions on the group was r-s which is the so assigning the mask solved the issue
	sudo setfacl -dm "m::rwx" $BASE_DIR
}

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
	echo "$image=$id" |  permission_wrapper tee -a "$BASE_DIR/.ids" > /dev/null 2>&1
}

tocker_remove_container () {
	declare container_id=$1
	permission_wrapper sed -E -i "/$container_id/d" "$BASE_DIR/.ids"
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

