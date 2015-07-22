## Spark and Infinispan cluster on Openstack

Download and source the rc file from Openstack
Log in to the OpenStack dashboard, choose the project for which you want 
to download the OpenStack RC file, and click Access & Security.
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


To provision a cluster, pick the number of servers and the key name:

```
./create.sh <num_servers> <key_name> <flavour> <image_id>
```

example:

```
./create 3 "my_key" "m1.large" "f2df087c-4e54-4047-98c0-8e03dbf6412b"
```

The script assumes the following security groups are present and exposing the following TCP ports:

* spark: 4040, 7077, 8081, 9080, 9081
* infinispan_server: 11222, 57600

