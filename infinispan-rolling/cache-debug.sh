#!/bin/bash

set -e -o pipefail -o errtrace -o functrace

export ANSIBLE_HOST_KEY_CHECKING=False

usage() {

cat << EOF
Usage: ./cache-clear.sh -l label

        -l label for the cluster
EOF
}

while getopts "l:h" o; do
    case "${o}" in
        h) usage; exit 0;;
        l)
            l=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ ! "$l" ]
then
    echo "ERROR: cluster label (-l) is required"
    usage
    exit 1
fi


ansible all -i inv-$l.sh -m shell -a "/usr/local/infinispan/bin/ispn-cli.sh -c '/subsystem=logging/logger=org.infinispan:add'"  --user fedora --sudo
ansible all -i inv-$l.sh -m shell -a "/usr/local/infinispan/bin/ispn-cli.sh -c '/subsystem=logging/logger=org.infinispan:write-attribute(name=level,value=TRACE)'"  --user fedora --sudo
