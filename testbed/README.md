# TopoOpt Testbed

This submodule contains source code used for TopoOpt's testbed evaluation. The experiments are completed at MIT, on the 12-node ASUS ESC4000-E10A machines, each equiped with a 32 Core CPU, 256 GB of DRAM and an NVIDIA A100 40G GPU. For networking, each machine is equiped with a 4x25Gbps HPE 620QSFP28 NIC connected to a Telescent NTM G4 patch panel, and a Mellanox ConnectX5 100Gbps NIC connected to a Juniper MX480 switch.

## Structure
| Directory | Description |
|-----------|-------------|
| `dlrm_torch`    | Meta's implementation of DLRM with model parallel training. Used to generate Figure 19 (DLRM column) and 21 in the paper. |
| `topoopt_ff_testbed` | Modified FlexFlow to run on MIT's textbed. Used to generate Figure 19. |
| `imagenet_training` | Training imagenet with data, adapted from trioML. Used to generate Figure 20 in the paper. |

## Testbed setup

In order to run the testbed programs, RDMA forwarding needs to be set up, and a modified version of NCCL need to be installed. A detailed documentation can be found [in this document](https://docs.google.com/document/d/190nelkTXo7fEQNWRe4rnMglzAvV1jj-ZyShMcAGZH08/edit). Please contact weiyangw@mit.edu to requiest access. 