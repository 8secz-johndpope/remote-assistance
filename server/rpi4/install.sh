#!/bin/bash

sudo apt update -y
sudo apt ugprade -y
sudo apt install -y nginx hostapd dnsmasq dhcpcd openssh-server stun-client stun-server

sudo cp -vr ./etc /

if [ ! \( -L /etc/nginx/sites-enabled/rhelp.fxpal.net \) ]; then
    sudo rm -f /etc/nginx/sites-enabled/rhelp.fxpal.net
    sudo ln -s /etc/nginx/sites-available/rhelp.fxpal.net /etc/nginx/sites-enabled/rhelp.fxpal.net
fi

sudo systemctl daemon-reload
sudo systemctl enable ssh
sudo systemctl enable hostapd
sudo systemctl enable remote-assistance
sudo systemctl enable dhcpcd
sudo systemctl enable nginx
sudo systemctl enable stun
#sudo systemctl restart ssh
#sudo systemctl restart hostapd
#sudo systemctl resatrt dnsmasq
#sudo systemctl restart dhcpcd

echo "Reboot is required." 
