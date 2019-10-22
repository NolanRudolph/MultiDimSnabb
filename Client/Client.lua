module(..., package.seeall)

-- Config and utility requirements
local config     = require("core.config")
local lib        = require("core.lib")

-- App association requirements
local app        = require("core.app")
local link       = require("core.link")
local Intel82599 = require("apps.intel_mp.intel_mp").Intel82599

-- Packet creation requirements
local packet     = require("core.packet")
local datagram   = require("lib.protocol.datagram")
local ethernet   = require("lib.protocol.ethernet")
local ipv4       = require("lib.protocol.ipv4")
local _udp       = require("lib.protocol.udp")

-- C function requirements
local ffi = require("ffi")
local C = ffi.c

-- Temp req
local raw_sock = require("apps.socket.raw")

Generator = {}

function Generator:new(args)
	local src_eth = args["src_eth"]
	local dst_eth = args["dst_eth"]

	local ether = ethernet:new(
	{
		src = ethernet:pton(src_eth),
		dst = ethernet:pton(dst_eth),
		type = 0x800
	})

	local ip = ipv4:new(
	{
		ihl = 0x4500,
		dscp = 1,
		ttl = 255,
		protocol = 17
	})

	local udp = _udp:new(
	{
		src_port = 123,
		dst_port = 456
	})

	local dgram = datagram:new()
	dgram:push(udp)
	dgram:push(ip)
	dgram:push(ether)

	local fin_packet = dgram:packet()

	local o = { packet = fin_packet }
	-- local o = { packet = ffi.gc(ffi.C.malloc(fin_packet.length), ffi.C.free) }

	-- ffi.copy(o.packet, fin_packet, fin_packet.length)

	return setmetatable(o, {__index = Generator})
end

function Generator:pull()
	link.transmit(self.output.output, self.packet)
end

function show_usage(code)
	print(require("program.MultiDimSnabb.Client.README_inc"))
	main.exit(code)
end

function run(args)
	if #args ~= 3 then show_usage(1) end
	local c = config.new()

	local src_eth  = args[1]
	local dst_eth  = args[2]
	local pci_addr = args[3]

--[[ Testing
	local RawSocket = raw_sock.RawSocket
	config.app(c, "socket", RawSocket, "enp6s0f0")
--]]

	config.app(c, "nic", Intel82599, 
	{
		pciaddr = pci_addr,
		macaddr = dst_eth,
		vmdq = true,
		--wait_for_link = false,
		mtu = 1500,
	})

	config.app(c, "generator", Generator, 
	{
		src_eth = src_eth,
		dst_eth = dst_eth
	})

	config.link(c, "generator.output -> nic.input")
	config.link(c, "nic.input -> nic.output")

	engine.configure(c)
	engine.main({report = {showlinks = true}, duration = 0.5})
end
