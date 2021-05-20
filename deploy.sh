#!/bin/bash

set -e

if [ ! -e id_rsa_glusterroot ]
then
  ssh-keygen -t rsa -f id_rsa_glusterroot -q -N ""
fi


terraform apply

cp gluster_ssh_config ~/.ssh/config.d
