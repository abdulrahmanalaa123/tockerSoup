BASE_DIR := /var/tocker
OUT_PATH := $(BASE_DIR)/tocker_images
CONT_PATH := $(BASE_DIR)/tocker_containers
META_PATH := $(BASE_DIR)/tocker_meta
CURRENT_USER := $(shell whoami)
current_dir := $(shell pwd)
RULES := /etc/sudoers.d/tocker_rules
OPT_DIR := /opt/tocker
HELP := /opt/tocker/helper
NETWORK := /var/opt/network_config
SLICE := /etc/systemd/system/tocker.slice

#https://stackoverflow.com/questions/649246/is-it-possible-to-create-a-multi-line-string-variable-in-a-makefile

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
$(OUT_PATH): $(SLICE)
	sudo mkdir $(OUT_PATH)
$(SLICE): $(RULES)
	sudo cp tocker.slice $(SLICE)
$(RULES): set_permissions 
	sudo cp tocker_rules $(RULES)
set_permissions: $(BASE_DIR) $(OPT_DIR) $(HELP) $(NETWORK)
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
$(NETWORK): $(OPT_DIR)
	sudo ./setBridge.sh
$(HELP): $(OPT_DIR)
	sudo cp helper $(OPT_DIR)
$(OPT_DIR): $(BASE_DIR)
	sudo mkdir $(OPT_DIR)
$(BASE_DIR): ./tockerParser.sh
	sudo mkdir $(BASE_DIR)
clean:
	sudo ./setBridge.sh delete
	sudo rm -rf $(BASE_DIR)
	sudo rm -rf $(OPT_DIR)
	sudo rm -f $(RULES)
	sudo rm -f $(SLICE)

