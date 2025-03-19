BASE_DIR := /var/tocker
OUT_PATH := $(BASE_DIR)/tocker_images
CONT_PATH := $(BASE_DIR)/tocker_containers
META_PATH := $(BASE_DIR)/tocker_meta
LOG_PATH := $(BASE_DIR)/container_logs
CURRENT_USER := $(shell whoami)
RULES := /etc/sudoers.d/tocker_rules
OPT_DIR := /opt/tocker
HELP := $(OPT_DIR)/helper
NETWORK := $(OPT_DIR)/network_config
SLICE := /etc/systemd/system/tocker.slice
LOGGER_TEMPLATE := /etc/systemd/system/tocker_container_logger@.service
CORE_SCRIPT := $(OPT_DIR)/tocker.sh
HELPERS_SCRIPT := $(OPT_DIR)/helpers.sh
PARSER_SCRIPT := /home/$(CURRENT_USER)/bin/tocker

#https://stackoverflow.com/questions/649246/is-it-possible-to-create-a-multi-line-string-variable-in-a-makefile

#check_current_dir:
	#mv ./tockerParser.sh ~/bin/tocker
open_tocker_shell: $(PARSER_SCRIPT)
	echo "You're now in a tocker group shell you can relogin your system after running the tocker commands right now to be able to run tocker regularly"
	newgrp tocker 
$(PARSER_SCRIPT): $(CORE_SCRIPT)
	sudo cp tockerParser.sh $(PARSER_SCRIPT)
$(CORE_SCRIPT): $(HELPERS_SCRIPT)
	sudo cp tocker.sh $(CORE_SCRIPT)
$(HELPERS_SCRIPT): $(META_PATH)
	sudo cp helpers.sh $(HELPERS_SCRIPT)
$(META_PATH): $(CONT_PATH)
	sudo mkdir $(META_PATH)
	sudo mkdir $(META_PATH)/images
	sudo mkdir $(META_PATH)/containers
$(CONT_PATH) : $(OUT_PATH)
	sudo mkdir $(CONT_PATH)
$(OUT_PATH): $(LOG_PATH)
	sudo mkdir $(OUT_PATH)
$(LOG_PATH): $(LOGGER_TEMPLATE)
	sudo mkdir $(LOG_PATH)
$(LOGGER_TEMPLATE): $(SLICE)
	sudo cp ./templates/tocker_container_logger@.service $(LOGGER_TEMPLATE)
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
	sudo rm -f $(LOGGER_TEMPLATE)
	sudo rm -f $(PARSER_SCRIPT)
