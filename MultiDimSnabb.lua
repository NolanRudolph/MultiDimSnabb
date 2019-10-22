module(..., package.seeall)

local engine = require("core.app")
local pci = require("lib.hardware.pci")
local lib = require("core.lib")
local Intel82599 = require("apps.intel_mp.intel_mp").Intel82599

local function show_usage(exit_code)
	print(require("program.MultiDimSnabb.README_inc"))
	main.exit(exit_code)
end

function run(args)
	if #args == 0 then show_usage(1) end
	local node_type = table.remove(args, 1)
	local modname = ("program.MultiDimSnabb.%s.%s"):format(node_type, node_type)
	if not lib.have_module(modname) then
		show_usage(1)
	end
	require(modname).run(args)
end
