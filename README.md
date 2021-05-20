# Glusterfs on AWS

This small Terraform + Ansible IaC creates VMs in AWS and installs GlusterFS on top of the provisioned infrastructure

## Usage
```
$ bash ./deploy.sh
$ ansible gluster_members  -m ping -i gluster_inventory
$ ansible-playbook -v -i gluster_inventory gluster-setup.yaml
```