local wezterm = require("wezterm")

local function is_vim(pane)
	local process_name = string.gsub(pane:get_foreground_process_name(), "(.*[/\\])(.*)", "%2")
	return process_name == "nvim" or process_name == "vim"
end

local super_vim_keys_map = {
	x = utf8.char(0xAB), -- Using 0xAB for CMD+X
	c = utf8.char(0xAC), -- Using 0xAC for CMD+C
}

local function bind_super_key_to_vim(key)
	return {
		key = key,
		mods = "CMD",
		action = wezterm.action_callback(function(win, pane)
			local char = super_vim_keys_map[key]
			if char and is_vim(pane) then
				win:perform_action({
					SendKey = { key = char, mods = nil },
				}, pane)
			else
				win:perform_action({
					SendKey = { key = key, mods = "CMD" },
				}, pane)
			end
		end),
	}
end

return { bind_super_key_to_vim = bind_super_key_to_vim }
