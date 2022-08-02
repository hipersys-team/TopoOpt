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

When running large scale experiments, this process should be automated. [This repository](https://github.com/chughtapan/clopt-tests) has a program that does the automation. In this document, we record each component's responsibility for the user to reconstruct the script.

### `ip route` and `arp`
Together, `iproute2` and `arp` are used to **specify a packet's next hop when the host is the source of the packet**. `ip route add <destination IP> dev <intended interface>` is used to specify which outgoing interface the packet should use, and `arp -s <destination IP> <next hop MAC> -i <intended interface>` is used to add a static ARP entry for the outgoing packet, to ensure it arrives the correct destination logical interface. Recall that when the packet should be forwarded, the next hop MAC needs to be the interface with RDMA disabled. 

### `tc`
`tc` or traffic control commands are used for the **forwarded packets**, i.e. they are the rule specifying how the intermediate hosts should behave. Each RDMA-disabled interface should have a tc ingress filter, added by the command 

`tc qdisc add dev <device name> ingress`

The rules are responsible for two things: rewrite the destination MAC to the next hop's MAC, and mirror the packet to the correct packet. We pipeline `tc flower` fliter with `tc pedit` packet edit, and finally `tc mirred` to achieve the desired functionality. Note that the destination MAC rewrite follows the rule mentioned above: if the next hop is the final destination of the packet, the new MAC address should be of the RDMA-enabled interface. Otherwise, it should be the MAC of the RDMA-disabled interface to allow the next host's kernel to capture the packet. 

Finally, a tc filter needs to be added for both regular ethernet traffic and VLAN enabled traffic for RDMA priority. Example (this is the script on the iraj machine of MIT cluster):

```
#!/bin/bash

tc qdisc del dev pp1eth parent ffff: >/dev/null 2>&1
tc qdisc add dev pp1eth ingress
tc qdisc del dev pp2eth parent ffff: >/dev/null 2>&1
tc qdisc add dev pp2eth ingress
tc qdisc del dev pp3eth parent ffff: >/dev/null 2>&1
tc qdisc add dev pp3eth ingress
tc qdisc del dev pp4eth parent ffff: >/dev/null 2>&1
tc qdisc add dev pp4eth ingress
tc filter add dev pp2eth prio 0 protocol 802.1Q parent ffff: flower skip_hw vlan_ethtype ip dst_ip 10.100.7.0/24 action pedit ex munge eth dst set 14:02:ec:ca:a8:cb pipe action mirred egress redirect dev pp3rdma
tc filter add dev pp3eth prio 0 protocol 802.1Q parent ffff: flower skip_hw vlan_ethtype ip dst_ip 10.100.3.0/24 action pedit ex munge eth dst set 34:80:0d:bc:3d:d4 pipe action mirred egress redirect dev pp2rdma
tc filter add dev pp3eth prio 0 protocol ip parent ffff: flower skip_hw  dst_ip 10.100.9.0/24 action pedit ex munge eth dst set 34:80:0d:bc:3c:4d pipe action mirred egress redirect dev pp4rdma
tc filter add dev pp3eth prio 0 protocol ip parent ffff: flower skip_hw  dst_ip 10.100.1.0/24 action pedit ex munge eth dst set 14:02:ec:ca:e8:8b pipe action mirred egress redirect dev pp1rdma
tc filter add dev pp2eth prio 0 protocol ip parent ffff: flower skip_hw  dst_ip 10.100.7.0/24 action pedit ex munge eth dst set 14:02:ec:ca:a8:cb pipe action mirred egress redirect dev pp3rdma
tc filter add dev pp1eth prio 0 protocol ip parent ffff: flower skip_hw  dst_ip 10.100.7.0/24 action pedit ex munge eth dst set 14:02:ec:ca:a8:cb pipe action mirred egress redirect dev pp3rdma
tc filter add dev pp4eth prio 0 protocol 802.1Q parent ffff: flower skip_hw vlan_ethtype ip dst_ip 10.100.7.0/24 action pedit ex munge eth dst set 14:02:ec:ca:a8:cb pipe action mirred egress redirect dev pp3rdma
tc filter add dev pp3eth prio 0 protocol 802.1Q parent ffff: flower skip_hw vlan_ethtype ip dst_ip 10.100.4.0/24 action pedit ex munge eth dst set 34:80:0d:bc:3c:51 pipe action mirred egress redirect dev pp4rdma
tc filter add dev pp3eth prio 0 protocol 802.1Q parent ffff: flower skip_hw vlan_ethtype ip dst_ip 10.100.1.0/24 action pedit ex munge eth dst set 14:02:ec:ca:e8:8b pipe action mirred egress redirect dev pp1rdma
tc filter add dev pp2eth prio 0 protocol 802.1Q parent ffff: flower skip_hw vlan_ethtype ip dst_ip 10.100.6.0/24 action pedit ex munge eth dst set 14:02:ec:ca:a8:cf pipe action mirred egress redirect dev pp3rdma
tc filter add dev pp2eth prio 0 protocol ip parent ffff: flower skip_hw  dst_ip 10.100.6.0/24 action pedit ex munge eth dst set 14:02:ec:ca:a8:cf pipe action mirred egress redirect dev pp3rdma
tc filter add dev pp1eth prio 0 protocol 802.1Q parent ffff: flower skip_hw vlan_ethtype ip dst_ip 10.100.7.0/24 action pedit ex munge eth dst set 14:02:ec:ca:a8:cb pipe action mirred egress redirect dev pp3rdma
tc filter add dev pp4eth prio 0 protocol ip parent ffff: flower skip_hw  dst_ip 10.100.7.0/24 action pedit ex munge eth dst set 14:02:ec:ca:a8:cb pipe action mirred egress redirect dev pp3rdma
tc filter add dev pp3eth prio 0 protocol ip parent ffff: flower skip_hw  dst_ip 10.100.4.0/24 action pedit ex munge eth dst set 34:80:0d:bc:3c:51 pipe action mirred egress redirect dev pp4rdma
tc filter add dev pp3eth prio 0 protocol ip parent ffff: flower skip_hw  dst_ip 10.100.3.0/24 action pedit ex munge eth dst set 34:80:0d:bc:3d:d4 pipe action mirred egress redirect dev pp2rdma
tc filter add dev pp3eth prio 0 protocol 802.1Q parent ffff: flower skip_hw vlan_ethtype ip dst_ip 10.100.9.0/24 action pedit ex munge eth dst set 34:80:0d:bc:3c:4d pipe action mirred egress redirect dev pp4rdma
arp -d 10.100.0.1 > /dev/null 2>&1
ip r d 10.100.0.1/32 > /dev/null 2>&1
arp -s 10.100.0.1 14:02:ec:ca:e8:8f -i pp1rdma
ip r a 10.100.0.1/32 src 10.100.8.1 dev pp1rdma
arp -d 10.100.1.4 > /dev/null 2>&1
ip r d 10.100.1.4/32 > /dev/null 2>&1
arp -s 10.100.1.4 14:02:ec:ca:e8:8b -i pp1rdma
ip r a 10.100.1.4/32 src 10.100.8.1 dev pp1rdma
arp -d 10.100.2.4 > /dev/null 2>&1
ip r d 10.100.2.4/32 > /dev/null 2>&1
arp -s 10.100.2.4 34:80:0d:bc:3c:51 -i pp4rdma
ip r a 10.100.2.4/32 src 10.100.8.4 dev pp4rdma
arp -d 10.100.3.3 > /dev/null 2>&1
ip r d 10.100.3.3/32 > /dev/null 2>&1
arp -s 10.100.3.3 34:80:0d:bc:3d:d4 -i pp2rdma
ip r a 10.100.3.3/32 src 10.100.8.2 dev pp2rdma
arp -d 10.100.4.3 > /dev/null 2>&1
ip r d 10.100.4.3/32 > /dev/null 2>&1
arp -s 10.100.4.3 34:80:0d:bc:3c:51 -i pp4rdma
ip r a 10.100.4.3/32 src 10.100.8.4 dev pp4rdma
arp -d 10.100.5.4 > /dev/null 2>&1
ip r d 10.100.5.4/32 > /dev/null 2>&1
arp -s 10.100.5.4 34:80:0d:bc:3c:51 -i pp4rdma
ip r a 10.100.5.4/32 src 10.100.8.4 dev pp4rdma
arp -d 10.100.6.3 > /dev/null 2>&1
ip r d 10.100.6.3/32 > /dev/null 2>&1
arp -s 10.100.6.3 14:02:ec:ca:a8:cf -i pp3rdma
ip r a 10.100.6.3/32 src 10.100.8.3 dev pp3rdma
arp -d 10.100.7.4 > /dev/null 2>&1
ip r d 10.100.7.4/32 > /dev/null 2>&1
arp -s 10.100.7.4 14:02:ec:ca:a8:cb -i pp3rdma
ip r a 10.100.7.4/32 src 10.100.8.3 dev pp3rdma
arp -d 10.100.9.3 > /dev/null 2>&1
ip r d 10.100.9.3/32 > /dev/null 2>&1
arp -s 10.100.9.3 34:80:0d:bc:3c:4d -i pp4rdma
ip r a 10.100.9.3/32 src 10.100.8.4 dev pp4rdma
arp -d 10.100.10.3 > /dev/null 2>&1
ip r d 10.100.10.3/32 > /dev/null 2>&1
arp -s 10.100.10.3 34:80:0d:bc:3c:51 -i pp4rdma
ip r a 10.100.10.3/32 src 10.100.8.4 dev pp4rdma
arp -d 10.100.11.1 > /dev/null 2>&1
ip r d 10.100.11.1/32 > /dev/null 2>&1
arp -s 10.100.11.1 14:02:ec:ca:e8:8f -i pp1rdma
ip r a 10.100.11.1/32 src 10.100.8.1 dev pp1rdma
```

## Step 3: install the hacked NCCL 

For this step please check the [google doc](https://drive.google.com/drive/u/1/folders/17hUXEw-yzuOWhvvnoD-NRfl77d6kKbyI). If another topology was set, the hacked NCCL will require some source code change, which is detailed in the documentation above. Another implementaion based on MSCCL which generate arbitrary schedule for collective communication can also be used on the RDMA-forwarding enabled topology.

## Step 4: run the testbed programs!