BASE_DIR := /var/tocker
OUT_PATH := $(BASE_DIR)/tocker_images
CONT_PATH := $(BASE_DIR)/tocker_containers
META_PATH := $(BASE_DIR)/tocker_meta
CURRENT_USER := $(shell whoami)
current_dir := $(shell pwd)
RULES := /etc/sudoers.d/tocker_rules
HELP := /opt/tocker/helper
OPT_DIR := /opt/tocker

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
#tocker parser would be the entrypoint and would call from opts/tocker/tocker
#and help would be from /opt/tocker/help
open_tocker_shell: $(META_PATH)
	echo "You're now in a tocker group shell you can relogin your system after running the tocker commands right now to be able to run tocker regularly"
	newgrp tocker 
$(META_PATH): $(CONT_PATH)
	sudo mkdir $(META_PATH)
	sudo mkdir $(META_PATH)/images
	sudo mkdir $(META_PATH)/containers
$(CONT_PATH) : $(OUT_PATH)
	sudo mkdir $(CONT_PATH)
$(OUT_PATH): $(RULES)
	sudo mkdir $(OUT_PATH)
$(RULES): set_permissions 
	echo "$$SUDOERS_VAR" | sudo tee $(RULES)
set_permissions: $(BASE_DIR) $(OPT_DIR) $(HELP)
	-sudo gpasswd -a $(CURRENT_USER) tocker;
	sudo chmod g=rwx $(OPT_DIR);
	sudo chmod g=rwx $(BASE_DIR);
	sudo chmod g+s $(OPT_DIR);
	sudo chmod g+s $(BASE_DIR);
	sudo chown :tocker $(OPT_DIR);
	sudo chown :tocker $(BASE_DIR);
	@# that was because the default permissions on the group was r-s which is the so assigning the mask solved the issue
	@# setting the tocker owner of the group and setting the setgid bit doesnt give permission while running sg tocker -c
	sudo setfacl -dm "m::rwx" $(OPT_DIR);
	sudo setfacl -dm "m::rwx" $(BASE_DIR);
$(HELP): $(OPT_DIR)
	echo "$$HELP_FILE" | sudo tee $(HELP)
$(OPT_DIR): $(BASE_DIR)
	sudo mkdir $(OPT_DIR)
$(BASE_DIR): ./tockerParser.sh
	sudo mkdir $(BASE_DIR)

clean:
	sudo rm -rf $(BASE_DIR)
	sudo rm -rf $(OPT_DIR)
	sudo rm -r $(RULES)
