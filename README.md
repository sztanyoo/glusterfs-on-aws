$ bash ./deploy.sh
$ ansible gluster_members  -m ping -i gluster_inventory
$ ansible-playbook -v -i gluster_inventory gluster-setup.yaml
