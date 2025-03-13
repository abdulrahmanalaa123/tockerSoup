#!/bin/bash

get_network (){
	current_links=$(sudo ip link show)
	# get the current running dns server you're using
	current_dns=$(resolvectl status | grep 'Current DNS' | cut -d':' -f2)
	# get the current device name which is used to connect you to the internet
	main_link=$(sudo ip route get "$current_dns" | sed -n 's/.*dev \([^\ ]*\).*/\1/p')
}


declare id=$(uuidgen)
# creating a randomized sudo ip suffix and mac address
ip="${id: -3}"
ip="${ip//[^0-9]/}"
# setting the default suffix with 2 in case the last 3 hexa not containing any numbers
ip="${ip:-2}"
ip="$((ip % 255))"
echo "your ip address is $ip"
mac="${id: -3:1}:${id: -2}"
uuid="${id::5}"

# creating the container's network namespace
sudo ip netns add netns_"$uuid"
# network components to delete on container deletion
# veth0_"$uuid" and the namespace netns_"$uuid" and veth1 is just deleted by simply existing inside the container
# veth_0 is the ehternet interafce on the host and veth_1 is the ethernet 
# interafce inside the container
sudo ip link add veth0_"$uuid" type veth peer name veth1_"$uuid" 
sudo ip link set veth1_"$uuid" netns netns_"$uuid"
# setting the loopback address as up inside the network namepsace
sudo ip netns exec netns_"$uuid" ip link set dev lo up
# setting the mac address of the virtual ethernet interface
sudo ip netns exec netns_"$uuid" ip link set veth1_"$uuid" address 02:42:ac:11:00"$mac"
# adding the sudo ip address of the veth0 
sudo ip addr add 10.0.3.1/24 dev veth0_"$uuid"
sudo ip netns exec netns_"$uuid" ip addr add 10.0.3."$ip"/24 dev veth1_"$uuid" 
# set the veth0 interafce as up 
sudo ip link set dev veth0_"$uuid" up
# setting the state of the veth1 to up
sudo ip netns exec netns_"$uuid" ip link set veth1_"$uuid" up
# making veth0 the default gateway
sudo ip netns exec netns_"$uuid" ip route add default via 10.0.3.1
# finally enabling the veth1 interface
network_type="host"
# getting the current main interface and the current dns server
get_network
bridge_name=$(grep  'bridge' "$NETWORK_CONFIG" | cut -d':' -f2)

case $network_type in
	bridge)
		sudo ip link set veth0_"$uuid" master "$bridge_name"
		echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
		;;
	host)
		# create a routing rule to forward packets from the source of 
		sudo iptables -A FORWARD -o $main_link -i veth0_"$uuid" -j ACCEPT
		echo "sudo iptables -D FORWARD -o $main_link -i veth0_$uuid -j ACCEPT"
		sudo iptables -A FORWARD -i $main_link -o veth0_"$uuid" -j ACCEPT
		echo "sudo iptables -D FORWARD -i $main_link -o veth0_$uuid -j ACCEPT"
		# mask the packets coming out of the veth1_ to be sourced from the main_link
		# to enable internet access to the container
		sudo iptables -t nat -A POSTROUTING -s 10.0.3."$ip"/24 -o $main_link -j MASQUERADE
		echo "sudo iptables -t nat -D POSTROUTING -s 10.0.3."$ip"/24 -o $main_link -j MASQUERADE"
		echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
		;;
	none)
		;;
esac

sudo ip netns exec netns_"$uuid" ping localhost
