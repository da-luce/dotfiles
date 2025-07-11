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

    -- Colorscheme: set first for other plugins that may depend on highlights
    'folke/tokyonight.nvim',
    'sainnhe/everforest',
    {
        "AlexvZyl/nordic.nvim",
        pin = true,
        lazy = false,
        config = function()
            vim.g.everforest_background = 'hard'
        end,
    },
    {
        'sainnhe/gruvbox-material',
        pin = true,
        config = function()
            vim.g.gruvbox_material_background = 'medium'
            vim.cmd.colorscheme('gruvbox-material')
        end,
    },

    -- Tetris game
    {
        "alec-gibson/nvim-tetris",
        pin = true,
    },

    -- LSP
    {
        "williamboman/mason.nvim",
        pin = true,
        config = function()
            require("mason").setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        pin = true,
        config = function()
            require("mason-lspconfig").setup({ensure_installed = { "lua_ls", "rust_analyzer" },})
        end,
    },
    {
        "neovim/nvim-lspconfig",
        pin = true,
        config = function()
            local lspconfig = require('lspconfig')
            lspconfig.lua_ls.setup {
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = { 'vim' }
                        }
                    }
                }
            }
            lspconfig.rust_analyzer.setup {
                -- Server-specific settings. See `:help lspconfig-setup`
                settings = {
                    ['rust-analyzer'] = { rustfmt = {extraArgs = {"--edition=2018"},} },
                },
            }
        end,
    },

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
        dependencies = {
            'nvim-lua/plenary.nvim',                      -- general
            'nvim-treesitter/nvim-treesitter',            -- finder/preview highlighting
            'BurntSushi/ripgrep',                         -- required for live_grep and grep_string
            'nvim-telescope/telescope-fzf-native.nvim',   -- better sorting performance
            'nvim-telescope/telescope-file-browser.nvim', -- file browser
        }
    },

    -- Status line
    {
        'nvim-lualine/lualine.nvim',
        pin = true,
        dependencies = { 'sainnhe/gruvbox-material' },
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
    -- TODO: currently not working
    -- {
    --     'hrsh7th/nvim-cmp',
    --     pin = true,
    --     requires = {"L3MON4D3/LuaSnip", tag = "v1.*"},
    --     config = function()
    --         require("config.cmp")
    --     end
    -- },
    -- {
    --     'hrsh7th/cmp-path',          -- nvim-cmp source for filesystem paths
    --     pin = true,
    -- },
    -- {
    --     'hrsh7th/cmp-cmdline',       -- nvim-cmp source for vim's cmdline
    --     pin = true,
    -- },

    {
        "iamcco/markdown-preview.nvim",
        pin = true,
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        ft = { "markdown" },
        build = function() vim.fn["mkdp#util#install"]() end,
    },
})

