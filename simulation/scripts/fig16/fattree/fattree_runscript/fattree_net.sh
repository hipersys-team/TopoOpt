#!/bin/bash

#SBATCH --array=0-199
#SBATCH -o net-%a.log
#SBATCH -c 24

netopt=1
igbw=200
gdbw=256
nlat=1
local_b=0
topo="fattree"
declare -a deg=(1)
declare -a bwarr=(100 200 400 800)
declare -a runid=(10 11 12 13 14 15 16 17 18 19)
declare -a nnodes=(432)
declare -a njobs=(5 10 15 20 27)

source /etc/profile

trial=${SLURM_ARRAY_TASK_ID}
d=${deg[$(( trial % ${#deg[@]} ))]}
trial=$(( trial / ${#deg[@]} ))
b=${bwarr[$(( trial % ${#bwarr[@]} ))]}
trial=$(( trial / ${#bwarr[@]} ))
rid=${runid[$(( trial % ${#runid[@]} ))]}
trial=$(( trial / ${#runid[@]} ))
n=${nnodes[$(( trial % ${#nnodes[@]} ))]}
trial=$(( trial / ${#nnodes[@]} ))
nj=${njobs[$(( trial % ${#njobs[@]} ))]}
trial=$(( trial / ${#njobs[@]} ))

jobsstr=`python3 sample_jobs.py $b 16 $nj`

resultdir="a100_mixed_${topo}_${n}_${b}_${d}_${nlat}_${local_b}_${nj}_${rid}"
#bash -c "cd $resultdir && $HOME/FlexFlow/ffsim-opera/src/clos/datacenter/htsim_tcp_fattree -simtime 3600.1 -flowfile ./taskgraph.fbuf -speed $((b*1000)) -ofile nwsim_linkft.txt -nodes 432 -ssthresh 10000 -rttnet 1000 -rttrack 1000 -q 10000"
mkdir $resultdir
bash -c "cd $resultdir && $HOME/FlexFlow/ffsim-opera/src/clos/datacenter/htsim_tcp_fattree_multijob -simtime 3600.1 -flowfiles $jobsstr -speed $((b*1000)) -ofile nwsim_linkft.txt -nodes $n -ssthresh 10000 -rttnet 1000 -rttrack 1000 -q 50000"
mv net-${SLURM_ARRAY_TASK_ID}.log $resultdir
