#!/bin/bash

export file='vcpu-2'


export cliente='10.1.0.7'
export servidor='10.1.0.10'
export vnf='10.1.0.6'

export porta=20000

export bw=200M


echo Killing processes on server...
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} killall -9 -1 httperf -2 iperf -3 python

echo Killing processes on client...
killall -9 -1 httperf -2 iperf -3 python

echo Starting sockets on server...
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} screen -dmS httperfs "python -m SimpleHTTPServer ${porta}"
sleep 2
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} screen -dmS iperf "iperf -su -p ${porta}"
sleep 2

for i in {1..8}; do

sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${vnf} killall -9 python
sleep 3
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${vnf} screen -dmS vxlan "python /root/vxlan_tool-cores.py -i ens3 -d forward -c $i -v off"
sleep 10

# httperf
echo Starting httperf...
sleep 3
for j in {1..20}; do
   if [ $j -lt 20 ]; then
      httperf --server ${servidor} --port ${porta} --num-conns=3000 -v 2> /dev/null | grep 'Connection rate' | awk '{print $3;}' | tr '\n' ',' >> conns_${file}.csv
   else
      httperf --server ${servidor} --port ${porta} --num-conns=3000 -v 2> /dev/null | grep 'Connection rate' | awk '{print $3;}' >> conns_${file}.csv
   fi
   echo httperf $j/20
   sleep 5
done

#nc-latency
echo Starting nc latency...
for j in {1..100}; do
   if [ $j -lt 100 ]; then
      { time nc -zw 5 ${servidor} ${porta}; } |& grep real | awk '{print $2;}' | tr '\n' ',' >> rtt_${file}.csv
   else
      { time nc -zw 5 ${servidor} ${porta}; } |& grep real | awk '{print $2;}' >> rtt_${file}.csv
   fi
   if [ $(($j % 10)) -eq 0 ]; then
      echo nc $j/100
   fi
   sleep 1
done


# iperf
echo Starting iperf...
for j in {1..50}; do
   if [ $j -lt 50 ]; then
      iperf -c ${servidor} -p ${porta} -b ${bw} -u -l 1334 | grep '%)' | awk '{print $7;}' | tr '\n' ',' >> vazao_${file}.csv
   else
      iperf -c ${servidor} -p ${porta} -b ${bw} -u -l 1334 | grep '%)' | awk '{print $7;}' >> vazao_${file}.csv
   fi
   echo iperf $j/50
   sleep 3
done

done

sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} killall -9 python
sshpass -p "opnfv" ssh -o StrictHostKeyChecking=no root@${servidor} killall -9 iperf


mkdir results-new

sed -re 's/s|0m//g' rtt_${file}.csv > ./results-new/rtt_${file}.csv
rm rtt_${file}.csv

mv vazao_${file}.csv ./results-new

mv conns_${file}.csv ./results-new
