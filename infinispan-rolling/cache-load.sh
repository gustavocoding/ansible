OPTS=$@
ansible master -i inv.sh -m shell -a "cd /usr/local/ && ./load.sh $OPTS"  --user fedora --sudo
