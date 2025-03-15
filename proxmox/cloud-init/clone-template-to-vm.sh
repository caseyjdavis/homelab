#!/bin/bash

qm clone 9000 470 --name ubuntu-2404-test -full -storage local-lvm
qm set 470 --ipconfig0 ip=10.0.60.78/24,gw=10.0.60.1
qm resize 470 virtio0 +35G
qm set 470 --core 4 --memory 5120 --balloon 0
qm start 470