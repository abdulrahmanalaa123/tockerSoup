# HOW TO RUN IT?
- clone the repo using git
```
git clone https://github.com/abdulrahmanalaa123/tockerSoup.git tocker
```
- simply cd into the directory where the project is located
```
cd tocker
```
- run the make file
```
make
```
- relogin for permissions to take effect or use it right away in the provided tockergrp shell
- provide the sudo permissions for the make commands
`sudo password: `
- To cleanly uninstall tocker you can simply run the make clean command
```
make clean
```
- you can view the help 
```
tocker help
```
## help file
```
tocker container run  --cpuquota [0-100] --memmax [num(B|K|M|G|T)] --memmin [num(B|K|M|G|T)] --memhigh [num(B|K|M|G|T)] <image_name> <command> # images are associate with an entryPoint can be done when pulling
tocker container exec <container_id|name> <command>
tocker container start <container_id|name>  keep running the image on the latest entrypoint
tocker container rm -f <container_id|name> -f removes the conatainer and stops it abruptly
tocker image rm -f <image_name> 
tocker container stop <container_id>
tocker image get <image_name>
tocker container (la|ls|l)
tocker image (la|ls|l)
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
- [Cgroups with systemd](https://www.redhat.com/en/blog/cgroups-part-four)
### systemd
- [understanding unit files](https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files)
- [creating oyur own slice file](https://serverfault.com/questions/1024514/systemd-how-do-i-create-a-new-slice-file)
- [creating template unit files](https://fedoramagazine.org/systemd-template-unit-files/)
- [Using cgroups with systemd-run](https://medium.com/@charles.vissol/systemd-and-cgroup-7eb80a08234d)
- [transient services with drop-in files](https://docs.oracle.com/en/operating-systems/oracle-linux/9/systemd/SystemdMngCgroupsV2.html#UsingDropInFiles2)
- [creating your own transient service](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/resource_management_guide/chap-using_control_groups#sec-Creating_Cgroups)
### mounting 
- [explaining mount bind and mount privelages](https://unix.stackexchange.com/questions/198590/what-is-a-bind-mount)
- [mounting systems to chroot](https://superuser.com/questions/165116/mount-dev-proc-sys-in-a-chroot-environment)
### chrooting
- [gnu docs for chroot best I've seen so far](https://www.gnu.org/software/coreutils/manual/html_node/chroot-invocation.html#chroot-invocation)
### namespaces
- [nsenter-docs nsenter is used for execing into the ran namespace](https://www.gnu.org/software/coreutils/manual/html_node/chroot-invocation.html#chroot-invocation)
- [unshare is used to fork the process and initate it into a new namespace](https://man7.org/linux/man-pages/man1/unshare.1.html)
- [ip netns used to virtualize the network namespace](https://man7.org/linux/man-pages/man8/ip-netns.8.html)
### networking
- [device types in a virtual network](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking#team_device)
- [creating your own virtual network](https://linuxconfig.org/configuring-virtual-network-interfaces-in-linux)
- [This article was a huge help in both configuring my network and containers in general](https://icicimov.github.io/blog/virtualization/Linux-Container-Basics/)
- [A complete guide to creating your own virtual network with internet access](https://josephmuia.ca/2018-05-16-net-namespaces-veth-nat/)
- [adding internet access to your virtual network ](https://askubuntu.com/questions/1214876/ubuntu-server-virtual-network-interface-with-internet-access)
