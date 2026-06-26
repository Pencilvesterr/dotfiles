-- Force out of bad vim habits
return {
  "m4xshen/hardtime.nvim",
  lazy = false,
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    restriction_mode = "hint",
  },
}
