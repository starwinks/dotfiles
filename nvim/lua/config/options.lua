-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Windows tools may write files in the system ANSI code page (GBK/cp936).
-- Without it nvim falls back to latin1 and renders such files as mojibake.
vim.opt.fileencodings = { "ucs-bom", "utf-8", "cp936", "latin1" }
