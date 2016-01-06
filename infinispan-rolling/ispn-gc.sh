ansible all -i inv.sh -m shell -a "jcmd \$(jps | grep modules | awk '{print \$1}') GC.run" --user fedora --sudo
