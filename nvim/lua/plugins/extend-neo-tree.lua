-- I've tried to have neo-tree open when starting a new session. Doesn't seem so easy
-- https://www.reddit.com/r/neovim/comments/1bmy37q/how_does_lazyvim_configure_neotree_to_open_on/
return {
  "neo-tree.nvim",
  opts = function(_, opts)
    opts.window.mappings["P"] = { "toggle_preview", config = { use_float = true } }

    opts.sources = { "filesystem", "buffers", "git_status", "diagnostics" }
    opts.source_selector = {
      winbar = true, -- Toggle to show selector on winbar
      content_layout = "center",
      tabs_layout = "equal",
      show_separator_on_edge = true,
      sources = {
        { source = "filesystem", display_name = "󰉓" },
        { source = "buffers", display_name = "󰈙" },
        { source = "git_status", display_name = "" },
        { source = "diagnostics", display_name = "󰒡" },
      },
    }

    -- This was supposed to open preview by default...
  end,
}
