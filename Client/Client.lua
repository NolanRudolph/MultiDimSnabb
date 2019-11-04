module(..., package.seeall)

-- Config and utility requirements
local config     = require("core.config")
local lib        = require("core.lib")

-- App association requirements
local app        = require("core.app")
local link       = require("core.link")
local Intel82599 = require("apps.intel_mp.intel_mp").Intel82599
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


Incubator = {}

dataset = {}

function Incubator:new(args)
	local src_eth = args["src_eth"]
        local dst_eth = args["dst_eth"]

        local o =
	{
		src_eth = src_eth,
		dst_eth = dst_eth
	}

	return setmetatable(o, {__index = Incubator})
end

function Incubator:pull()
	assert(self.output.output, "Could not locate output port.")
	assert(self.input.input, "Could not locate input port.")
	local i = self.input.input
	local o = self.output.output
	while not link.empty(i) do
		--local p = link.receive(i)
		--link.transmit(o, packet.clone(p))
		return_packet(i, o, self.src_eth, self.dst_eth)
	end
end

function return_packet(i, o, src, dst)
	local p = link.receive(i)

	local dgram = datagram:new(p, ethernet)
	dgram:parse_n(3)
	
	local eth, ip, udp = unpack(dgram:stack())
	
	-- Check to make sure packet is from host
	local rec_src = tostring(ethernet:ntop(eth:src()))
	local rec_dst = tostring(ethernet:ntop(eth:dst()))
	if rec_dst ~= src or rec_src ~= dst then
		return
	end
	print("Received packet from server.")
--[[ For server
	local src = tostring(ethernet:ntop(eth:src()))

	if dataset[src] then
		dataset[src] = dataset[src] + 1
	else
		dataset[src] = 1
	end
	
	packet.free(p)
	__________________________
	for k, v in pairs(dataset) do
		print(k .. " : " .. tostring(v))
	end
--]]

	-- Change Ethernet src and dst (dst just becomes src)
	eth:swap()

	local ret_gram = dgram:new()
	ret_gram:push(udp)
	ret_gram:push(ip)
	ret_gram:push(eth)

	print("Transmitting back to server.")
	-- Transmit packet back to server
	link.transmit(o, packet.clone(dgram:packet()))

	return
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
	local IF       = args[3]

	local RawSocket = raw_sock.RawSocket
	config.app(c, "socket", RawSocket, IF)

	config.app(c, "incubator", Incubator, 
	{
		src_eth = src_eth,
		dst_eth = dst_eth
	})

	config.link(c, "socket.tx -> incubator.input")
	config.link(c, "incubator.output -> socket.rx")

	engine.busywait = true
	engine.configure(c)
	engine.main({report = {showlinks = true}})
	
end
