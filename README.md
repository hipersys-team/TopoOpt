# TopoOpt: Optimizing the Network Topology for Distributed DNN Training

## 1. Overview

TopoOpt is a novel DNN training system that co-optimizes the distributed training process across computation, communication, and network topology.

Training large-scale deep neural networks have become one of the predominant workloads in today's datacenter. Today's DNN training systems are built on top of traditional datacenter clusters, with electrical packet switches arranged in a multi-tier Fat-Tree topology. But Fat-Tree networks are becoming a bottleneck for distributed DNN training workloads.

In TopoOpt, we explore using reconfigurable optical interconnect to construct a flexible network fabric for future large-scale DNN training workload. Furthermore, we jointly optimize the network topology and the DNN parallelization strategy to maximize the training performance. 

Specifically, TopoOpt creates dedicated partitions for each training job within the cluster, and jointly optimizes the topology and parallelization strategy of the job. To achieve this goal, we grapple with the algorithmic challenges of finding the best topology, such as how to navigate the large search space across computation, communication, and topology dimensions, and also with various operational challenges, such as which optical switching technologies match well with the traffic patterns of various DNN models. 

For a full technical description on TopoOpt, please read our NSDI 2023 paper:
> W. Wang, M. Khazraee, Z. Zhong, Z. Jia$, D. Mudigere, Y. Zhang, A. Kewitsch, M. Ghobadi, "TopoOpt: Optimizing the Network Topology for Distributed DNN Training" NSDI 2023. https://arxiv.org/abs/2202.00433

This repository contains the necessary code base to generate the simuation and testbed result of TopoOpt. For code questions, please contact Weiyang Wang at weiyangw [at] mit.edu. We welcome contributions and feedbacks.

## 2. Repository Structure
| Folder                         | Description                                                      |
| -------------------------------|------------------------------------------------------------------|
| `simulation`                   | Source code necessary to generate the simulation result          | 
| `simulation/FlexNet`           | FlexNet simulator that implements the topology search algorithms |
| `simulation/FlexNetPacket`     | FlexNetPacket simulator for packet level simulation              |
| `testbed`                      | Soruce code necessary to generate the textbed result             |
| `testbed/dlrm_torch`           | Meta's implementation of DLRM on torch that runs model parallel  |
| `testbed/topoopt_ff_testbed`   | Modified Flexflow to generate TopoOpt's testbed result           |

Each submodule contains its own detained README file for file structure and programe usage. 

## 3. License
TopoOpt is licensed under Apache License 2.0.