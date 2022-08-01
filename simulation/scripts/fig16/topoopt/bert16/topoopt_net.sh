#!/bin/bash

#SBATCH --array=0-49
#SBATCH -o net-%a.log
#SBATCH -c 24

netopt=1
igbw=200
gdbw=256
nlat=1
local_b=16
topo="topoopt"
declare -a deg=(4 8)
declare -a bwarr=(10 25 40 100 200)
declare -a runid=(0 1 2 3 4)
declare -a nnodes=(16)

source /etc/profile

trial=${SLURM_ARRAY_TASK_ID}
d=${deg[$(( trial % ${#deg[@]} ))]}
trial=$(( trial / ${#deg[@]} ))
b=${bwarr[$(( trial % ${#bwarr[@]} ))]}
trial=$(( trial / ${#bwarr[@]} ))
rid=${runid[$(( trial % ${#runid[@]} ))]}
trial=$(( trial / ${#bwarr[@]} ))
n=${nnodes[$(( trial % ${#nnodes[@]} ))]}

resultdir="a100_transformer_${topo}_${n}_${b}_${d}_${nlat}_${local_b}_${rid}"
bash -c "cd $resultdir && $HOME/FlexFlow/ffsim-opera/src/clos/datacenter/htsim_tcp_flat -simtime 3600.1 -q 50000 -flowfile ./taskgraph.fbuf -speed $((b*1000)) -ofile nwsim.txt -nodes $n -ssthresh 10000 -rtt 1000"
mv net-${SLURM_ARRAY_TASK_ID}.log $resultdir
