local wezterm = require("wezterm")
local key_map = require("keymaps")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config = {
	leader = { key = "a", mods = "CTRL", timeout_milliseconds = 10000 },

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

	keys = key_map,
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
				File = os.getenv("HOME") .. "/.config/wezterm/dark-desert.jpg",
			},
			hsb = {
				hue = 1.0,
				saturation = 1.02,
				brightness = 0.25,
			},
			attachment = { Parallax = 0.3 },
			width = "100%",
			height = "100%",
			opacity = 0.80,
		},

		{
			source = {
				Color = "#282c35",
			},
			width = "100%",
			height = "100%",
			opacity = 0.60,
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
