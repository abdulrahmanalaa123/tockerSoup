#!/bin/bash

# getting the scripts directory 
SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})
# base working location of tocker
BASE_DIR=/var/tocker
#location of the all the images created
OUT_PATH=$BASE_DIR/tocker_images

# meta contains the cgroup names or mounted logs
# some sort of persistent state for the image or entry command fro example
# would be added under tocker_meta/$image_uuid
META_PATH=$BASE_DIR/tocker_meta

set_permissions () {
	sudo groupadd tocker
	sudo gpasswd -a $USER tocker
	sudo chmod g=rwx $BASE_DIR
	sudo chmod g+s $BASE_DIR
	sudo chown :tocker $BASE_DIR
	# dirs are created with group:r-s to set the default 
	# the solution is to set the file default access mask to rwx for tocker
	# to set the default permissions for rwx
	sudo setfacl -d -m "m:rwx" $BASE_DIR
	tocker_ownership
}

# replacement of the permission_wrapper
# using sgid on the base script running to run as a tocker group
# to apply  the tocker group to run the script
tocker_ownership () {
	echo "$SCRIPT_DIR"
	sudo chown -R :tocker $SCRIPT_DIR
	sudo chmod g+x $SCRIPT_DIR/*.sh
	sudo chmod g+s $SCRIPT_DIR/*.sh	
}

#having cgroups with the name of the UUID saving the name to the UUID
tocker_init () {
	if [[ ! -e $BASE_DIR ]]
	then
		sudo mkdir $BASE_DIR
		set_permissions
	fi

	if [[ ! -e $OUT_PATH ]]
	then
		 sudo mkdir $OUT_PATH
	fi

	if [[ ! -e $META_PATH ]]
	then
		 sudo mkdir $META_PATH
	fi
	return 0
}

tocker_init
