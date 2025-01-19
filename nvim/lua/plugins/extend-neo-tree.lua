return {
  "neo-tree.nvim",
  opts = function(_, opts)
    opts.window.mappings["P"] = { "toggle_preview", config = { use_float = true } }
    -- This was supposed to open preview by default...
    opts.event_handler = {
      {
        event = "after_render",
        handler = function()
          local state = require("neo-tree.sources.manager").get_state("filesystem")
          if not require("neo-tree.sources.common.preview").is_active() then
            state.config = { use_float = true } -- or whatever your config is
            state.commands.toggle_preview(state)
          end
        end,
      },
    }
  end,
}
