ansible all -i inv.sh -m shell -a "/usr/local/infinispan/bin/ispn-cli.sh -c '/subsystem=logging/logger=org.infinispan:add'"  --user fedora --sudo
ansible all -i inv.sh -m shell -a "/usr/local/infinispan/bin/ispn-cli.sh -c '/subsystem=logging/logger=org.infinispan:write-attribute(name=level,value=TRACE)'"  --user fedora --sudo
