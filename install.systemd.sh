#!/bin/bash

if [[ ! -e "output/finger2023" ]] ; then
	echo "Please build main executable first!"
	echo "Use make.sh script!"
	exit
fi

echo "Installing main executable..."

sudo install "output/finger2023" "/usr/bin/finger2023"

echo "Installing systemd files..."

sudo install "systemd/finger2023.socket" "/etc/systemd/system/finger2023.socket"
sudo install "systemd/finger2023@.service" "/etc/systemd/system/finger2023@.service"
sudo install -b "systemd/finger2023.env" "/etc/default/finger2023.env"

echo "Enabling systemd service..."

sudo systemctl daemon-reload
sudo systemctl enable finger2023.socket
sudo systemctl start finger2023.socket
sudo systemctl status finger2023.socket

echo "Done!"
