#!/bin/bash

sudo apt update -y
sudo apt ugprade -y
sudo apt install -y nginx hostapd dnsmasq dhcpcd openssh-server

sudo cp -vr ./etc /

sudo systemctl daemon-reload
sudo systemctl enable ssh
sudo systemctl enable hostapd
sudo systemctl enable remote-assistance
sudo systemctl enable dhcpcd
#sudo systemctl restart ssh
#sudo systemctl restart hostapd
#sudo systemctl resatrt dnsmasq
#sudo systemctl restart dhcpcd

echo "Reboot is required." 
