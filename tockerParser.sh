#!/bin/bash
# multiplying first by 100 and multiplying by the 0.001 to get hte float definition of the number
		#size=$(printf '%.2f' $((10**2 * $(echo $info | cut -d'|' -f2) / 1048576))e-2)
# man 5 systemd.resource-control
# IOREAD and IOWrite are removed becuase device needs to be specified and i dont want to go through that hassle
# default CPUQuota=5% IOreadbandwith=20M/s by default B,K,M,G,T IOwritebandwith=  MemoryMin=1G(requested)B,K,M,G,T MemoryMax=2G(requested)B,K,M,G,T(absolute limit)  MemoryHigh2G(softcap)=B,K,M,G,T AllowedCPUs=1,2 (specify which cpus are specified)
# either enable accounting on the userslice to enable quoting the services i presume 

. ./tocker.sh

container_run () {
	#cpuquota 0-100% including floats
	#["ioread"]="[0-9]+(.[0-9]+)?(B|K|M|G|T){1}" \
	#["iowrite"]="[0-9]+(.[0-9]+)?(B|K|M|G|T){1}" \
	declare -A VAL_VALIDATION=(["cpuquota"]="0*([1-9][0-9]?|100){1}(.0*([1-9][0-9]?))?" \
		["memmin"]="[0-9]+(.[0-9]+)?(B|K|M|G|T){1}" \
		["memmax"]="[0-9]+(.[0-9]+)?(B|K|M|G|T){1}" \
		["memhigh"]="[0-9]+(.[0-9]+)?(B|K|M|G|T){1}" \
		["network"]="(bridge|host|none){1}")	

	if [[ $# -gt 0 ]]; 
	then
		
		if [[ $1 =~ (-it) ]] 
		then
			interactive=true
			shift
		fi
	
		declare -gA TOCKER_PARAMS;
		while [ "${1:0:2}" == '--' ]; 
		do 
			OPTION=${1:2} 

			key=${OPTION%=*}
			val=${OPTION#*=}
			key=${key,,}

			if [[ $key =~ (cpuquota|name|ioread|iowrite|memmin|memmax|memhigh|network) ]]
			then
				[[ ${val,,} = ${key} ]] && shift && val=$1;

				if [[ $val =~ ${VAL_VALIDATION["$key"]} ]];
				then
					TOCKER_PARAMS["$key"]="$val"
				else
					echo "value $val doesnt match option $key" tocker_help
					return 1
				fi

				shift; 
			else
				echo "unknown option $OPTION please write all options consecutively"
				tocker_help container
				return 1
			fi
		done
		declare image=$1
		declare entry=$2
	
		tocker_run "$image" "$entry"
	fi
}

#TODO
# container exec using systemd process id and exec
# container start with systemd start
# container delete with id or name
# container stop 
# container ls 
# image remove by name or id removing all envs and id from the 

container_exec () {
	id=$(get_full_id $1)

	echo execing $id
}

container_start () {
	id=$(get_full_id $1)
	echo starting
}

container_rm () {
	id=$(get_full_id $1)
	echo removing_cont
}

container_stop () {
	id=$(get_full_id $1)
	[[ -z $id ]] && echo "container $1 doesnt exist please check writing the the proper name " && return 1

	declare status=$(get_status $id)
	if [[ $status = "RUNNING" ]]
	then
		sudo systemctl stop tocker_$id.service
	else
		echo "can't stop an idle container"
	fi	
}

container_ls () {
	if [[ $@ =~ (-l) ]] || [[ $@ =~ long ]]
	then
		long=true
		header="CONTAINER_ID\t\tIMAGE\t\tCOMMAND\t\tDATE_CREATED\t\tSTATUS\t\t\tIP\t\tMAC\t\t\tNAME\n"
	else
		long=false
		header="CONTAINER_ID\t\tIMAGE\t\tCOMMAND\t\tDATE_CREATED\t\tSTATUS\t\t\tNAME\n"
	fi	
	printf $header
	# container_rm is with tocker_container_rm
	# container_stop is with systemctl stop if its in running
	# container_start runs startup script
	# container_exec is with the get_pid function
	# image rm image with all its data
	get_running 
	for file in $CONT_PATH/*
	do
		info=$(stat --printf="%n|%w\n" $file)

		container_id=$(basename $(echo $info | cut -d'|' -f1))
		image_name=$(grep  "image" $CONT_META_PATH/$container_id.meta | cut -d'=' -f2)
		date=$(echo $info | cut -d'|' -f2)		
		# date day year hour and min
		creation_date="${date::16}:00"
		entry=$(grep "ENTRYPOINT" $CONT_META_PATH/$container_id.meta | cut -d'=' -f2)
		container_status=$(get_status $container_id)
		container_name=$(grep "name" $CONT_META_PATH/$container_id.meta | cut -d'=' -f2)
		if [[ $long = true ]]
		then
			container_IP=$(grep "ipv4" $CONT_META_PATH/$container_id.meta | cut -d'=' -f2)
			container_MAC=$(grep "mac_address" $CONT_META_PATH/$container_id.meta | cut -d'=' -f2)
			printf "${container_id::5}\t\t$image_name\t\t$entry\t\t$creation_date\t$container_status\t$container_IP\t$container_MAC\t$container_name\n"
		else
			#creation_date ofllowed by 1 tab only due to date length
			printf "${container_id::5}\t\t$image_name\t\t$entry\t\t$creation_date\t$container_status\t$container_name\n"
		fi

	done
}


image_get () {
	tocker_pull "$1"
}

image_rm () {
	echo removing_image
}

image_ls () {
	if [[ $@ =~ (-l) ]] || [[ $@ =~ long ]]
	then
		long=true
		header="NAME\t\tTAG\t\tID\t\t\t\t\tCOMMAND\t\tENV_VARS\t\tDATE_CREATED\t\tSIZE\n"
	else
		long=false
		header="NAME\t\tTAG\t\tID\t\tDATE_CREATED\t\tSIZE\n"
	fi	
	printf $header
	for file in $OUT_PATH/*
	do
		info=$(stat --printf="%n|%s|%w\n" $file)
		file_name=$(basename $(echo $info | cut -d'|' -f1))
		file_name=${file_name%.tar.gz}
		image_name=${file_name%%_*}	
		image_tag=${file_name##*_}
		# scale is the defining the scale of percision of the division operation before gviing the input to the basic calculator command
		# keep in mind that the size is in MB
		image_size_mb="$(echo "scale=2; $(echo $info | cut -d'|' -f2) / 1048576" | bc)MB"
		date=$(echo $info | cut -d'|' -f3)		
		# date day year hour and min
		creation_date="${date::16}:00"
		image_id=$(grep $image_name $IMAGE_META_PATH/.ids | cut -d'=' -f2)
		if [[ $long = true ]]
		then
			entry_command=$(grep ENTRYPOINT $IMAGE_META_PATH/$file_name.env | cut -d'=' -f2)	
			env_vars=$(grep -v ENTRYPOINT $IMAGE_META_PATH/$file_name.env | cut -d'=' -f1)
			# since paste takes in from a list of delimiters which means print at three env_vars per line max
			env_vars=$(printf "$env_vars" | paste -sd ',,\n')
			printf "$image_name\t\t$image_tag\t\t$image_id\t$entry_command\t$env_vars\t\t\t$creation_date\t$image_size_mb\n"
		else
			#creation_date ofllowed by 1 tab only due to date length
			printf "$image_name\t\t$image_tag\t\t${image_id::5}\t\t$creation_date\t$image_size_mb\n"
		fi

	done
}

parser () {
	if [[ $1 =~ (image) ]];
	then
		shift 
		image_parser $@
	elif [[ $1 =~ (get) ]];
	then
		image_parser $@
	elif [[ $1 =~ (container) ]];
	then
		shift
		container_parser $@
	elif [[ $1 =~ (run|exec|stop|start) ]];
	then
		container_parser $@
	else
		echo "command $1 isnt recognized as either a contianer or image please specify either container or image"
		return 1
	fi
}

tocker_help () {
	# the help either takes container or image
	# change to /opt/tocker/help
	sed -n "/tocker $1/p" /opt/tocker/helper
}

container_parser () {
	case $1 in
		run|"exec"|"stop"|start|"rm"|"ls")
			container_"$1" "${@:2}"
			;;
		"ll")
			container_ls long ${@:2}
			;;
		"la")
			container_ls all ${@:2}
			;;
		*)
			tocker_help container
			;;
	esac	
}

image_parser () {
	case $1 in
		get|"rm"|"ls")
			image_"$1" "${@:2}"
			;;
		"ll")
			image_ls long ${@:2}
			;;
		*)
			tocker_help image
			;;
	esac	
}

#parser container run --cpuquota 20 --ioread 50B alpine /bin/bash
#parser container run -it --network bridge --ioread 50B --name test_container alpine 
parser container ll
