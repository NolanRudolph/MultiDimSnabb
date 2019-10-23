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


Recorder = {}

function Recorder:new(args)
	local o = {}
	return setmetatable(o, {__index = Recorder})
end

function Recorder:push()
	local i = self.input.input
	while not link.empty(i) do
		self:record_packet(i)
	end
end

function Recorder:record_packet(i)
	local p = link.receive(i)

	local dgram = datagram:new(p, ethernet)
	dgram:parse_n(3)
	
	local eth, ip, udp = unpack(dgram:stack())

	print("Eth source is: " .. ethernet:ntop(eth:src()))

	packet.free(p)
end


function show_usage(code)
	print(require("program.MultiDimSnabb.Server.README_inc"))
	main.exit(code)
end

function run(args)
	if #args ~= 1 then show_usage(1) end
	local c = config.new()

	local pci_addr = args[1]

	config.app(c, "nic", Intel82599, 
	{
		pciaddr = pci_addr
	})

	config.app(c, "recorder", Recorder)

	config.link(c, "nic.output -> recorder.input")
	
	engine.busywait = true
	engine.configure(c)
	engine.main({report = {showlinks = true, showapps = true}, duration = 10})
end
