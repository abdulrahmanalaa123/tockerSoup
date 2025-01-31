# HOW TO RUN IT?
- first run the script init.sh to initialize the image location and permissions

- the init.sh requires sudo permissions to perform such operations such as setting up the operating dir as well as adding the tocker group so you will be prompted for your sudo password if password is enabled in your sudoers file

- at first you shouldve reloaded to have group permissions just creating the group is needed in the latest commit to assign the permissions which resolves adding it to the group permenantly since its not needed using the setgid bit but the permission_wrapper solution was a bit useful

- next run the tocker.sh script
