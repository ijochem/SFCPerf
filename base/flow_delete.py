import json
import requests

flow_url = 'http://admin:admin@10.240.114.130:8181/restconf/operational/opendaylight-inventory:nodes'
#flow_url = 'http://admin:admin@10.240.114.130:8181/restconf/config/opendaylight-inventory:nodes'

tables = ['11','1'] # tables onde fluxos de sfc costumam ficar
nodes = []
a = requests.get(flow_url)
b =json.loads(a.content)
for i in b['nodes']['node']:
    print i['id']
    nodes.append(i['id'])

l = []
k = 0
while k < len(a.content):
    k = k +1 + a.content[k+1:].find("sfc")
    if k+1+a.content[k+1:].find("sfc") == k: break
    l.append(k)

flows = []
for i in l:
    print a.content[i:].split("\"")[0]
    flows.append(a.content[i:].split("\"")[0])

for openflow_id in nodes:
    for table in tables:
        for flow_id in flows:
            flow_url = 'http://admin:admin@10.240.114.130:8181/restconf/config/opendaylight-inventory:nodes/node/' + openflow_id + '/table/' + table + '/flow/' + flow_id
            r = requests.delete(flow_url)
            if r.status_code == 200:
                print 'Deleted:', flow_id
