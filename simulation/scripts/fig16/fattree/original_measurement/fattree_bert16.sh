#!/bin/bash

#SBATCH --array=0-10
#SBATCH -o tranformer-a-%a.log
#SBATCH --gres=gpu:volta:1
#SBATCH -c 20

netopt=1
igbw=200
gdbw=256
nlat=1
local_b=16
biggpu=4
declare -a deg=(1)
declare -a bwarr=(10 25 40 80 100 160 200 320 400 800 1600)
declare -a runid=(0)
declare -a nnodes=(16)
declare -a topologies=("fattree")

source /etc/profile
module load cuda/11.3

trial=${SLURM_ARRAY_TASK_ID}
d=${deg[$(( trial % ${#deg[@]} ))]}
trial=$(( trial / ${#deg[@]} ))
b=${bwarr[$(( trial % ${#bwarr[@]} ))]}
trial=$(( trial / ${#bwarr[@]} ))
rid=${runid[$(( trial % ${#runid[@]} ))]}
trial=$(( trial / ${#bwarr[@]} ))
n=${nnodes[$(( trial % ${#nnodes[@]} ))]}
trial=$(( trial / ${#nnodes[@]} ))
topo=${topologies[$(( trial % ${#topologies[@]} ))]}

globalb=$((n*local_b*biggpu))
mfile="/home/gridsan/weiyangw/FlexFlow/measures/transformer16.json"
resultdir="a100_transformer_${topo}_${n}_${b}_${d}_${nlat}_${local_b}_${rid}"
/home/gridsan/weiyangw/FlexFlow/build/Release/examples/cpp/Transformersim/transformersim -ll:gpu 1 -ll:cpu 1 -ll:zsize 20000 -ll:fsize 10000 -ll:util 4 -dm:memoize --num-layers 6 --sequence-length 256 --hidden-size 768 --num-heads 12 --batch-size ${globalb} --interface-bandwidth $b --inter-gpu-bandwidth $igbw --gpu-dram-bandwidth $gdbw --network-latency $nlat --net-opt $netopt --nsimnode $n --search-budget 5000 --mfile $mfile --enable-propagation --node-degree $d --taskgraph taskgraph_$SLURM_ARRAY_TASK_ID.fbuf --simulator-workspace-size 65536 --topology $topo --big-gpu $biggpu
mkdir $resultdir
mv taskgraph_$SLURM_ARRAY_TASK_ID.fbuf $resultdir/taskgraph.fbuf
mv transformer-a-${SLURM_ARRAY_TASK_ID}.log $resultdir
