# Glusterfs on AWS

This small Terraform + Ansible IaC creates VMs in AWS and installs GlusterFS on top of the provisioned infrastructure

**WARNING:** This setup disables all firewalls and opens up the GlusterFS for the whole World. Don't even play with it like that.

## Usage
```
$ bash ./deploy.sh
$ ansible gluster_members  -m ping -i gluster_inventory
$ ansible-playbook -v -i gluster_inventory gluster-setup.yaml
```