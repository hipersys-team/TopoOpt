#!/bin/bash

netopt=1
igbw=200
gdbw=256
nlat=1
local_b=64
biggpu=4
declare -a deg=(4 8)
declare -a bwarr=(10 25 40 100 200)
declare -a runid=(0 1 2 3 4)
declare -a nnodes=(128)
declare -a topologies=("topoopt" "random")


for d in "${deg[@]}"; do
  for b in "${bwarr[@]}"; do
    for rid in "${runid[@]}"; do
      for n in "${nnodes[@]}"; do
        for topo in "${topologies[@]}"; do
          globalb=$((n*local_b*biggpu))
          mfile="$FF_HOME/measures/vgg128.json"
          resultdir="a100_vgg_${topo}_${n}_${b}_${d}_${nlat}_${local_b}_${rid}"
          $FF_HOME/build/Release/examples/cpp/vgg16sim/vggsim -ll:gpu 1 -ll:cpu 1 -ll:zsize 20000 -ll:fsize 10000 -ll:util 4 --batch-size ${globalb} --interface-bandwidth $b --inter-gpu-bandwidth $igbw --gpu-dram-bandwidth $gdbw --network-latency $nlat --net-opt $netopt --nsimnode $n --search-budget 4000 --mfile $mfile  --enable-propagation --node-degree $d --taskgraph taskgraph_$SLURM_ARRAY_TASK_ID.fbuf --simulator-workspace-size 65536 --topology $topo --big-gpu $biggpu
          mkdir $resultdir
          mv taskgraph.fbuf $resultdir/taskgraph.fbuf
          bash -c "cd $resultdir && $FF_HOME/ffsim-opera/src/clos/datacenter/htsim_tcp_flat -simtime 3600.1 -flowfile ./taskgraph.fbuf -speed $((b*1000)) -ofile nwsim.txt -nodes $n -ssthresh 10000 -rtt 1000 -q 50000"
        done
      done
    done
  done
done

