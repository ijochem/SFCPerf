#!/bin/bash

servidor='10.240.114.46'
cliente='10.240.114.48'

for j in {1..10}; do
   echo Epoch $j/10

   echo Killing processes on server...
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} killall -1 httperf -2 iperf -3 python
   echo Killing processes on client...
   sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${cliente} killall -1 httperf -2 iperf -3 python
   chain=''

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

      # iperf
      echo Starting iperf on chain $i ...
      echo sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} screen -dmS iperf${i} "iperf -s -i 1 -p $(($i+20000))"
      sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} screen -dmS iperf${i} "iperf -s -i 1 -p $(($i+20000))"
      sleep 5
      if [ $i -lt 11 ]; then
         sshpass -p "opnfv" ssh root@${cliente} "iperf -c 10.10.0.5 -p $(($i+20000)) -t 10 | grep 0.0-" | awk '{print $7}' | tr '\n' ',' >> vazao_x_vnfs_topo1.csv
      else
         sshpass -p "opnfv" ssh root@${cliente} "iperf -c 10.10.0.5 -p $(($i+20000)) -t 10 | grep 0.0-" | awk '{printf("%s,%s\n",$7,$8);}' >> vazao_x_vnfs_topo1.csv
      fi
      echo Epoch 1: iperf chain-$i
      chain="${chain},"
   done

   echo 'Deleting all SFC and Classifiers...'
   ./delete-sanz.sh
   sleep 10
done

sed -re 's/,Mbits\/sec//g' vazao_x_vnfs_topo1.csv > ./results-new/vazao_x_vnfs_topo1.csv
