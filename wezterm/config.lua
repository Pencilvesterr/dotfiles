local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
	-- this is set by the plugin, and unset on ExitPre in Neovim
	return pane:get_user_vars().IS_NVIM == "true"
end

-- TODO: Seperate these into it's own file
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

config = {

	default_cursor_style = "SteadyBar",
	automatically_reload_config = true,
	window_close_confirmation = "NeverPrompt",
	hide_tab_bar_if_only_one_tab = true,
	macos_window_background_blur = 35,
	-- Tab management
	tab_bar_at_bottom = false, -- Make it look like tabs, with better GUI controls
	-- Don't let any individual tab name take too much room
	tab_max_width = 50,
	colors = {
		tab_bar = {
			active_tab = {
				-- I use a solarized dark theme; this gives a teal background to the active tab
				fg_color = "#073642",
				bg_color = "#2aa198",
			},
		},
	},
	-- Switch to the last active tab when I close a tab
	switch_to_last_active_tab_when_closing_tab = true,

	-- Exit code behaviour
	exit_behavior = "Hold",
	exit_behavior_messaging = "Brief",
	adjust_window_size_when_changing_font_size = false,
	enable_tab_bar = true,
	use_fancy_tab_bar = true,
	window_decorations = "TITLE | RESIZE",
	check_for_updates = false,
	font_size = 12.5,
	font = wezterm.font("JetBrains Mono", { weight = "Bold" }),
	window_padding = {
		left = 10,
		right = 10,
		top = 0,
		bottom = 0,
	},
	leader = { key = "a", mods = "CTRL", timeout_milliseconds = 10000 },

	keys = {
		split_nav("move", "h"),
		split_nav("move", "j"),
		split_nav("move", "k"),
		split_nav("move", "l"),
		-- resize panes
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
		-- Add copy and paste as normal. TODO: Could look into using the built in like above
		require("command_keys").bind_super_key_to_vim("x"),
		require("command_keys").bind_super_key_to_vim("c"),
	},
	mouse_bindings = {
		{
			event = { Down = { streak = 1, button = "Left" } },
			mods = "CMD|ALT",
			action = wezterm.action.SelectTextAtMouseCursor("Block"),
			alt_screen = "Any",
		},
		{
			event = { Down = { streak = 4, button = "Left" } },
			action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
			mods = "NONE",
		},
		-- Make right click used for both copy and paste
		{
			event = { Down = { streak = 1, button = "Right" } },
			mods = "NONE",
			action = wezterm.action_callback(function(window, pane)
				local has_selection = window:get_selection_text_for_pane(pane) ~= ""
				if has_selection then
					window:perform_action(wezterm.action.CopyTo("ClipboardAndPrimarySelection"), pane)
					window:perform_action(wezterm.action.ClearSelection, pane)
				else
					window:perform_action(wezterm.action({ PasteFrom = "Clipboard" }), pane)
				end
			end),
		},
	},
	background = {
		{
			source = {
				File = "/Users/" .. os.getenv("USER") .. "/.config/wezterm/dark-desert.jpg",
			},
			hsb = {
				hue = 1.0,
				saturation = 1.02,
				brightness = 0.25,
			},
			attachment = { Parallax = 0.3 },
			width = "100%",
			height = "100%",
			opacity = 0.90,
		},

		{
			source = {
				Color = "#282c35",
			},
			width = "100%",
			height = "100%",
			opacity = 0.55,
		},
	},
	-- from: https://akos.ma/blog/adopting-wezterm/
	hyperlink_rules = {
		-- Matches: a URL in parens: (URL)
		{
			regex = "\\((\\w+://\\S+)\\)",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in brackets: [URL]
		{
			regex = "\\[(\\w+://\\S+)\\]",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in curly braces: {URL}
		{
			regex = "\\{(\\w+://\\S+)\\}",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in angle brackets: <URL>
		{
			regex = "<(\\w+://\\S+)>",
			format = "$1",
			highlight = 1,
		},
		-- Then handle URLs not wrapped in brackets
		{
			-- Before
			--regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
			--format = '$0',
			-- After
			regex = "[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)",
			format = "$1",
			highlight = 1,
		},
		-- implicit mailto link
		{
			regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
			format = "mailto:$0",
		},
	},
}
return config
