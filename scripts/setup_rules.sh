#!/bin/bash
cp 99-usb-serial.rules /etc/udev/rules.d/99-usb-serial.rules
sudo udevadm trigger
udevadm test -a -p $(udevadm info -q path -n /dev/my3dprinter)

