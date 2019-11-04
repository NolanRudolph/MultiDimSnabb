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

Generator = {}

function Generator:new(args)
	--[[ Node Stuff ]]--
	dst_file = args["dst_file"]
	local f = io.open(dst_file, "r")
	io.input(f)

	-- Check to see if file exists
	if f == nil then
		print("File does not exist.")
		main.exit(1)
	end

	local num_nodes = tonumber(io.read())

	local dst_eths = {}
	local last_eths = {}
	for i = 1, num_nodes do
		local rec = io.read()
		table.insert(dst_eths, ethernet:pton(rec))
		last_eths[rec] = 0
		net_eths[rec] = 0
	end

	--[[ Packet Stuff ]]--
	local src_eth = args["src_eth"]

	local ether = ethernet:new(
	{
		src = ethernet:pton(src_eth),
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
		num_nodes = num_nodes,
		cur_node = 1,
		last_eths = last_eths,
		wait = 0
	}

	return setmetatable(o, {__index = Generator})
end

function Generator:gen_packet()
	local addr = self.nodes[self.cur_node]
	print("Pinging Node " .. tostring(self.cur_node) .. " | Addr: " .. ethernet:ntop(addr))

	self.eth:dst(addr)
	self.dgram = datagram:new()
	self.dgram:push(self.udp)
	self.dgram:push(self.ip)
	self.dgram:push(self.eth)

	self.last_eths[ethernet:ntop(addr)] = os.clock()
	link.transmit(self.output.output, self.dgram:packet())
	
	if self.cur_node == self.num_nodes then
		self.cur_node = 1
	else
		self.cur_node = self.cur_node + 1
	end
	
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

		local dgram = datagram:new(p, ethernet)
		dgram:parse_n(3)

		local eth, _, _ = unpack(dgram:stack())
		local eth_src = tostring(ethernet:ntop(eth:src()))

		if net_eths[eth_src] then
			-- Get the net time the request took
			local net = temp_time - self.last_eths[eth_src]
			-- Take the average of the recorded times
			if net_eths[eth_src] ~= 0 then
				net_eths[eth_src] = (net_eths[eth_src] + net) / 2
			else
				net_eths[eth_src] = net
			end
		end

		packet.free(p)
end
end

function show_usage(code)
	print(require("program.MultiDimSnabb.Server.README_inc"))
	main.exit(code)
end

function run(args)
	x = os.clock()
	if #args ~= 3 then show_usage(1) end
	local c = config.new()

	local IF       = args[1]
	local src_eth  = args[2]
	local dst_file = args[3]

	config.app(c, "generator", Generator, 
	{
		src_eth = src_eth,
		dst_file = dst_file
	})

	local RawSocket = raw_sock.RawSocket
	config.app(c, "server", RawSocket, IF)

	config.link(c, "generator.output -> server.rx")
	config.link(c, "server.tx -> generator.input")

	engine.busywait = true
	engine.configure(c)
	engine.main({duration = 10})
	
	local low = 100
	local low_i = 0
	local i = 0
	for _, v in pairs(net_eths) do
		print("Node " .. tostring(i) .. " : " .. tostring(v))
		if v < low then
			low = v
			low_i = i
		end
		i = i + 1
	end

	local ms_low = low * 1000
	print(string.format("Best Connection: Node %d at %.2f ms", low_i, ms_low))
end
