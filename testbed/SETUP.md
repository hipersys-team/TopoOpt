# Testbed setup guideline

TopoOpt requires RDMA forwarding to function properly on the 12-node testbed at MIT. In this document we provide detailed guidelines on how to set RDMA forwarding up. For more information about each step, check [this document](https://docs.google.com/document/d/190nelkTXo7fEQNWRe4rnMglzAvV1jj-ZyShMcAGZH08/edit). 

## Step 1: setup HPE nics in NPAR mode

To run RDMA forwarding, we split each interface on our HPE 620SFP28 NIC into two, one with RDMA enabled and the other disabled. This requiers some change in the NVM of the NIC. 

Download QLogic's firmware tool at [here](https://drive.google.com/drive/u/1/folders/17hUXEw-yzuOWhvvnoD-NRfl77d6kKbyI). Unzip the firmware.tar.gz file and find qlediag. cd into qlediag_8.60.22.0 and compile the program by running `make`.

From here, you can modify the NVM of the NIC by with the command 

`sudo load.sh -eng`

A list of NICs currently on the system will be listed. Moein has provided a configuration script that does all the job to set up the forwarding, select the correct and run the script (also in the previous drive folder):

`source breakout_NPAR.cfg`

Reboot the machine, now you should see two logical interfaces per physical interface. The first four interfaces has RDMA enabled, the rest does not.

## Step 2: Setup RDMA forwarding rules

RDMA forwarding is completed by a set of `iproute2`, `tc` and `arp` modifications. In a nutshell, we setup forwarding and static ARP rules such that when a packet should be forwarded, it is sent to the RDMA-disabled interface on the intermediate host; on the other hand, if the packet is at its last hop, its delivered to the RDMA-enabled interface. 

In large scale, this process should be automated. [This repository](https://github.com/chughtapan/clopt-tests) has a program that does the automation. In this document, we record each component's responsibility fot the user to reconstruct the script.

