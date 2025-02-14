BASE_DIR := /var/tocker
OUT_PATH := $(BASE_DIR)/tocker_images
META_PATH := $(BASE_DIR)/tocker_meta
CURRENT_USER := $(shell whoami)
current_dir := $(shell pwd)

#https://stackoverflow.com/questions/649246/is-it-possible-to-create-a-multi-line-string-variable-in-a-makefile
define SUDOERS_VAR

Cmnd_Alias      TOCKER_ALIAS= /usr/bin/unshare, /usr/bin/systemctl, /usr/sbin/chroot, /usr/bin/systemd, /usr/sbin/ip 
%tocker         ALL= (root) NOPASSWD: TOCKER_ALIAS 

endef

export SUDOERS_VAR

define HELP_FILE
tocker container run  --cpuquota [0-100] --iowrite [num(B|K|M|G|T)] --ioread [num(B|K|M|G|T)] --memmax [num(B|K|M|G|T)] --memmin [num(B|K|M|G|T)] --memhigh [num(B|K|M|G|T)] <image_name> <command> # images are associate with an entryPoint can be done when pulling
tocker container exec <container_id> <command>
tocker container start <container_id>  keep running the image on the latest entrypoint
tocker container rm -rf <container_id>  -r remove the container alongside its respective image -f removes the conatainer and stops it abruptly
tocker image rm -f <image_name> 
tocker container stop <container_id>
tocker image get <image_name>
tocker container (la|ls|l)
tocker image (la|ls|l)
endef
export HELP_FILE
# empty make to stop from running it by mistake


#check_current_dir:
	#mv ./tockerParser.sh ~/bin/tocker
#tocker parser would be the entrypoint and would call from opts/tocker/helpers opts/tocker/tocker
#and help would be from /opt/tocker/help
help:
	echo "$$HELP_FILE"
open_tocker_shell: sudoer_tocker
	echo "You're now in a tocker group shell you can relogin your system after running the tocker commands right now to be able to run tocker regularly"
	newgrp tocker 
# add tocker to /usr/bin how to do so with which permissions
sudoer_tocker: create_out_path
	echo "$$SUDOERS_VAR" | sudo tee /etc/sudoers.d/tocker_rules
create_meta_path: create_out_path
	sudo mkdir $(META_PATH)
create_out_path: set_permissions
	sudo mkdir $(OUT_PATH)
set_permissions: create_base_dir
	sudo groupadd tocker
	sudo gpasswd -a $(CURRENT_USER) tocker
	sudo chmod g=rwx $(BASE_DIR)
	sudo chmod g+s $(BASE_DIR)
	sudo chown :tocker $(BASE_DIR)
	# setting the tocker owner of the group and setting the setgid bit doesnt give permission while running sg tocker -c
	# that was because the default permissions on the group was r-s which is the so assigning the mask solved the issue
	sudo setfacl -dm "m::rwx" $(BASE_DIR)
create_base_dir:
	sudo mkdir $(BASE_DIR)
