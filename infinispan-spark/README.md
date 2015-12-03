## Spark and Infinispan cluster on Openstack

Download and source the rc file from Openstack
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


To provision a cluster, pick the number of servers, the key name, the infinispan server version and the server offset:

```
./create.sh <num_servers> <key_name> <flavour> <image_id> <infinispan_version> <spark_version> <offset>
```

example:

```
./create 10 "my_key" "m1.large" "f2df087c-4e54-4047-98c0-8e03dbf6412b" 8.1.0.Final 1.5.2 4
```

Will create 10 node cluster with the provided key, flavour and image id containing Infinispan Server 8.1.0.Final, Sparl 1.5.2 and will start from server #4.

To resume a failed playbook run:

```
ansible-playbook --user fedora -i inventory.py server.yaml --extra-vars "infinispanVersion=<infinispan_version> sparkVersion=<spark_version>"
```

The script assumes the following security groups are present and exposing the following TCP ports:

* spark: 4040, 7077, 8081, 9080, 9081
* infinispan_server: 11222, 57600

