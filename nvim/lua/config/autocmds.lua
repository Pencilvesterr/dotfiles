-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Autosave when leaving the current buffer
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "VimLeavePre" }, {
  group = vim.api.nvim_create_augroup("mcrouch:" .. "autosave", {}),
  callback = function(event)
    -- Check if the old buffer has been changed
    if vim.bo[event.buf].modified then
      vim.schedule(function()
        vim.api.nvim_buf_call(event.buf, function()
          -- Save the buffer
          vim.cmd("silent! write")
        end)
      end)
    end
  end,
})
