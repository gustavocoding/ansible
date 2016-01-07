#!/bin/bash

set -e -o pipefail -o errtrace -o functrace

export ANSIBLE_HOST_KEY_CHECKING=False


DEFAULT_NODES=2
DEFAULT_FLAVOUR="m1.large"
DEFAULT_VERSION="8.1.0.Final"
DEFAULT_START_INDEX=1

usage() {

cat << EOF

Usage: ./create.sh -k key -i image -l label [-n nodes] [-f flavour] [-v infinispan version] [-c source cluster] [-r github repo] [-b git branch] [-s start] 

	-k the key name on openstack 

        -i openstack image id

	-l label for the cluster

	-n number of nodes (default=$DEFAULT_NODES)

	-f image flavour (default=$DEFAULT_FLAVOUR)

	-v infinispan version (default=$DEFAULT_VERSION if github repo and branch not specified) 
 
        -c source cluster to point to (remote cache loader)

	-r github repo to build from sources (not used if -v specified)

	-b git branch to build from sources (not used if -v specified)

	-s start from server index (default=$DEFAULT_START_INDEX)
        
        -h help

EOF

}
while getopts ":k:i:n:f:v:r:b:s:c:l:h" o; do
    case "${o}" in
        h) usage; exit 0;;
        k)
            k=${OPTARG}
            ;;
        i)
            i=${OPTARG}
            ;;
        l)
            l=${OPTARG}
            ;;
        n)
            n=${OPTARG}
            ;;
        f)
            f=${OPTARG}
            ;;
        v)
            v=${OPTARG}
            ;;
        c)
            c=${OPTARG}
            ;;
        r)
            r=${OPTARG}
            ;;
        b)
            b=${OPTARG}
            ;;
        s)
            s=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ ! "$k" ] || [ ! "$i" ]
then
    echo "ERROR: -k and -i are mandatory"
    usage
    exit 1
fi

if [ ! "$l" ]
then
    echo "ERROR: must provide a label for the cluster (ex. 'mycluster')"
    usage
    exit 1
fi

if [ "$v" ] && ([ "$r" ] || [ "$b" ])
then
   echo "WARNING: -r and -b will be ignored since infinispan version was specified"
fi

if [ ! "$v" ] && ([ "$b" ] && [ ! "$r" ])
then
   echo "ERROR: missing git repo"
   usage
   exit 1
fi

if [ ! "$v" ] && ([ ! "$b" ] && [ "$r" ])
then
   echo "ERROR: missing git branch"
   usage
   exit 1
fi


KEY_NAME=${k}
IMAGE=${i}
N=${n:-$DEFAULT_NODES}
FLAVOUR=${f:-$DEFAULT_FLAVOUR}
if [ ! "$r" ] 
then
  INFINISPAN_VERSION=${v:-$DEFAULT_VERSION}
fi
GITHUB_REPO=${r}
GITHUB_BRANCH=${b}
SOURCE_CLUSTER=${c}
START_FROM=${s:-$DEFAULT_START_INDEX}
LABEL=${l}

SECURITY_GROUPS="default,infinispan_server"

for (( c=$START_FROM; c<=$N; c++))
do
  echo "Provisioning server $c"
  SERVER=$(nova boot --flavor $FLAVOUR --image $IMAGE --security-groups $SECURITY_GROUPS --key-name $KEY_NAME node$c-$LABEL | grep " id " | awk '{print $4}')
  STATUS=''
  while [[ "$STATUS" != "ACTIVE" ]];
  do
    STATUS=$(nova show $SERVER | grep status | awk '{print $4'})
    echo "Waiting for server to be ACTIVE (current status: $STATUS)"
    sleep 5
  done
  echo "Associating floating IP to server $SERVER"
  IP=$(nova floating-ip-create os1_public | grep os1_public | awk '{ print $2 }')
  [[ $c = 1 ]] && MASTER=$IP 
  MEMBER[c]=\"$IP\"
  nova floating-ip-associate $SERVER $IP
done

echo "Provisioning done."

sleep 30

echo "Running Playbook"

echo "Generating the inventory"
INVENTORY="inv-$LABEL.sh"

cat > $INVENTORY << END
#!/bin/bash
cat <<EOF
{
  "master": {
     "hosts": [
        "$MASTER"
     ]
  }, 
  "infinispan": {
     "hosts": [
         $(IFS=, ; echo "${MEMBER[*]}" )
     ]
  }
}
EOF
END

chmod +x $INVENTORY

echo "Playbook variables: infinispanVersion=$INFINISPAN_VERSION github=$GITHUB_REPO branch=$GITHUB_BRANCH cluster=$SOURCE_CLUSTER"

ansible-playbook --user fedora -i inv-$LABEL.sh server.yaml --extra-vars "infinispanVersion=$INFINISPAN_VERSION github=$GITHUB_REPO branch=$GITHUB_BRANCH cluster=$SOURCE_CLUSTER"
