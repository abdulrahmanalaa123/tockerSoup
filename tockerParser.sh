# man 5 systemd.resource-control
# default CPUQuota=20% IOreadbandwith=20M/s by default B,K,M,G,T IOwritebandwith=  MemoryMin=1G(requested)B,K,M,G,T MemoryMax=2G(requested)B,K,M,G,T(absolute limit)  MemoryHigh2G(softcap)=B,K,M,G,T AllowedCPUs=1,2 (specify which cpus are specified)
# either enable accounting on the userslice to enable quoting the services i presume 
# tocker container run <image_name> --cpuquota --iowrite --ioread --memmax --memmin --memhigh 
# tocker container stop <container_id>
# tocker image get <image_name>
# tocker container la ls l
# tocker image la ls l 
