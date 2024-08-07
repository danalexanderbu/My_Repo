#!/bin/bash
#
# generate ssh key pair. Unable to connect if I dont
if [ ! -f ~/.ssh/my_vagrant_key ]; then
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/my_vagrant_key -N ""
fi
# You could make your own vbox file and use it as a base box
# uses rocky 9.4
vagrant up

# Using vboxmanage for ips and bash to dynamically add the ip to the ansible hosts file
# Bash is awesome
# make sure hosts.ini is blank before running this script
# Path to the hosts.ini file
HOSTS_FILE="/home/$(whoami)/Documents/My_Repo/vagrant-ansible/RKE2/inventory/hosts.ini"

# Function to get the IP of a VM from eth1
get_vm_ip() {
    vm_name=$1
    ip=$(vboxmanage guestproperty get "$vm_name" "/VirtualBox/GuestInfo/Net/1/V4/IP" | awk '{print $2}')
    if [[ $ip == "No" || $ip == "" ]]; then
        ip="Not available"
    fi
    echo $ip
}

# Start the hosts.ini content
echo "[servers]" > $HOSTS_FILE

# Get and right IP addresses for servers
for i in 1 2; do
    vm=$(vboxmanage list vms | grep "vagrant-ansible_server${i}_" | awk -F\" '{print $2}')
    ip=$(get_vm_ip "$vm")
    echo "server${i} ansible_host=${ip} ansible_ssh_user=vagrant ansible_ssh_private_key_file=/home/sithlord/.ssh/my_vagrant_key" >> $HOSTS_FILE
done

for i in 1 2; do
    vm=$(vboxmanage list vms | grep "vagrant-ansible_agent${i}_" | awk -F\" '{print $2}')
    ip=$(get_vm_ip "$vm")
    ssh vagrant@$ip -o StrictHostKeyChecking=no
done

# Add agents header
echo "" >> $HOSTS_FILE
echo "[agents]" >> $HOSTS_FILE

# Get and right IP addresses for agents
for i in 1 2 3; do
    vm=$(vboxmanage list vms | grep "vagrant-ansible_agent${i}_" | awk -F\" '{print $2}')
    ip=$(get_vm_ip "$vm")
    echo "agent${i} ansible_host=${ip} ansible_ssh_user=vagrant ansible_ssh_private_key_file=/home/sithlord/.ssh/my_vagrant_key" >> $HOSTS_FILE
done

for i in 1 2 3; do
    vm=$(vboxmanage list vms | grep "vagrant-ansible_agent${i}_" | awk -F\" '{print $2}')
    ip=$(get_vm_ip "$vm")
    # add to local machine to known hosts
    ssh vagrant@$ip -o StrictHostKeyChecking=no
done

echo "hosts.ini file has been updated with VM IP addresses."

# Run the playbook
cd RKE2

# For some reason i need to ssh into the servers and agents before running the playbook
# running playbook without sshing into the servers and agents will result in an error
# Added --ask-become-pass to ask for sudo password for copying file to local kubeconfig
#ansible-playbook site.yaml -i inventory/hosts.ini --key-file ~/.ssh/my_vagrant_key --ask-become-pass