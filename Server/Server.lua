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

net_eths = {}
glob = {}
Generator = {}

function Generator:new(args)

	local src_eth = args["src_eth"]
	local dst_eth = args["dst_eth"]
	local name = args["name"]


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

	local o = 
	{ 
		eth = ether,
		ip = ip,
		udp = udp,
		dgram = datagram:new(),
		nodes = dst_eths,
		name = name,
		last_time = 0,
		wait = 0
	}

	return setmetatable(o, {__index = Generator})
end

function Generator:gen_packet()
	assert(self.output.output, "Could not locate output port.")
	print("Pinging Node " .. tostring(self.name) .. " | Addr: " .. ethernet:ntop(addr))

	self.dgram = datagram:new()
	self.dgram:push(self.udp)
	self.dgram:push(self.ip)
	self.dgram:push(self.eth)

	self.last_time = os.clock()
	link.transmit(self.output.output, self.dgram:packet())
	
	return
end

function Generator:pull()
	if self.wait ~= 100000 then
		self.wait = self.wait + 1
	else
		self:gen_packet()
		self.wait = 0
	end
end

function Generator:push()
	assert(self.input.input, "Could not locate input port.")
	local i = self.input.input
	while not link.empty(i) do
		print("Received packet.")
		local p = link.receive(i)
		local temp_time = os.clock()

		--[[
		local dgram = datagram:new(p, ethernet)
		dgram:parse_n(3)

		local eth, _, _ = unpack(dgram:stack())
		local eth_src = tostring(ethernet:ntop(eth:src()))
		--]]

		if (glob[self.name] == nil) then
			glob[self.name] = {}
			table.insert(glob[self.name], temp_time - self.last_time)
		else
			table.insert(glob[self.name], temp_time - self.last_time)
		end

		packet.free(p)
end
end

function show_usage(code)
	print(require("program.MultiDimSnabb.Server.README_inc"))
	main.exit(code)
end

function run(args)
	if #args ~= 1 then show_usage(1) end
	local c = config.new()

	local conf_file = args[1]

	local f = io.open(conf_file, "r")
	io.input(f)

	if f == nil then
		print("File does not exist.")
		main.exit(1)
	end

	src_eths = {}
	dst_eths = {}
	ifs = {}
	local num_nodes = tonumber(io.read())	

	for i = 1, num_nodes do
		local src = io.read()
		local dst = io.read()
		local IF = io.read()
		table.insert(src_eths, ethernet:pton(src))
		table.insert(dst_eths, ethernet:pton(dst))
		table.insert(ifs, IF)
	end

	config.app(c, "generator1", Generator, 
	{
		src_eth = src_eth[1],
		dst_eth = dst_eth[1],
		name = "Wisc HDD"
	})
	config.app(c, "generator2", Generator, 
	{
		src_eth = src_eth[2],
		dst_eth = dst_eth[2],
		name = "Wisc SSD"
	})
	config.app(c, "generator3", Generator,
	{
		src_eth = src_eth[3],
		dst_eth = dst_eth[3],
		name = "Clem HDD"
	})
	config.app(c, "generator4", Generator,
	{
		src_eth = src_eth[4],
		dst_eth = dst_eth[4],
		name = "Clem SSD"
	})

	local RawSocket1 = raw_sock.RawSocket
	local RawSocket2 = raw_sock.RawSocket
	local RawSocket3 = raw_sock.RawSocket
	local RawSocket4 = raw_sock.RawSocket

	config.app(c, "server1", RawSocket1, ifs[1])
	config.app(c, "server2", RawSocket2, ifs[2])
	config.app(c, "server3", RawSocket3, ifs[3])
	config.app(c, "server4", RawSocket4, ifs[4])

	config.link(c, "generator1.output -> server1.rx")
	config.link(c, "generator2.output -> server2.rx")
	config.link(c, "generator3.output -> server3.rx")
	config.link(c, "generator4.output -> server4.rx")

	config.link(c, "server1.tx -> generator1.input")
	config.link(c, "server2.tx -> generator2.input")
	config.link(c, "server3.tx -> generator3.input")
	config.link(c, "server4.tx -> generator4.input")

	x = os.clock()
	engine.busywait = true
	engine.configure(c)
	engine.main({duration = 10})
	
	for key, value in pairs(glob) do
		print("Key: " .. key)
		for time in value do
			print("Value: " .. time)
		end
		print("---------------------------------------")
	end

end
