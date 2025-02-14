# man 5 systemd.resource-control
# default CPUQuota=5% IOreadbandwith=20M/s by default B,K,M,G,T IOwritebandwith=  MemoryMin=1G(requested)B,K,M,G,T MemoryMax=2G(requested)B,K,M,G,T(absolute limit)  MemoryHigh2G(softcap)=B,K,M,G,T AllowedCPUs=1,2 (specify which cpus are specified)
# either enable accounting on the userslice to enable quoting the services i presume 
# tocker container run  --cpuquota [0-100] --iowrite [num(B|K|M|G|T)] --ioread [num(B|K|M|G|T)] --memmax [num(B|K|M|G|T)] --memmin [num(B|K|M|G|T)] --memhigh [num(B|K|M|G|T)] <image_name> <command> # images are associate with an entryPoint can be done when pulling
# tocker container exec <container_id> <command>
# tocker container start <container_id> # keep running the image on the latest entrypoint
# tocker container rm -rf <container_id> # -r remove the ocntainer alongside its respective image -f removes the conatainer and stops it abruptly
# tocker image rm -f <image_name> #remove 
# tocker container stop <container_id>
# tocker image get <image_name>
# tocker container la ls l
# tocker image la ls l 

if [[ $# -gt 0 ]]; 
then
       	while [ "${1:0:2}" == '--' ]; 
	do 
		OPTION=${1:2}; [[ $OPTION =~ = ]] 
		declare "BOCKER_${OPTION/=*/}=${OPTION/*=/}" 
		declare "BOCKER_${OPTION}=x"
	       	shift; 
	done
fi

container_run () {}
container_exec () {}
container_start () {}
container_rm () {}
container_stop () {}
container_ls () {}
image_get () {}
image_rm () {}
image_ls () {}

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
	case $1) in
		run|"exec"|"stop"|start|"rm"|"ls")
			container_"$1" "${@:2}"
			;;
		*)
			tocker_help container
			;;
	esac	
}

image_parser () {
	case $1) in
		get|"rm"|"ls")
			image_"$1" "${@:2}"
			;;
		*)
			tocker_help image
			;;
	esac	
}

