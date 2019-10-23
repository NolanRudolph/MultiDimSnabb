#!/bin/bash

ARGC=$#

# Argument Validation
if [ $ARGC -ne 12 ]; then
	echo "Use as $ ./$0 [C1] [P1] [M1] [C2] [P2] [M2] [C3] [P3] [M3] [S1] [P4] [M4]"
	echo "C#: The SSH Address of Client Node \#"
	echo "S#: The SSH Address of Server Node \#"
	echo "P#: The PCI Address of Client/Server Node \#"
	echo "M#: The Source MAC Address of Client/Server Node \#"
fi

$C1=$1
$P1=$2
$C2=$3
$P2=$4
$C3=$5
$P3=$6
$S1=$7
$P4=$8

# Node Validation
if [ $(ssh $C1 echo Hello) ] && [ $(ssh $C2 echo Hello) ] &&
   [ $(ssh $C3 echo Hello) ] && [ $(ssh $S1 echo Hello) ]; then
	echo "Nodes appear to be functional."
else
	echo "Node are not accessible. Exiting."
	exit 1;
fi

# Cloning Multi Dim Snabb Repository
echo "Cloning the MultiDimSnabb Repository"
printf "Client 1: "; ssh $C1 "git clone https://github.com/NolanRudolph/MultiDimSnabb.git"
printf "Client 2: "; ssh $C2 "git clone https://github.com/NolanRudolph/MultiDimSnabb.git"
printf "Client 3: "; ssh $C3 "git clone https://github.com/NolanRudolph/MultiDimSnabb.git"
printf "Server 1: "; ssh $S1 "git clone https://github.com/NolanRudolph/MultiDimSnabb.git"

# Cloning Snabb Repository
echo "Cloning the Snabb Repository"
printf "Client 1: "; ssh $C1 "git clone https://github.com/snabbco/snabb.git"
printf "Client 2: "; ssh $C2 "git clone https://github.com/snabbco/snabb.git"
printf "Client 3: "; ssh $C3 "git clone https://github.com/snabbco/snabb.git"
printf "Server 1: "; ssh $S1 "git clone https://github.com/snabbco/snabb.git"

# Initializing Snabb
echo "Creating Snabb Executable & Linking MultiDimSnabb"
ssh $C1 "bash ~/MultiDimSnabb/automake.sh" &
ssh $C2 "bash ~/MultiDimSnabb/automake.sh" &
ssh $C3 "bash ~/MultiDimSnabb/automake.sh" &
ssh $S1 "bash ~/MultiDimSnabb/automake.sh" 

# Unbindings
echo "Unbinding NICs from PCI Addresses"
ssh $C1 "echo $P1 > /sys/bus/pci/drivers/ixgbe/unbind" &
ssh $C2 "echo $P2 > /sys/bus/pci/drivers/ixgbe/unbind" &
ssh $C3 "echo $P3 > /sys/bus/pci/drivers/ixgbe/unbind" &
ssh $S1 "echo $P4 > /sys/bus/pci/drivers/ixgbe/unbind" 

# Running
echo "Beginning 10 Second Test"
ssh $C1 "~/snabb/src/snabb MultiDimSnabb Client $M1 $M4 $P1" &
ssh $C2 "~/snabb/src/snabb MultiDimSnabb Client $M2 $M4 $P2" &
ssh $C3 "~/snabb/src/snabb MultiDimSnabb Client $M3 $M4 $P3" &
ssh $S1 "~/snabb/src/snabb MultiDimSnabb Server $P4" 
