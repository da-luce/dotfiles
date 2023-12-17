-- Indenting
vim.opt.autoindent = true          -- apply same indent to next line on enter
vim.opt.smartindent = true         -- indent reacts to code syntax
vim.opt.tabstop = 4                -- insert 4 spaces for a tab (how many columns of whitespace a \t char is worth)
vim.opt.expandtab = true           -- convert tabs to spaces
vim.opt.shiftwidth = 4             -- number of spaces inserted for each indentation
vim.opt.softtabstop = 4            -- how many columns of whitespace a tab or backspace is worth

-- UI
vim.opt.cursorline = true          -- highlight current line of cursor
vim.opt.number = true              -- show line numbers
vim.opt.relativenumber = true      -- lines numbers are relative
vim.opt.termguicolors = true       -- use colorscheme & init.lua gui values to set color highlighting rather than cterm* values
vim.opt.background = "dark"        -- use dark colorscheme for themes with light/dark variants
vim.opt.signcolumn = "yes"         -- permanent column for LSP & Git icons in gutter
vim.opt.ruler = false              -- hide line and column number of the cursor position in cmdline (already habe in statusline!)
vim.opt.showmode = false           -- don't show mode in the command line (already have in statusline!)
vim.opt.cmdheight=1                -- hide the command line (NOT WORKING)

-- Interactions
vim.opt.mouse = "a"                -- enable mouse in all modes
vim.opt.updatetime = 300           -- time to write a swap file and determine when cursor isn't moving (in milliseconds) - completion and gitgutter relies on this
vim.opt.timeoutlen = 1000          -- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.clipboard = "unnamedplus"  -- allows neovim to access system keyboard
vim.opt.ignorecase = true          -- ignore case in search patterns
vim.opt.scrolloff = 8              -- minimum number of context lines above and below cursor (keeps cursor more centered when scrolling)
vim.opt.undofile = true            -- enable persistent undo (undotree is saved to a file when exiting buffer)
vim.opt.wrap = false               -- display lines as one long line
vim.opt.sidescrolloff = 8          -- minimal number of screen columns to left and right of the cursor if wrap is `false`
vim.opt.swapfile = false           -- disable swap files

-- Character highlights
vim.opt.listchars = {
    trail = '⋅',            -- shows trailing whitespaces
    tab = '  ',             -- shows tabs as spaces (must override for some reason)
}
vim.opt.list = true
vim.opt.fillchars = {
    eob = ' ',               -- show empty lines at the end of a buffer as ` ` (default `~`)
}

-- Additional options
vim.opt.iskeyword:append("-")       -- treats words with `-` as single words
