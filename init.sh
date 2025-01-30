#!/bin/bash


#having cgroups with the name of the UUID saving the name to the UUID
tocker_init () {
	BASE_DIR=/var/tocker
	if [[ ! -e $BASE_DIR ]]
	then
		sudo mkdir $BASE_DIR
		set_permissions
	fi
	#location of the all the images created
	OUT_PATH=$BASE_DIR/tocker_images
	if [[ ! -e $OUT_PATH ]]
	then
		 permission_wrapper mkdir $OUT_PATH
	fi
	# meta contains the cgroup names or mounted logs
	# some sort of persistent state for the image or entry command fro example
	# would be added under tocker_meta/$image_uuid
	META_PATH=$BASE_DIR/tocker_meta
	if [[ ! -e $META_PATH ]]
	then
		 permission_wrapper mkdir $META_PATH
	fi
	return 0
}


