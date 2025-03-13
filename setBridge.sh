#!/bin/bash

. ./helpers.sh

if [[ -z $1 ]]
then
	get_network	

	if [[ $current_links =~ bridge0 ]]
	then
		echo "bridge is all set"
	else
		sudo ip link add bridge0 type bridge
		# setting the bridge as the matser of your current network interface device
#		echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
		sudo iptables -t nat -A POSTROUTING -o bridge0 -j MASQUERADE
		sudo iptables -t nat -A POSTROUTING -o "$main_link" -j MASQUERADE
		sudo ip addr add 10.0.3.1/24 dev bridge0
		sudo ip link set bridge0 up
		echo "main_link:$main_link" >> "$NETWORK_CONFIG"
		echo "configured_dns:$current_dns" >> "$NETWORK_CONFIG"
		echo "bridge:bridge0" >> "$NETWORK_CONFIG"
	fi
else
	main_link=$(grep 'main_link' "$NETWORK_CONFIG" | cut -d':' -f2)
	configured_dns=$(grep  'configured_dns' "$NETWORK_CONFIG" | cut -d':' -f2)
	bridge_name=$(grep  'bridge' "$NETWORK_CONFIG" | cut -d':' -f2)
	
	sudo ip link delete "$bridge_name" type bridge
	iptables -t nat -D POSTROUTING -o bridge0 -j MASQUERADE
	iptables -t nat -D POSTROUTING -o "$main_link" -j MASQUERADE
#	echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward

fi

