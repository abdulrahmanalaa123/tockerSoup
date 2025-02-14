# HOW TO RUN IT?
- run the make file and provide it with sudo password to setup the proper environment with the proper privelages
- you can use it using tocker right after in the tockergrp shell or simply relogin for the permissions to take effect 
- you can view the help file in /opt/tocker/help
- although it needs some work its the same as docker with limited cgroup utilities only available cgroups are provided in the help
help file
```
tocker container run  --cpuquota [0-100] --iowrite [num(B|K|M|G|T)] --ioread [num(B|K|M|G|T)] --memmax [num(B|K|M|G|T)] --memmin [num(B|K|M|G|T)] --memhigh [num(B|K|M|G|T)] <image_name> <command> # images are associate with an entryPoint can be done when pulling
tocker container exec <container_id> <command>
tocker container start <container_id>  keep running the image on the latest entrypoint
tocker container rm -rf <container_id>  -r remove the container alongside its respective image -f removes the conatainer and stops it abruptly
tocker image rm -f <image_name> 
tocker container stop <container_id>
tocker image get <image_name>
tocker container (la|ls|l)
tocker image (la|ls|l)
e
```
# Learning Journey
- This project is a capstone project as well as passion-driven learning several linux topics 
- sudoers,Privilages,ACLS,cgroups,namespaces,bash,chroot,filesystems,mounting,process management and process types and STATUS
- as well as learning a ton about makefiles and building with them
- and on top of all that inner workings of docker and the docker architecture as well as the shim,rc architecture and containerd as well as container runtimes
## Resources used 
- the docs have been mainly helpful whether man pages and GNU official documentation
### Creating your own container system
- [what started it all a great talk about utilizing btrfs for creating a copy on write fault tolerant file system which i didnt utilize becuase of the hassle](https://www.youtube.com/watch?v=sK5i-N34im8)
- [explorating into syscalls first and trying to run syscalls in bash which was later discovered to be useless after finding out about unshare and nsenter](https://www.youtube.com/watch?v=Utf-A4rODH8)
- [great talk explaining the docker architecture and why it was modularized](https://www.youtube.com/watch?v=VWuHWfEB6ro)
- [A great video as well breaking down creating your own container into bite-sized pieces](https://www.youtube.com/watch?v=JOsWB50LmwQ&t=1394s) 
- [Useful article creating it using simple bash commands](https://icicimov.github.io/blog/virtualization/Linux-Container-Basics/)
- [The go-to reference project and whom i was hugely inspired by](https://github.com/p8952/bocker/blob/master/bocker)
### cgroups
- [No better resource than redhat docs for me](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/resource_management_guide/chap-introduction_to_control_groups)
- [Was first introduced to cgroups v2 using this article](https://medium.com/@charles.vissol/practicing-cgroup-v2-cad6743bba0c)
- [great intro into cgroups well prepared and defined](https://www.youtube.com/watch?v=gcX8fqOVCpw&t=3115s)
- [solidifying your knowledge in cgroups v2 using systemd](https://www.youtube.com/watch?v=gcX8fqOVCpw&t=3115s) 
### mounting 
- [explaining mount bind and mount privelages](https://unix.stackexchange.com/questions/198590/what-is-a-bind-mount)
- [mounting systems to chroot](https://superuser.com/questions/165116/mount-dev-proc-sys-in-a-chroot-environment)
### chrooting
- [gnu docs for chroot best I've seen so far](https://www.gnu.org/software/coreutils/manual/html_node/chroot-invocation.html#chroot-invocation)
### namespaces
- [nsenter-docs nsenter is used for execing into the ran namespace](https://www.gnu.org/software/coreutils/manual/html_node/chroot-invocation.html#chroot-invocation)
- [unshare is used to fork the process and initate it into a new namespace](https://man7.org/linux/man-pages/man1/unshare.1.html)
- [ip netns used to virtualize the network namespace](https://man7.org/linux/man-pages/man8/ip-netns.8.html)
