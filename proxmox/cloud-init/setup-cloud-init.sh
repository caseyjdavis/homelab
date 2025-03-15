#!/bin/bash

# Prompt for username and password
read -p "Enter custom user name: " CUSTOM_USER_NAME
read -p "Enter custom user password: " CUSTOM_USER_PASSWORD
echo

# Downloading public keys from GitHub
curl https://github.com/caseyjdavis.keys -o .authorized_keys

# Check if the image file already exists
if [ ! -f noble-server-cloudimg-amd64.img ]; then
    # Download Ubuntu Cloud Image
    wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
else
    echo "Image file noble-server-cloudimg-amd64.img already exists. Skipping download."
fi

# Resize the image to 32GB
qemu-img resize noble-server-cloudimg-amd64.img 32G

# Create initial vm using the cloud image
qm create 9000 --name "ubuntu-2404-cloudinit" --ostype l26 \
    --memory 1024 \
    --agent 1 \
    --bios ovmf --machine q35 --efidisk0 local-lvm:0,pre-enrolled-keys=0 \
    --cpu host --socket 1 --cores 1 \
    --vga serial0 --serial0 socket  \
    --net0 virtio,bridge=vmbr0

# Import the disk and local storage
qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm

# Configure the imported disk
qm set 9000 --scsihw virtio-scsi-pci --virtio0 local-lvm:vm-9000-disk-1,discard=on

# Set the boot order
qm set 9000 --boot order=virtio0

# Add the cloud-init drive
qm set 9000 --ide2 local-lvm:cloudinit

# Create the vendor.yaml file
cat << EOF | tee /var/lib/vz/snippets/vendor.yaml
#cloud-config
runcmd:
    - apt update
    - apt install -y qemu-guest-agent
    - systemctl start qemu-guest-agent
    - reboot
EOF

# Configure cloud-init
qm set 9000 --cicustom "vendor=local:snippets/vendor.yaml"
qm set 9000 --tags ubuntu-template,24.04,cloudinit
qm set 9000 --ciuser $CUSTOM_USER_NAME --ciupgrade 1
qm set 9000 --cipassword $(openssl passwd -6 $CUSTOM_USER_PASSWORD)
qm set 9000 --sshkeys .authorized_keys
qm set 9000 --ipconfig0 ip=dhcp

# Update the cloud-init configuration
qm cloudinit update 9000

# Convert vm to template
qm template 9000