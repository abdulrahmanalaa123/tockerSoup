#!/bin/bash

. ./helpers.sh
. ./init.sh

tocker_pull() {
	declare image=$1
	declare image_name_modified=${image/:/_}
	
	if [[ -n $(sed -nE '/docker.io/p' ~/.docker/config.json) ]]
	then
		declare out_path="$OUT_PATH/$image_name_modified.tar.gz"
		declare temp_cont=$(docker create $image)
		docker container export $temp_cont |  permission_wrapper tee $out_path > /dev/null 2>&1
		docker container rm $temp_cont > /dev/null
		# setting 
		declare output_dir=${out_path%.tar.gz}
		if [[ -e $output_dir ]]
		then
			permission_wrapper mkdir $output_dir
			permission_wrapper tar -mxf $out_path --directory=$output_dir --no-same-owner --no-same-permissions
			if [[ $? -eq 0 ]]
			then
				tocker_add_image $image_name_modified
			fi

			# removing for cleanup even after failure yet not adding it to the ids if it doesnt work
			permission_wrapper rm $out_path > /dev/null 2>&1
			permission_wrapper rm .dockerenv > /dev/null 2>&1
			
		fi
	else
		echo "please login into docker first"
	fi
}

tocker_ps () {
	declare out=$( grep -oP ".+?(?==)" $BASE_DIR/.ids)
	echo -e ${out/$'\n'/$'\t'}
}


set_prefix
tocker_init
tocker_pull alpine:latest
tocker_ps 
