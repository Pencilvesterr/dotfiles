# 💤 Morgan's LazyVim Config

## TODO

- Need to stop having enter select the suggestion
- Want to allow command + / to comment out a line
- With markdown, want to be able to see the ``` when having text blocks
- Follow the book guide to get rid of the top buffer suggestions
- Setup edge again for neo-tree
- Replace the `s` and `S` commands in `extend-snacks.lua`
- Turn off transperancy, seems to fuck with some stuff regaring colours
- Add key maps for <S-h> and <S-l> for going to the start/end of a line
- Get quick fix working for spelling mistakes
- Get <C-g> working to select a word and multi-cursor, just like intellij

## Low Piroitfy

- Get preview showing by default. Have tried:
- Figure out if it's possible to only show diagnostics for errors
- Rathern than having `s` be the session for the current dir, use:
- <https://github.com/linux-cultist/venv-selector.nvim> for selecting venvs automatically
- Look into setting debug configs [docs](https://github.com/harrisoncramer/harrisoncramer.me/blob/main/src/content/blog/debugging-in-neovim.mdx#multiple-configurations), wonder if there's a better way of having per project configs?

```lua
-- load the last session  
vim.keymap.set("n", "<leader>ql", function() require("persistence").load({ last = true }) end)
```
