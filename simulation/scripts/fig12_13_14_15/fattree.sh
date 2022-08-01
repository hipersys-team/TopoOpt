#!/bin/bash

FF_HOME=${HOME}/FlexFlow
netopt=1
igbw=200
gdbw=256
nlat=1
local_b=128
topo="fattree"
biggpu=4
declare -a deg=(1)
declare -a bwarr=(10 25 40 80 100 160 200 320 400 800 1600)
declare -a runid=(0 1 2 3 4)
declare -a nnodes=(128)

for d in "${deg[@]}"; do
  for b in "${bwarr[@]}"; do
    for rid in "${runid[@]}"; do
      for n in "${nnodes[@]}"; do
        globalb=$((n*local_b*biggpu))
        mfile="$FF_HOME/measures/dlrm128.json"
        resultdir="a100_dlrm_${topo}_${n}_${b}_${d}_${nlat}_${local_b}_${rid}"
        $FF_HOME/build/Release/examples/cpp/DLRMsim/dlrmsim -ll:gpu 1 -ll:cpu 1 -ll:zsize 20000 -ll:fsize 10000 -ll:util 4 -dm:memoize --embedding-bag-size 100 --arch-sparse-feature-size 128 --arch-embedding-size 10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000-10000000 --arch-mlp-bot 2048-2048-2048-2048-2048-2048-2048-2048 --arch-mlp-top 4096-4096-4096-4096-4096-4096-4096-4096-4096-4096-4096-4096-4096-4096-4096-4096-1  --batch-size ${globalb} --interface-bandwidth $b --inter-gpu-bandwidth $igbw --gpu-dram-bandwidth $gdbw --network-latency $nlat --net-opt $netopt --nsimnode $n --search-budget 4000 --mfile $mfile  --enable-propagation --node-degree $d --taskgraph taskgraph.fbuf --simulator-workspace-size 65536 --big-gpu $biggpu
        mkdir $resultdir
        mv taskgraph.fbuf $resultdir/taskgraph.fbuf
        bash -c "cd $resultdir && $FF_HOME/ffsim-opera/src/clos/datacenter/htsim_tcp_fattree -simtime 3600.1 -flowfile ./taskgraph.fbuf -speed $((b*1000)) -ofile nwsim_linkft.txt -nodes $n -ssthresh 10000 -rttnet 1000 -rttrack 1000 -q 10000"
        bash -c "cd $resultdir && $FF_HOME/ffsim-opera/src/clos/datacenter/htsim_tcp_abssw -simtime 3600.1 -flowfile ./taskgraph.fbuf -speed $((b*1000)) -ofile nwsim_abssw.txt -nodes $n -ssthresh 10000 -rtt 1000 -q 60000"
      done
    done
  done
done
