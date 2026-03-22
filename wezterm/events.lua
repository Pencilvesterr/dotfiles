local wezterm = require("wezterm")
local mux = wezterm.mux

-- Background override for SSH/mux panes. Swaps the default dark overlay (#282c35) for a
-- warm reddish-brown tint over the same wallpaper, making remote windows visually distinct
-- without changing the terminal color scheme or font rendering.
local SSH_BACKGROUND = {
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
      Color = "#2c2418",  -- muted dark orange, similar intensity to the default #282c35
    },
    width = "100%",
    height = "100%",
    opacity = 0.60,
  },
}

-- Process name → nerd font icon mapping
local PROCESS_ICONS = {
  nvim    = wezterm.nerdfonts.custom_vim,
  vim     = wezterm.nerdfonts.custom_vim,
  zsh     = wezterm.nerdfonts.dev_terminal,
  bash    = wezterm.nerdfonts.dev_terminal,
  fish    = wezterm.nerdfonts.dev_terminal,
  ssh     = wezterm.nerdfonts.md_server_network,
  git     = wezterm.nerdfonts.dev_git,
  python  = wezterm.nerdfonts.dev_python,
  python3 = wezterm.nerdfonts.dev_python,
  node    = wezterm.nerdfonts.dev_nodejs_small,
  docker  = wezterm.nerdfonts.dev_docker,
  lua     = wezterm.nerdfonts.seti_lua,
  lazygit = wezterm.nerdfonts.dev_git,
  htop    = wezterm.nerdfonts.md_chart_line,
  btop    = wezterm.nerdfonts.md_chart_line,
}

local function get_process_icon(pane)
  local proc = pane.foreground_process_name or ""
  local name = proc:match("([^/\\]+)$") or ""
  return PROCESS_ICONS[name:lower()] or wezterm.nerdfonts.md_console_line
end

-- Powerline separators (requires a nerd font or WezTerm's built-in symbol font)
local LEFT_ARROW  = wezterm.nerdfonts.pl_right_hard_divider  --
local RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider   --

wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
  local pane   = tab.active_pane
  local domain = pane.domain_name
  local icon   = get_process_icon(pane)
  local index  = tab.tab_index + 1

  -- Build the visible title
  local title = pane.title
  if domain ~= "local" then
    title = string.format("[%s] %s", domain, title)
  end

  -- Truncate if needed (leave room for index, icon, separators, spaces)
  local overhead = #tostring(index) + 5  -- " N: I title "
  local budget   = max_width - overhead
  if #title > budget then
    title = title:sub(1, budget - 1) .. "…"
  end

  local label  = string.format(" %d: %s %s ", index, icon, title)
  local is_active = tab.is_active

  local bg      = is_active and "#88C0D0" or "#2E3440"
  local fg      = is_active and "#2E3440" or "#6B7A8D"
  local edge_bg = "#1a1e26"

  return wezterm.format({
    { Attribute = { Intensity = is_active and "Bold" or "Normal" } },
    -- Left powerline arrow
    { Background = { Color = edge_bg } },
    { Foreground = { Color = bg } },
    { Text = LEFT_ARROW },
    -- Tab label
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = label },
    -- Right powerline arrow
    { Background = { Color = edge_bg } },
    { Foreground = { Color = bg } },
    { Text = RIGHT_ARROW },
  })
end)

-- Prefix the window title with the SSH domain name when the active pane is remote,
-- so the host is visible in the OS window title and the dock/taskbar.
wezterm.on("format-window-title", function(tab)
  local pane = tab.active_pane
  local domain = pane.domain_name

  if domain ~= "local" then
    return string.format("[%s] %s", domain, pane.title)
  end

  return pane.title
end)

-- Show mux latency in the right status bar when the remote pane is slow to respond.
-- "Tardy" means the mux server hasn't replied within the expected window, which typically
-- indicates lag on an SSH or remote mux connection. The elapsed time is shown so you can
-- tell at a glance how long the pane has been unresponsive. The status is cleared when
-- the connection is healthy.
--
-- Also overrides the window background when the active pane is remote, giving an
-- immediate whole-window visual cue that you're working on a non-local machine.
-- Derive leader hints directly from the keymap definitions so they stay in sync.
-- Any keymap entry with mods = "LEADER" and a description field is included.
local LEADER_HINTS = (function()
  local hints = {}
  for _, map in ipairs(require("keymaps")) do
    if map.mods == "LEADER" and map.description then
      local display_key = map.key == "Space" and "SPC" or map.key
      table.insert(hints, { display_key, map.description })
    end
  end
  return hints
end)()

local function leader_status()
  local parts = {
    { Attribute = { Intensity = "Bold" } },
    { Foreground = { Color = "#ECEFF4" } },
    { Background = { Color = "#5E81AC" } },
    { Text = " LEADER " },
    { Foreground = { Color = "#D8DEE9" } },
    { Background = { Color = "#2E3440" } },
    { Text = " " },
  }
  for i, hint in ipairs(LEADER_HINTS) do
    table.insert(parts, { Foreground = { Color = "#EBCB8B" } })
    table.insert(parts, { Background = { Color = "#2E3440" } })
    table.insert(parts, { Text = hint[1] })
    table.insert(parts, { Foreground = { Color = "#D8DEE9" } })
    table.insert(parts, { Text = ":" .. hint[2] })
    if i < #LEADER_HINTS then
      table.insert(parts, { Foreground = { Color = "#4C566A" } })
      table.insert(parts, { Text = "  " })
    end
  end
  table.insert(parts, { Text = " " })
  return wezterm.format(parts)
end

wezterm.on("update-status", function(window, pane)
  -- Both get_metadata() and get_domain_name() can fail during mux connection
  -- before the pane is registered — bail out early and wait for the next tick.
  local ok, meta = pcall(function() return pane:get_metadata() end)
  if not ok then return end
  meta = meta or {}

  local ok2, domain = pcall(function() return pane:get_domain_name() end)
  if not ok2 then return end

  local overrides = window:get_config_overrides() or {}

  local leader_active = window:leader_is_active()

  -- Only call set_config_overrides when the background actually needs to change,
  -- to avoid a read-modify-write race that wipes transient overrides (e.g. the
  -- flash_selection colors set by CMD+C) on every status tick.
  local new_bg = domain ~= "local" and SSH_BACKGROUND or nil
  if overrides.background ~= new_bg then
    overrides.background = new_bg
    window:set_config_overrides(overrides)
  end

  if meta.is_tardy then
    local secs = meta.since_last_response_ms / 1000.0
    window:set_right_status(string.format("tardy: %5.1fs⏳", secs))
  else
    window:set_right_status("")
  end

  if leader_active then
    window:set_left_status(leader_status())
  else
    window:set_left_status("")
  end
end)

wezterm.on("gui-startup", function()
  local _, _, window = mux.spawn_window({})
  -- window:gui_window():maximize()
end)

-- wezterm.on("window-resized", function(window, pane)
-- 	readjust_font_size(window, pane)
-- end)

-- Readjust font size on window resize to get rid of the padding at the bottom
function readjust_font_size(window, pane)
  local window_dims = window:get_dimensions()
  local pane_dims = pane:get_dimensions()

  local config_overrides = {}
  local initial_font_size = 13 -- Set to your desired font size
  config_overrides.font_size = initial_font_size

  local max_iterations = 5
  local iteration_count = 0
  local tolerance = 3

  -- Calculate the initial difference between window and pane heights
  local current_diff = window_dims.pixel_height - pane_dims.pixel_height
  local min_diff = math.abs(current_diff)
  local best_font_size = initial_font_size

  -- Loop to adjust font size until the difference is within tolerance or max iterations reached
  while current_diff > tolerance and iteration_count < max_iterations do
    -- wezterm.log_info(window_dims, pane_dims, config_overrides.font_size)
    wezterm.log_info(
      string.format(
        "Win Height: %d, Pane Height: %d, Height Diff: %d, Curr Font Size: %.2f, Cells: %d, Cell Height: %.2f",
        window_dims.pixel_height,
        pane_dims.pixel_height,
        window_dims.pixel_height - pane_dims.pixel_height,
        config_overrides.font_size,
        pane_dims.viewport_rows,
        pane_dims.pixel_height / pane_dims.viewport_rows
      )
    )

    -- Increment the font size slightly
    config_overrides.font_size = config_overrides.font_size + 0.5
    window:set_config_overrides(config_overrides)

    -- Update dimensions after changing font size
    window_dims = window:get_dimensions()
    pane_dims = pane:get_dimensions()
    current_diff = window_dims.pixel_height - pane_dims.pixel_height

    -- Check if the current difference is the smallest seen so far
    local abs_diff = math.abs(current_diff)
    if abs_diff < min_diff then
      min_diff = abs_diff
      best_font_size = config_overrides.font_size
    end

    iteration_count = iteration_count + 1
  end

  -- If no acceptable difference was found, set the font size to the best one encountered
  if current_diff > tolerance then
    config_overrides.font_size = best_font_size
    window:set_config_overrides(config_overrides)
  end
end
