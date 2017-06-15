#!/bin/sh

ARGS=$@

docker pull centos:7
CONTAINER_ID=$(sudo docker run --privileged --interactive --tty --volume=${PWD}:/$(basename ${PWD}) --detach centos:7)
docker exec ${CONTAINER_ID} yum install -y yum-plugin-fastestmirror
docker exec ${CONTAINER_ID} adduser centos
docker exec ${CONTAINER_ID} usermod -G wheel centos
docker exec ${CONTAINER_ID} yum install -y sudo 
docker exec ${CONTAINER_ID} sed -i.bak \
  -e 's/\(^%wheel\s*ALL=(ALL)\s*ALL\)/# \1/' \
  -e 's/^#\s\(%wheel\s*ALL=(ALL)\s*NOPASSWD:\s*ALL\)/\1/' \
  /etc/sudoers
docker exec ${CONTAINER_ID} sudo -E -u centos bash -c "cd /X11RDP-RH-Matic; ./X11RDP-RH-Matic.sh ${ARGS}"
#docker attach ${CONTAINER_ID} 
docker stop ${CONTAINER_ID}
docker rm ${CONTAINER_ID} 
