# HOW TO RUN IT?
- first run the script init.sh to initialize the image location and permissions
- if its ran first you can relogin to be as the tocker root user
- if not then you can run tocker.sh right away

- metadata specifying used namespaces and cgroups on created image
- and if named cgroups (just specifying their types and naming them according to theri uuid)
- cgroup and namespaces saving (using nsenter and cgroup)
- adding virtual network 
- exec running and ataching it to the bash shell
- metadata includes entrypoint command and thats it its by default /bin/sh
