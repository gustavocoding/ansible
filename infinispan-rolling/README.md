## Infinispan rolling upgrade test on Openstack

### Preparation

Download and ./source the rc file from Openstack  
Log in to the OpenStack dashboard, choose the project for which you want  
to download the OpenStack RC file, and click 'Access & Security', then go to 'API Access'. 
Click 'Download OpenStack RC File' and save the file. Source it using: 

```
source openstack.rc
```

Install the package novaclient using dnf/yum or your system's package manager:

```
dnf install python-novaclient
```

Check the variable ```OS_NETWORK_NAME``` in the script file ```inventory.py``` to 
match the Openstack installation

The script assumes the following security groups are present in openstack and exposing the following TCP ports:

* infinispan_server: 11222, 57600


### Provisioning

To provision the source and target clusters, run the script ./create.sh and follow help instructions.

example:

```
./create 10 -k "my_key" -i "m1.large" -f "f2df087c-4e54-4047-98c0-8e03dbf6412b" -v 8.1.0.Final -s 4
```

Will create 10 node cluster with the provided key, flavour and image id containing Infinispan Server 8.1.0.Final, and will start from server #4.

To provision an infinispan cluster built from sources:

```
./create 10 -k "my_key" -i "m1.large" -f "f2df087c-4e54-4047-98c0-8e03dbf6412b" -r https://github.com/infinispan.git -b master
```

Will create the cluster from the specified github repo (-r) and branch (-b) 

### Error recovery

To resume a failed playbook run:

```
ansible-playbook --user fedora -i inventory.py server.yaml --extra-vars "infinispanVersion=<infinispan_version> github=<git repo> branch=<branch>"
```

### Utility scripts

* cache-size.sh:   Prints the cache size of each member
* ispn-members.sh: Prints the members of the cluster, as seen by each member
* ispn-gc.sh:      Triggers a garbage collection cycle on all members
* cache-clear.sh:  Erases all data on the default cache
* cache-debug.sh:  Increase log level for org.infinispan to TRACE
* cache-load.sh:   Load cache with data, keys are integers and values are random phrases generated from the Linux dictionary  
                   Example: ./cache-load.sh --entries 100000 --write-batch 20000 --max-phrase-size 10
