import requests
import sys

# python acl_delete.py acl1 acl2 acl3 ...

for acl_name in sys.argv[1:]:
   acl_url = 'http://admin:admin@10.240.114.130:8181/restconf/config/ietf-access-control-list:access-lists/acl/ietf-access-control-list:ipv4-acl/' + acl_name
   r = requests.delete(acl_url)
   print acl_name, 'deleting status:', r.status_code
