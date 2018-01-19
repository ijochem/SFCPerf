# delete all classifiers and odl acls
for i in `tacker sfc-classifier-list | grep ACTIVE | awk '{print $4;}'`; do
   tacker sfc-classifier-delete $i
   python /root/acl_delete.py $i
done

# delete all odl acls
#for i in {1..11}; do
#   python /root/acl_delete.py c${i}_udp_$(($i+20000));
#   python /root/acl_delete.py c${i}_tcp_$(($i+20000));
#done

# delete all ovs flows
python /root/flow_delete.py

# delete all sfc
for i in `tacker sfc-list | grep ACTIVE | awk '{print $4;}'`; do
   tacker sfc-delete $i
done
