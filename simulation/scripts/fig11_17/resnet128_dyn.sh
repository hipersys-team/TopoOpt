#!/bin/bash

FF_HOME=${HOME}/FlexFlow
netopt=1
igbw=200
gdbw=256
nlat=1
local_b=128
declare -a deg=(4 8)
declare -a bwarr=(100)
declare -a runid=(0 1 2 3 4)
declare -a nnodes=(128)
declare -a srp=(1 5 20 100 1000 10000)

# Note: run this file after all fattree taskgraphs are generated!
source ./compile_to_sipml.sh
topo="sipml"

for d in "${deg[@]}"; do
  for b in "${bwarr[@]}"; do
    for rid in "${runid[@]}"; do
      for n in "${nnodes[@]}"; do
        for topo in "${topologies[@]}"; do
          for s in "${srp[@]}"; do
            tgdir="a100_resnet_fattree_${n}_$((d*b))_1_${nlat}_${local_b}_${rid}"
            resultdir="a100_resnet_${topo}${s}_${n}_${b}_${d}_${nlat}_${local_b}_${rid}"
            bash -c "mkdir -p $resultdir && cd $resultdir && $FF_HOME/ffsim-opera/src/clos/datacenter/htsim_tcp_dyn_flat -simtime 3600.1 -flowfile ../$tgdir/taskgraph.fbuf -speed $((b*1000)) -deg $d -rdelay $s -omethod dheu -ofile nwsim.txt -nodes $n -ssthresh 50 -rtt 1000 -q 500"
          done
        done
      done
    done
  done
done

source ./compile_to_ocs.sh
topo="ocsreconfig"

for d in "${deg[@]}"; do
  for b in "${bwarr[@]}"; do
    for rid in "${runid[@]}"; do
      for n in "${nnodes[@]}"; do
        for topo in "${topologies[@]}"; do
          for s in "${srp[@]}"; do
            tgdir="a100_resnet_fattree_${n}_$((d*b))_1_${nlat}_${local_b}_${rid}"
            resultdir="a100_resnet_${topo}${s}_${n}_${b}_${d}_${nlat}_${local_b}_${rid}"
            bash -c "mkdir -p $resultdir && cd $resultdir && $FF_HOME/ffsim-opera/src/clos/datacenter/htsim_tcp_dyn_flat -simtime 3600.1 -flowfile ../$tgdir/taskgraph.fbuf -speed $((b*1000)) -deg $d -rdelay $s -omethod dheu -ofile nwsim.txt -nodes $n -ssthresh 50 -rtt 1000 -q 500"
          done
        done
      done
    done
  done
done
