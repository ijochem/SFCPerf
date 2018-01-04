#!/bin/bash


servidor='10.240.114.46'
cliente='10.240.114.48'
chain=''
echo Killing processes on server...
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} killall -1 httperf -2 iperf -3 python
echo Killing processes on client...
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${cliente} killall -1 httperf -2 iperf -3 python

for i in {1..11}; do
   chain="${chain}gta-vnf${i}"
   echo Creating chain $i ...
   echo tacker sfc-create  --name gta-c${i} --chain ${chain}
   tacker sfc-create  --name gta-c${i} --chain ${chain}
   echo tacker sfc-classifier-create --name c${i}_tcp_$(($i+20000)) --chain gta-c${i} --match source_port=0,dest_port=$(($i+20000)),protocol=6
   tacker sfc-classifier-create --name c${i}_tcp_$(($i+20000)) --chain gta-c${i} --match source_port=0,dest_port=$(($i+20000)),protocol=6
   echo tacker sfc-classifier-create --name c${i}_udp_$(($i+20000)) --chain gta-c${i} --match source_port=0,dest_port=$(($i+20000)),protocol=17
   tacker sfc-classifier-create --name c${i}_udp_$(($i+20000)) --chain gta-c${i} --match source_port=0,dest_port=$(($i+20000)),protocol=17
   sleep 30

# httperf
   echo Starting httperf on chain $i ...
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} screen -dmS http$chain "python -m SimpleHTTPServer $(($i+20000))"
   for j in {1..20}; do
      if [ $j -lt 20 ]; then
         sshpass -p "opnfv" ssh root@${cliente} "httperf --server 10.10.0.5 --port $(($i+20000)) --num-conns=3000 -v 2> /dev/null | grep 'Connection rate'" | awk '{print $3;}' | tr '\n' ',' >> conns_x_vnfs_topo1.csv
      else
         sshpass -p "opnfv" ssh root@${cliente} "httperf --server 10.10.0.5 --port $(($i+20000)) --num-conns=3000 -v 2> /dev/null | grep 'Connection rate'" | awk '{print $3;}' >> conns_x_vnfs_topo1.csv
      fi
      echo chain-$i httperf $j/20
      sleep 3
   done

   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} killall python

# iperf
   echo Starting iperf on chain $i ...
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} screen -dmS iperf${i} "iperf -s -i 1 -p $(($i+20000))"
   for j in {1..20}; do
      if [ $j -lt 20 ]; then
         sshpass -p "opnfv" ssh root@${cliente} "iperf -c 10.10.0.5 -p $(($i+20000)) -t 10 | grep 0.0-" | awk '{print $7}' | tr '\n' ',' >> vazao_x_vnfs_topo1.csv
      else
         sshpass -p "opnfv" ssh root@${cliente} "iperf -c 10.10.0.5 -p $(($i+20000)) -t 10 | grep 0.0-" | awk '{printf("%s,%s\n",$7,$8);}' >> vazao_x_vnfs_topo1.csv
      fi
      echo chain-$i iperf $j/20
      sleep 3
   done

# nc-latency
   echo Starting nc-latency on chain $i ...
   for j in {1..200}; do
      if [ $j -lt 200 ]; then
         { sshpass -p "opnfv" ssh root@${cliente} "time nc -zw 5 10.10.0.5 $(($i+20000))"; } |& grep real | awk '{print $2;}' | tr '\n' ',' >> rtt_x_vnfs_topo1.csv
      else
         { sshpass -p "opnfv" ssh root@${cliente} "time nc -zw 5 10.10.0.5 $(($i+20000))"; } |& grep real | awk '{print $2;}' >> rtt_x_vnfs_topo1.csv
      fi
      if [ $(($j % 10)) -eq 0 ]; then
         echo chain-$i nc $j/200
      fi
      sleep 1
   done

   chain="${chain},"
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} killall iperf

done

mkdir results-new
sed -re 's/s|0m//g' rtt_x_vnfs_topo1.csv > ./results-new/rtt_x_vnfs_topo1.csv
sed -re 's/,Mbits\/sec//g' vazao_x_vnfs_topo1.csv > ./results-new/vazao_x_vnfs_topo1.csv
mv conns_x_vnfs_topo1.csv ./results-new
