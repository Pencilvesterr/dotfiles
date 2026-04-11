-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.opt.timeoutlen = 0 -- Show which-key popup immediately

-- Options for edgy.nvim
-- views can only be fully collapsed with the global statusline
vim.opt.laststatus = 2 -- Show a status line below every split
-- Default splitting will cause your main splits to jump when opening an edgebar.
-- To prevent this, set `splitkeep` to either `screen` or `topline`.
vim.opt.splitkeep = "screen"

-- Use OSC 52 clipboard (WezTerm supports this natively, including via mux domains)
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    -- Paste falls back to unnamed register; OSC 52 paste requires terminal support
    ["+"] = function() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end,
    ["*"] = function() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end,
  },
}
