Usage: MultiDimSnabb Client <Dsts>

  Dsts: File Containing Destination MAC Addresses

Example:
  ./snabb MultiDimSnabb Client dsts.txt

dsts.txt:
  3   <-- Number of Nodes to Send to
  00:09:08:07:00:04   <-- Client Node MAC Address
  00:09:08:07:06:05   <-- Server Node MAC Address
  vlan192             <-- Interface Name
  00:04:03:02:01:00   <-- Client Node MAC Address
  00:09:03:08:04:07   <-- Server Node MAC Address
  eth0                <-- Interface Name
  00:09:03:08:04:07   <-- Client Node MAC Address
  00:04:03:02:01:00   <-- Server Node MAC Address
  eth1                <-- Interface Name
