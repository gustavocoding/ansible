#!/bin/bash

set -e -o pipefail -o errtrace -o functrace

export ANSIBLE_HOST_KEY_CHECKING=False

usage() {

cat << EOF
Usage: ./cache-clear.sh -l label [opts]

        -l label for the cluster

[opts]
--entries num [--write-batch num] [--max-phrase-size num]     

entries          number of entries to load
write-batch      how many entries to send with each put
max-phrase-size  maximum number of words in the random phrases generated

EOF
}

while getopts "l:h" o > /dev/null 2>&1; do
    case "${o}" in
        h) usage; exit 0;;
        l)
            l=${OPTARG}
            ;;
    esac
done
#shift $((OPTIND-1))

if [ ! "$l" ]
then
    echo "ERROR: cluster label (-l) is required"
    usage
    exit 1
fi

ansible master -i inv-$l.sh -m shell -a "cd /usr/local/ && ./load.sh $*"  --user fedora --sudo
