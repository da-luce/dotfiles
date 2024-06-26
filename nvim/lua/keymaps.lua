-- TODO: what does this do
-- Silent map option
local opts = { noremap = true, silent = true }

-- Use space as leader key
vim.keymap.set("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "

-- Better window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
vim.keymap.set("n", "<C-l>", "<C-w>l", opts)

-- Resize with arrows
vim.keymap.set("n", "<C-Up>", ":resize -2<CR>", opts)
vim.keymap.set("n", "<C-Down>", ":resize +2<CR>", opts)
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", opts)
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
vim.keymap.set("n", "<S-l>", ":bnext<CR>", opts)
vim.keymap.set("n", "<S-h>", ":bprevious<CR>", opts)

-- Clear highlights
vim.keymap.set("n", "<leader>h", "<cmd>nohlsearch<CR>", opts)

-- Close buffers
vim.keymap.set("n", "<S-q>", "<cmd>bd<CR>", opts)

-- Stay in indent mode
vim.keymap.set("v", "<", "<gv", opts) 
vim.keymap.set("v", ">", ">gv", opts)

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {desc = "Telescope find files"})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {desc = "Telescope live grep"})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {desc = "Telescope buffers"})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {desc = "Telescope help tags"})
vim.keymap.set("n", "<leader>fs", ":Telescope file_browser<CR>", {desc = "Telescope file browser"})

-- LSP
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, {desc = "Open diagnostic float"})
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {desc = "Previous diagnostic"})
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {desc = "Next diagnostic"})
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, {desc = "Set loclist diagnostics"})

