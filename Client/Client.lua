module(..., package.seeall)

local config = require("core.config")

local function show_usage(code)
	print(require("program.MultiDimSnabb.Client.README_inc"))
	main.exit(code)
end

function run(args)
	if #args ~= 3 then show_usage(1) end
	local c = config.new()
	print("Got to Client")

	engine.config(c)
	engine.main({report = {showlinks = true}})
end
