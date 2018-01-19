#!/bin/bash

cliente_node_2='10.240.114.34'
cliente_node_8='10.240.114.37'
servidor_node_2='10.240.114.30'
servidor_node_4='10.240.114.50'
servidor_node_8='10.240.114.35'

chain=''
echo Killing processes on server...
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_2} killall -1 httperf -2 iperf -3 python
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_4} killall -1 httperf -2 iperf -3 python
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_8} killall -1 httperf -2 iperf -3 python
echo Killing processes on client...
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${cliente_node_2} killall -1 httperf -2 iperf -3 python
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${cliente_node_8} killall -1 httperf -2 iperf -3 python

for i in {1..11}; do
   chain="${chain}gta-vnf-${i}"
   echo Creating chain $i ...
   echo tacker sfc-create  --name gta-c${i} --chain ${chain}
   tacker sfc-create  --name gta-c${i} --chain ${chain}
   echo tacker sfc-classifier-create --name c${i}_tcp_$(($i+20000)) --chain gta-c${i} --match source_port=0,dest_port=$(($i+20000)),protocol=6
   tacker sfc-classifier-create --name c${i}_tcp_$(($i+20000)) --chain gta-c${i} --match source_port=0,dest_port=$(($i+20000)),protocol=6
   sleep 30

# httperf
   echo Starting httperf on chain $i ...
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_8} screen -dmS http$chain "python -m SimpleHTTPServer $(($i+20000))"
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_4} screen -dmS http$chain "python -m SimpleHTTPServer $(($i+20000))"
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_2} screen -dmS http$chain "python -m SimpleHTTPServer $(($i+20000))"

# TOPOLOGIA 1
   for j in {1..10}; do
      if [ $j -lt 10 ]; then
         sshpass -p "opnfv" ssh root@${cliente_node_8} "httperf --server 10.1.0.11 --port $(($i+20000)) --num-conns=3000 -v 2> /dev/null | grep 'Connection rate'" | awk '{print $3;}' | tr '\n' ',' >> conns_x_vnfs_topo1.csv
         sshpass -p "opnfv" ssh root@${cliente_node_2} "httperf --server 10.1.0.16 --port $(($i+20000)) --num-conns=3000 -v 2> /dev/null | grep 'Connection rate'" | awk '{print $3;}' | tr '\n' ',' >> conns_x_vnfs_topo2.csv
         sshpass -p "opnfv" ssh root@${cliente_node_2} "httperf --server 10.1.0.9 --port $(($i+20000)) --num-conns=3000 -v 2> /dev/null | grep 'Connection rate'" | awk '{print $3;}' | tr '\n' ',' >> conns_x_vnfs_topo3.csv
      else
         sshpass -p "opnfv" ssh root@${cliente_node_8} "httperf --server 10.1.0.11 --port $(($i+20000)) --num-conns=3000 -v 2> /dev/null | grep 'Connection rate'" | awk '{print $3;}' >> conns_x_vnfs_topo1.csv
         sshpass -p "opnfv" ssh root@${cliente_node_2} "httperf --server 10.1.0.16 --port $(($i+20000)) --num-conns=3000 -v 2> /dev/null | grep 'Connection rate'" | awk '{print $3;}' >> conns_x_vnfs_topo2.csv
         sshpass -p "opnfv" ssh root@${cliente_node_2} "httperf --server 10.1.0.9 --port $(($i+20000)) --num-conns=3000 -v 2> /dev/null | grep 'Connection rate'" | awk '{print $3;}' >> conns_x_vnfs_topo3.csv
      fi
      echo chain-$i httperf $j/10
      sleep 5
   done

# nc-latency
   echo Starting nc-latency on chain $i ...
   for j in {1..100}; do
      if [ $j -lt 100 ]; then
         { sshpass -p "opnfv" ssh root@${cliente_node_8} "time nc -zw 5 10.1.0.11 $(($i+20000))"; } |& grep real | awk '{print $2;}' | tr '\n' ',' >> rtt_x_vnfs_topo1.csv
         { sshpass -p "opnfv" ssh root@${cliente_node_2} "time nc -zw 5 10.1.0.16 $(($i+20000))"; } |& grep real | awk '{print $2;}' | tr '\n' ',' >> rtt_x_vnfs_topo2.csv
         { sshpass -p "opnfv" ssh root@${cliente_node_2} "time nc -zw 5 10.1.0.9 $(($i+20000))"; } |& grep real | awk '{print $2;}' | tr '\n' ',' >> rtt_x_vnfs_topo3.csv
      else
         { sshpass -p "opnfv" ssh root@${cliente_node_8} "time nc -zw 5 10.1.0.11 $(($i+20000))"; } |& grep real | awk '{print $2;}' >> rtt_x_vnfs_topo1.csv
         { sshpass -p "opnfv" ssh root@${cliente_node_2} "time nc -zw 5 10.1.0.16 $(($i+20000))"; } |& grep real | awk '{print $2;}' >> rtt_x_vnfs_topo2.csv
         { sshpass -p "opnfv" ssh root@${cliente_node_2} "time nc -zw 5 10.1.0.9 $(($i+20000))"; } |& grep real | awk '{print $2;}' >> rtt_x_vnfs_topo3.csv
      fi
      if [ $(($j % 10)) -eq 0 ]; then
         echo chain-$i nc $j/100
      fi
      sleep 1
   done

   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_2} killall python
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_4} killall python
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_8} killall python

   echo tacker sfc-classifier-create --name c${i}_udp_$(($i+20000)) --chain gta-c${i} --match source_port=0,dest_port=$(($i+20000)),protocol=17
   tacker sfc-classifier-create --name c${i}_udp_$(($i+20000)) --chain gta-c${i} --match source_port=0,dest_port=$(($i+20000)),protocol=17

# iperf
   echo Starting iperf on chain $i ...
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_2} screen -dmS iperf${i} "iperf -su -p $(($i+20000))"
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_4} screen -dmS iperf${i} "iperf -su -p $(($i+20000))"
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_8} screen -dmS iperf${i} "iperf -su -p $(($i+20000))"
   sleep 5
   bw=100M
   for j in {1..10}; do
      if [ $j -lt 10 ]; then
         sshpass -p "opnfv" ssh root@${cliente_node_8} "iperf -c 10.1.0.11 -p $(($i+20000)) -b ${bw} -u -l 1334 | grep '%)'" | awk '{print $7;}' | tr '\n' ',' >> vazao_x_vnfs_topo1.csv
         sshpass -p "opnfv" ssh root@${cliente_node_2} "iperf -c 10.1.0.16 -p $(($i+20000)) -b ${bw} -u -l 1334 | grep '%)'" | awk '{print $7;}' | tr '\n' ',' >> vazao_x_vnfs_topo2.csv
         sshpass -p "opnfv" ssh root@${cliente_node_2} "iperf -c 10.1.0.9 -p $(($i+20000)) -b ${bw} -u -l 1334 | grep '%)'" | awk '{print $7;}' | tr '\n' ',' >> vazao_x_vnfs_topo3.csv
      else
         sshpass -p "opnfv" ssh root@${cliente_node_8} "iperf -c 10.1.0.11 -p $(($i+20000)) -b ${bw} -u -l 1334 | grep '%)'" | awk '{print $7;}' >> vazao_x_vnfs_topo1.csv
         sshpass -p "opnfv" ssh root@${cliente_node_2} "iperf -c 10.1.0.16 -p $(($i+20000)) -b ${bw} -u -l 1334 | grep '%)'" | awk '{print $7;}' >> vazao_x_vnfs_topo2.csv
         sshpass -p "opnfv" ssh root@${cliente_node_2} "iperf -c 10.1.0.9 -p $(($i+20000)) -b ${bw} -u -l 1334 | grep '%)'" | awk '{print $7;}' >> vazao_x_vnfs_topo3.csv
      fi
      echo chain-$i iperf $j/10
      sleep 3
   done


   chain="${chain},"
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_2} killall iperf
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_4} killall iperf
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor_node_8} killall iperf

done

mkdir results-new
sed -re 's/s|0m//g' rtt_x_vnfs_topo1.csv > ./results-new/rtt_x_vnfs_topo1.csv
sed -re 's/s|0m//g' rtt_x_vnfs_topo2.csv > ./results-new/rtt_x_vnfs_topo2.csv
sed -re 's/s|0m//g' rtt_x_vnfs_topo3.csv > ./results-new/rtt_x_vnfs_topo3.csv

#sed -re 's/,Mbits\/sec//g' vazao_x_vnfs_topo1.csv > ./results-new/vazao_x_vnfs_topo1.csv
mv vazao_x_vnfs_topo1.csv ./results-new
mv vazao_x_vnfs_topo2.csv ./results-new
mv vazao_x_vnfs_topo3.csv ./results-new

mv conns_x_vnfs_topo1.csv ./results-new
mv conns_x_vnfs_topo2.csv ./results-new
mv conns_x_vnfs_topo3.csv ./results-new
