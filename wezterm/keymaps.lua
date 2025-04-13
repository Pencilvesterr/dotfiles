local wezterm = require("wezterm")

-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
	-- this is set by the plugin, and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
	LeftArrow = "Left",
	RightArrow = "Right",
	DownArrow = "Down",
	UpArrow = "Up",
}

-- For moving between splits while in neovim
local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				-- pass the keys through to vim/nvim
				win:perform_action({
					SendKey = { key = key, mods = "CTRL" },
				}, pane)
			else
				-- Run the wezterm action on the terminal panes
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

key_map = {
	-- Ctrl + vim direction -> Move focus
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	-- Ctrl + arrow -> Resize pane
	split_nav("resize", "LeftArrow"),
	split_nav("resize", "DownArrow"),
	split_nav("resize", "UpArrow"),
	split_nav("resize", "RightArrow"),

	-- Close when just using terminal windows
	{
		mods = "LEADER",
		key = "d",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},

	-- Shortcut for opening a temrinal window
	{
		mods = "CTRL",
		key = "/",
		action = wezterm.action_callback(function(window, pane)
			if is_vim(pane) then
				-- If terminal tab is already open, then close
				local tab = window:active_tab()
				local panes = tab:panes()
				wezterm.log_info("Panes info", panes)
				for _, current_pane in ipairs(panes) do
					if not is_vim(current_pane) then
						current_pane:activate()
						window:perform_action(wezterm.action.CloseCurrentPane({ confirm = true }), pane)
						return
					end
				end
				pane:split({ direction = "Bottom", size = 0.2 })
			else
				window:perform_action(wezterm.action.CloseCurrentPane({ confirm = true }), pane)
			end
		end),
	},
	{
		mods = "LEADER",
		key = "v",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		mods = "LEADER",
		key = "s",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	-- Maximise current pane
	{
		mods = "LEADER",
		key = "m",
		action = wezterm.action.TogglePaneZoomState,
	},
	-- rotate panes
	{
		mods = "LEADER",
		key = "Space",
		action = wezterm.action.RotatePanes("Clockwise"),
	},
	-- show the pane selection mode, but have it swap the active and selected panes
	{
		mods = "LEADER",
		key = "x",
		action = wezterm.action.PaneSelect({
			mode = "SwapWithActive",
		}),
	},

	-- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
	{ key = "LeftArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bb" }) },

	-- Make Option-Right equivalent to Alt-f; forward-word
	{ key = "RightArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bf" }) },

	-- Add Command + Backspace to delete the whole line
	{
		key = "Backspace",
		mods = "CMD",
		action = wezterm.action({ SendKey = { mods = "CTRL", key = "u" } }),
	},

	-- Add Option + Backspace to delete a word
	{
		key = "Backspace",
		mods = "OPT",
		action = wezterm.action({ SendKey = { mods = "CTRL", key = "w" } }),
	},
	-- Select next tab with cmd-opt-left/right arrow
	{
		key = "LeftArrow",
		mods = "CMD|OPT",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		key = "RightArrow",
		mods = "CMD|OPT",
		action = wezterm.action.ActivateTabRelative(1),
	},
	-- Select next pane with cmd-left/right arrow
	{
		key = "LeftArrow",
		mods = "CMD",
		action = wezterm.action({ ActivatePaneDirection = "Prev" }),
	},
	{
		key = "RightArrow",
		mods = "CMD",
		action = wezterm.action({ ActivatePaneDirection = "Next" }),
	},
	-- on cmd-s, send esc, then ':w<enter>'. This makes cmd-s trigger a save action in neovim
	{
		key = "s",
		mods = "CMD",
		action = wezterm.action({ SendString = "\x1b:w\n" }),
	},

	-- Font Zoom
	{
		key = "+",
		mods = "CMD",
		action = wezterm.action.IncreaseFontSize,
	},
	{
		key = "-",
		mods = "CMD",
		action = wezterm.action.DecreaseFontSize,
	},
	-- Add copy and paste as normal. TODO: Could look into using the built in like above
	require("command_keys").bind_super_key_to_vim("x"),
	require("command_keys").bind_super_key_to_vim("c"),
}

return key_map
