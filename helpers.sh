#!/bin/bash

# unifying variable assignments since this script would probably would be used alot
BASE_DIR=/var/tocker
OUT_PATH=/var/tocker/tocker_images
META_PATH=/var/tocker/tocker_meta

tocker_add_image () {
	declare image=$1
	declare id=$(uuidgen)
	echo "$image=$id" |  tee "$BASE_DIR/.ids" > /dev/null 2>&1
	return 0
}

tocker_remove_image () {
	declare image=$1
	sed -E -i "/$image/d" "$BASE_DIR/.ids"
}

get_id () {
	declare image=$1
	id=$( grep -oP "(?<=$image=)\S*" $BASE_DIR/.ids)
	[ -z $id ] && return 1
	return 0
}

