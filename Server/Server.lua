module(..., package.seeall)

-- Config and utility requirements
local config     = require("core.config")
local lib        = require("core.lib")

-- App association requirements
local app        = require("core.app")
local link       = require("core.link")
local Intel82599 = require("apps.intel_mp.intel_mp").Intel82599
local LoadGen    = require("apps.intel_mp.loadgen").LoadGen
local raw_sock   = require("apps.socket.raw")

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

	local o = { packet = dgram:packet() }

	return setmetatable(o, {__index = Generator})
end

function Generator:pull()
	link.transmit(self.output.output, packet.clone(self.packet))
	os.execute("sleep " .. 2)
end

function Generator:stop()
	packet.free(self.packet)
end

function show_usage(code)
	print(require("program.MultiDimSnabb.Server.README_inc"))
	main.exit(code)
end

function run(args)
	if #args ~= 4 then show_usage(1) end
	local c = config.new()

	local pci_addr = args[1]
	local src_eth  = args[2]
	local dst_eth  = args[3]
	local IF       = args[4]

	config.app(c, "generator", Generator, 
	{
		src_eth = src_eth,
		dst_eth = dst_eth
	})

	local RawSocket = raw_sock.RawSocket
	config.app(c, "server", RawSocket, IF)

	config.link(c, "generator.output -> server.rx")

	engine.busywait = true
	engine.configure(c)
	engine.main({})
end
