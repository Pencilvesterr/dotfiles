-- Update the dashboard have S select session rather than the last one
return {
  "snacks.nvim",
  opts = function(_, opts)
    if not vim.g.vscode then
      table.insert(
        opts.dashboard.preset.keys,
        7,
        { icon = "S", key = "S", desc = "Select Session", action = require("persistence").select }
      )
    end
  end,
}
