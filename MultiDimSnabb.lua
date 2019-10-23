module(..., package.seeall)

local lib = require("core.lib")

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
