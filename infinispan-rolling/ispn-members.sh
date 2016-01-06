ansible all -i inv.sh -m shell -a "/usr/local/infinispan/bin/ispn-cli.sh -c '/subsystem=datagrid-infinispan/cache-container=clustered:read-attribute(name=members)'"  --user fedora --sudo
