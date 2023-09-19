#!/bin/bash

# Set the base properties
ISO_PATH="/home/sithlord/Downloads/ubuntu-22.04.2-live-server-amd64.iso"
VM_PATH="/home/sithlord/VirtualBox VMs"
BRIDGE_ADAPTER=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
RAM=6144
CPU=4
DISK_SIZE=80000

# Array of VM names
declare -a VMs=("master-1" "master-2" "worker-1" "worker-2" "loadbalancer-1")

# Download the latest Ubuntu Server ISO
if [ ! -f "$ISO_PATH" ]; then
    echo "Ubuntu Server ISO not found. Downloading..."
    curl -o $ISO_PATH "https://opencolo.mm.fcix.net/ubuntu-releases/22.04.2/ubuntu-22.04.2-live-server-amd64.iso"
else
    echo "Ubuntu Server ISO already exists. Skipping download."
fi

# Loop over VM names
for VM_NAME in "${VMs[@]}"; do
    # Create the VM
    VBoxManage createvm --name $VM_NAME --basefolder "$VM_PATH" --ostype "Ubuntu_64" --register

    # Set the RAM and CPU
    VBoxManage modifyvm $VM_NAME --memory $RAM --cpus $CPU

    # Create a virtual hard disk
    VBoxManage createmedium disk --filename "$VM_PATH/$VM_NAME/$VM_NAME.vdi" --size $DISK_SIZE

    # Attach the hard disk to the VM
    VBoxManage storagectl $VM_NAME --name "SATA Controller" --add sata --controller IntelAHCI
    VBoxManage storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_PATH/$VM_NAME/$VM_NAME.vdi"

    # Attach the Ubuntu Server ISO to the VM
    VBoxManage storagectl $VM_NAME --name "IDE Controller" --add ide
    VBoxManage storageattach $VM_NAME --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $ISO_PATH

    # Set the network adapter to bridged mode
    VBoxManage modifyvm $VM_NAME --nic1 bridged --bridgeadapter1 $BRIDGE_ADAPTER

    # Start the VM
    VBoxManage startvm $VM_NAME
done
