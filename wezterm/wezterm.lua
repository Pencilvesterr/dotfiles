local wezterm = require("wezterm")
local config = require("config")
require("events")

-- Apply color scheme based on the WEZTERM_THEME environment variable
local themes = {
	nord = "Nord (Gogh)",
	onedark = "One Dark (Gogh)",
}
local selected_theme = os.getenv("WEZTERM_THEME") or "nord"
config.color_scheme = themes[selected_theme]

return config
