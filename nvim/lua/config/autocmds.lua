-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Windows PowerShell (5.1) decodes a BOM-less script with the system ANSI code
-- page (cp936 here), so UTF-8 Chinese becomes mojibake. UTF-8 with a BOM is the
-- one encoding both Windows PowerShell 5.1 and pwsh 7 read correctly.
-- Scoped to /mnt so Linux-side PowerShell scripts stay plain UTF-8 (a BOM would
-- break a `#!/usr/bin/env pwsh` shebang).
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "/mnt/*.ps1", "/mnt/*.psm1", "/mnt/*.psd1" },
  callback = function()
    vim.bo.fileencoding = "utf-8"
    vim.bo.bomb = true
  end,
})
