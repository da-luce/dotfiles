-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- Automatic indentation
	{
        "tpope/vim-sleuth",
        pin = true,
    },

    -- Better syntax highlighting
    {
        'nvim-treesitter/nvim-treesitter',
        build = ":TSUpdate",
        config = function()
            require("config.treesitter")
        end
    },

    -- Git & GitHub plugins
	{
        "tpope/vim-rhubarb",
        pin = true,
    },

    {
	    "tpope/vim-fugitive",
        pin = true,
    },

    -- Fuzzy finding
    {
        'nvim-telescope/telescope.nvim',
        pin = true,
        event = "VeryLazy",
        dependencies = {
            'nvim-lua/plenary.nvim',                      -- general 
            'nvim-treesitter/nvim-treesitter',            -- finder/preview highlighting
            'BurntSushi/ripgrep',                         -- required for live_grep and grep_string
            'nvim-telescope/telescope-fzf-native.nvim',   -- better sorting performance
            'nvim-telescope/telescope-file-browser.nvim', -- file browser
        }
    },

    -- Colorscheme
    {
        'folke/tokyonight.nvim',
        pin = true,
        lazy = false,
        config = function()
			vim.cmd([[colorscheme tokyonight]])
		end,
    },


    -- Status line
    {
        'nvim-lualine/lualine.nvim',
        pin = true,
        config = function()
            require("config.lualine")
        end
    },

    -- Tab indents
    {
        'lukas-reineke/indent-blankline.nvim',
        pin = true,
        main = "ibl",
        config = function()
            require("config.blankline")
        end
    },

    -- Which key
    {
        'folke/which-key.nvim',
        pin = true,
        config = function ()
            require("config.which-key")
        end
    },

    -- Pair matching characters
	{
		"windwp/nvim-autopairs",
        pin = true,
		event = "InsertEnter",
		opts = {
			disable_filetype = { "TelescopePrompt", "vim" },
		},
	},

    -- Git signs
    {
        'lewis6991/gitsigns.nvim',
        pin = true,
        config = function()
            require("config.gitsigns")
        end
    },

    -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        pin = true,
        requires = {"L3MON4D3/LuaSnip", tag = "v1.*"},
        config = function()
            require("config.cmp")
        end
    },
    {
        'hrsh7th/cmp-path',          -- nvim-cmp source for filesystem paths
        pin = true,
    },
    {
        'hrsh7th/cmp-cmdline',       -- nvim-cmp source for vim's cmdline
        pin = true,
    },

})

