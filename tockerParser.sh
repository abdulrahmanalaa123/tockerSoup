# man 5 systemd.resource-control
# default CPUQuota=5% IOreadbandwith=20M/s by default B,K,M,G,T IOwritebandwith=  MemoryMin=1G(requested)B,K,M,G,T MemoryMax=2G(requested)B,K,M,G,T(absolute limit)  MemoryHigh2G(softcap)=B,K,M,G,T AllowedCPUs=1,2 (specify which cpus are specified)
# either enable accounting on the userslice to enable quoting the services i presume 

container_run () {
	#cpuquota 0-100% including floats
	# all the rest are digits including floats followed by B,K,M,G,T
	declare -A VAL_VALIDATION=(["cpuquota"]="0*([1-9][0-9]?|100){1}(.0*([1-9][0-9]?))?" \
		["ioread"]="[0-9]+(.[0-9]+)?(B|K|M|G|T){1}" \
		["iowrite"]="[0-9]+(.[0-9]+)?(B|K|M|G|T){1}" \
		["memmin"]="[0-9]+(.[0-9]+)?(B|K|M|G|T){1}" \
		["memmax"]="[0-9]+(.[0-9]+)?(B|K|M|G|T){1}" \
		["memhigh"]="[0-9]+(.[0-9]+)?(B|K|M|G|T){1}")	
	if [[ $# -gt 0 ]]; 
	then
		declare -gA TOCKER_PARAMS;
		while [ "${1:0:2}" == '--' ]; 
		do 
			OPTION=${1:2} 

			key=${OPTION%=*}
			val=${OPTION#*=}
			key=${key,,}

			if [[ $key =~ (cpuquota|ioread|iowrite|memmin|memmax|memhigh) ]]
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

	fi
}

container_exec () {
	echo execing
}

container_start () {
	echo starting
}

container_rm () {
	echo removing_cont
}

container_stop () {
	echo stopping
}

container_ls () {
	echo lsing_cont
}

image_get () {
	echo getting
}

image_rm () {
	echo removing_image
}

image_ls () {
	echo lsing_image
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
	sed -n "/tocker $1/p" /opt/tocker/help
}

container_parser () {
	case $1 in
		run|"exec"|"stop"|start|"rm"|"ls")
			container_"$1" "${@:2}"
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
		*)
			tocker_help image
			;;
	esac	
}

parser container run --cpuquota 20 --ioread 50B
parser container run --cpuquota=20 --ioread=50B
parser image get
parser container rm
parser container exec
parser container stop
parser container start
parser image rm
parser image ls
parser container ls

