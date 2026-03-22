local wezterm = require("wezterm")

local function is_vim(pane)
	local process_name = string.gsub(pane:get_foreground_process_name(), "(.*[/\\])(.*)", "%2")
	return process_name == "nvim" or process_name == "vim"
end

local super_vim_keys_map = {
	x = utf8.char(0xAB), -- Using 0xAB for CMD+X
	c = utf8.char(0xAC), -- Using 0xAC for CMD+C
}

local function flash_selection(win)
	local overrides = win:get_config_overrides() or {}
	overrides.colors = {
		selection_fg = "#282c35",
		selection_bg = "#a3be8c",
	}
	win:set_config_overrides(overrides)
	wezterm.time.call_after(0.15, function()
		local cur = win:get_config_overrides() or {}
		cur.colors = nil
		win:set_config_overrides(cur)
	end)
end

local non_vim_copy_action = wezterm.action_callback(function(win, pane)
	win:perform_action(wezterm.action.CopyTo("Clipboard"), pane)
	flash_selection(win)
end)

local non_vim_actions = {
	c = non_vim_copy_action,
	x = non_vim_copy_action,
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
				local action = non_vim_actions[key]
				if action then
					win:perform_action(action, pane)
				else
					win:perform_action({
						SendKey = { key = key, mods = "CMD" },
					}, pane)
				end
			end
		end),
	}
end

return { bind_super_key_to_vim = bind_super_key_to_vim }
