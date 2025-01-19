return {
  "pocco81/auto-save.nvim",
  opts = {
    -- Stop having a message on autosave
    execution_message = {
      message = function()
        return ""
      end,
      dim = 0.18,
      cleaning_interval = 1250,
    },
  },
  keys = {
    {
      "<leader>bs",
      ":ASToggle<CR>",
      desc = "Toggle Autosave",
    },
  },
}
