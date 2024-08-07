You will need to get the ip addresses for the hosts.ini file.

IP addresses can be found in the ip folder on the vm.
    - Need to find a way to dynamically get ips and update hosts.ini

Will take a while to complete. To run do:
ansible-playbook site.yaml -i inventory/hosts.ini --key-file ~/.ssh/my_vagrant_key