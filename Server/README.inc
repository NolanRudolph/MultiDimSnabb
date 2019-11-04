Usage: MultiDimSnabb Client <IF> <Src> <Dsts>

  IF  : Network Interface
  Src : Source MAC Address
  Dsts: File Containing Destination MAC Addresses

Example:
  ./snabb MultiDimSnabb Client eth0 00:01:02:03:04:05 dsts.txt

dsts.txt:
  3   <-- Number of Nodes to Send to
  00:09:08:07:06:05   <-- First Node MAC Address
  00:04:03:02:01:00   <-- Second Node MAC Address
  00:09:03:08:04:07   <-- Third Node MAC Address
