# man 5 systemd.resource-control
# default CPUQuota=5% IOreadbandwith=20M/s by default B,K,M,G,T IOwritebandwith=  MemoryMin=1G(requested)B,K,M,G,T MemoryMax=2G(requested)B,K,M,G,T(absolute limit)  MemoryHigh2G(softcap)=B,K,M,G,T AllowedCPUs=1,2 (specify which cpus are specified)
# either enable accounting on the userslice to enable quoting the services i presume 


container_run () {
	echo running

	if [[ $# -gt 0 ]]; 
	then
		while [ "${1:0:2}" == '--' ]; 
		do 
			OPTION=${1:2}; 
			if [[ $OPTION =~ = ]] 
			then
				declare "TOCKER_${OPTION/=*/}=${OPTION/*=/}" | declare "TOCKER_${OPTION}=x"
				shift; 
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
	sed -n "/tocker $1/p" ./Makefile
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

parser container run
parser image get
parser container rm
parser container exec
parser container stop
parser container start
parser image rm
parser image ls
parser container ls

