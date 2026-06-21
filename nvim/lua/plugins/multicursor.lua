-- Multicursor support https://github.com/jake-stewart/multicursor.nvim
-- Keybindings based on IntelliJ multicursor behaviour: https://www.jetbrains.com/help/idea/multicursor.html
return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  event = "VeryLazy",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    -- Alt+Shift+Click to add/remove cursor (IntelliJ: Alt+Shift+Click)
    -- Note: terminal emulators may intercept Alt+click; try <A-LeftMouse> if this doesn't work
    vim.keymap.set("n", "<M-S-LeftMouse>", mc.handleMouse, { desc = "Add/remove cursor at click" })

    -- Select next/previous occurrence (IntelliJ Mac: Ctrl+G / Ctrl+Shift+G)
    vim.keymap.set({ "n", "v" }, "<C-g>", function() mc.matchAddCursor(1) end, { desc = "Add cursor at next match" })

    -- Deselect last added match (IntelliJ Mac: Ctrl+Shift+G)
    -- Note: this removes the last cursor, it does NOT add a cursor at the previous match
    vim.keymap.set({ "n", "v" }, "<C-S-g>", function() mc.deleteCursor() end, { desc = "Deselect last match" })

    -- Select all occurrences (IntelliJ Linux: Ctrl+Alt+Shift+J / Mac: Cmd+Ctrl+G)
    vim.keymap.set({ "n", "v" }, "<C-A-g>", function() mc.matchAllAddCursors() end, { desc = "Select all occurrences" })

    -- Skip next/previous occurrence without adding cursor (IntelliJ: F3 / Shift+F3)
    vim.keymap.set({ "n", "v" }, "<F3>", function() mc.matchSkipCursor(1) end, { desc = "Skip to next occurrence" })
    vim.keymap.set({ "n", "v" }, "<S-F3>", function() mc.matchSkipCursor(-1) end, { desc = "Skip to previous occurrence" })

    -- Add cursor above/below (IntelliJ: Ctrl×2 + Up/Down)
    vim.keymap.set({ "n", "v" }, "<M-S-Up>", function() mc.lineAddCursor(-1) end, { desc = "Add cursor above" })
    vim.keymap.set({ "n", "v" }, "<M-S-Down>", function() mc.lineAddCursor(1) end, { desc = "Add cursor below" })

    -- Esc to clear all cursors (IntelliJ: Esc)
    vim.keymap.set("n", "<Esc>", function()
      if not mc.cursorsEnabled() then
        mc.enableCursors()
      elseif mc.hasCursors() then
        mc.clearCursors()
      else
        vim.cmd("nohlsearch")
      end
    end)

    -- No equivalent for "add cursors to line ends" (IntelliJ: Alt+Shift+G)
    -- Use Neovim's native Visual Block instead: Ctrl+V to select lines, then $ then A to edit line ends
  end,
}
