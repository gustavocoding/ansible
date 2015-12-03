#!/bin/bash

set -e -o pipefail -o errtrace -o functrace

export ANSIBLE_HOST_KEY_CHECKING=False

usage() { 
   echo -e "\nUsage:\n$0 [number of nodes] [key-name] [flavour] [image_id] [infinispan_version] [spark_version] ([start_from Id])\n"
} 

if [  $# -le 6 ]
then 
  usage
exit 1
fi 

# Number of nodes in the cluster
N=${1}
KEY_NAME=${2}
FLAVOUR=${3}
IMAGE=${4}
INFINISPAN_VERSION=${5}
SPARK_VERSION=${6}
START_FROM=${7,1}

SECURITY_GROUPS="default,spark,infinispan_server"
METADATA_MASTER="--meta ansible_host_groups=spark,master,slave,infinispan"
METADATA_SLAVE="--meta ansible_host_groups=spark,slave,infinispan"

for (( c=$START_FROM; c<=$N; c++))
do
  echo "Provisioning server $c"
  [[ $c = 1 ]] && METADATA="$METADATA_MASTER" || METADATA="$METADATA_SLAVE"
  SERVER=$(nova boot --flavor $FLAVOUR --image $IMAGE --security-groups $SECURITY_GROUPS --key-name $KEY_NAME $METADATA node$c | grep " id " | awk '{print $4}')
  STATUS=''
  while [[ "$STATUS" != "ACTIVE" ]];
  do
    STATUS=$(nova show $SERVER | grep status | awk '{print $4'})
    echo "Waiting for server to be ACTIVE (current status: $STATUS)"
    sleep 5
  done
  echo "Associating floating IP to server $SERVER"
  IP=$(nova floating-ip-create os1_public | grep os1_public | awk '{ print $2 }')
  nova floating-ip-associate $SERVER $IP
done

echo "Provisioning done."

sleep 30

echo "Running Playbook"

echo "Pre-caching the inventory"
CACHED_INVENTORY=inv.sh
./inventory.py > $CACHED_INVENTORY
sed -i '1i#!/bin/bash' $CACHED_INVENTORY
sed -i '2icat <<EOF' $CACHED_INVENTORY
echo "EOF" >> $CACHED_INVENTORY
chmod +x $CACHED_INVENTORY

ansible-playbook --user fedora -i inv.sh server.yaml --extra-vars "infinispanVersion=$INFINISPAN_VERSION sparkVersion=$SPARK_VERSION"
