-- Use a protected call so don't error out on first use
local status_ok, packer = pcall(require, "packer")

if not status_ok then
	return
end

-- Have packer use a popup window
packer.init {
    display = {
        open_fn = function()
            return require("packer.util").float { border = "rounded" }
        end,
        },
        git = {
            clone_timeout = 300, -- Timeout, in seconds, for git clones
        },
        prompt_border = 'single',
}

return packer.startup(function(use)

    -- Plugin manager
    use 'wbthomason/packer.nvim'

    -- Improved start speed
    use {
        'lewis6991/impatient.nvim',
        config = function()
            require('impatient').enable_profile()
        end
    }

    -- USER INTERFACE

    -- Colorschemes
    use 'tiagovla/tokyodark.nvim'
    use {
        'folke/tokyonight.nvim',
        config = function ()
            require("plugins.config.tokyonight")
        end
    }

    use {
        'catppuccin/nvim',
        tag = 'v0.2.4',
        config = function ()
            require("plugins.config.catppuccin")
        end
    }
    use 'sam4llis/nvim-tundra'
    use 'hoppercomplex/calvera-dark.nvim'
    use {
        'metalelf0/jellybeans-nvim',
        requires = 'rktjmp/lush.nvim'
    }
    use 'cocopon/iceberg.vim'
    use 'aktersnurra/no-clown-fiesta.nvim'
    use 'sainnhe/everforest'
    use 'arcticicestudio/nord-vim'
    use 'FrenzyExists/aquarium-vim'
    use 'dikiaap/minimalist'
    use 'challenger-deep-theme/vim'
    use 'AlexvZyl/nordic.nvim'
    use 'mountain-theme/Mountain'
    use 'JoosepAlviste/palenightfall.nvim'

    -- Common dependencies
    use 'nvim-lua/plenary.nvim'

    -- Start screen
    -- use {
    --     'glepnir/dashboard-nvim',
    --     -- Pin, more recent version breaks something
    --     commit = '1aab263f4773106abecae06e684f762d20ef587e',
    --     config = function()
    --         require("plugins.config.dashboard")
    --     end
    -- }

    -- File explorer
    use {
        'kyazdani42/nvim-tree.lua',
        tag = 'compat-nvim-0.7*',
        requires = {
            'kyazdani42/nvim-web-devicons',
        },
        cmd = {
            'NvimTreeOpen',
            'NvimTreeToggle',
            'NvimTreeFocus',
        },
        config = function()
            require("plugins.config.nvim-tree-config")
        end
    }

    -- Buffers
    use {
        'akinsho/bufferline.nvim',
        tag = "v3.*",
        requires = 'ryanoasis/vim-devicons',
        config = function()
            require("plugins.config.bufferline")
        end
    }
    -- use {
    --     'famiu/bufdelete.nvim',  -- Preserve window layout when deleting buffers
    --     commit = '8933abc09df6c381d47dc271b1ee5d266541448e',
    -- }

    -- Status line
    use {
        'nvim-lualine/lualine.nvim',
        requires = {
            {'kyazdani42/nvim-web-devicons', opt = true}
        },
        config = function()
            require("plugins.config.lualine")
        end
    }

    -- EDITOR PLUGINS

    -- Git
    use {
        'lewis6991/gitsigns.nvim',
        tag = 'v0.5*',
        config = function()
            require("plugins.config.gitsigns")
        end
    }
    use 'tpope/vim-fugitive'

    -- Show tab indents
    use {
        'lukas-reineke/indent-blankline.nvim',
        config = function()
            require("plugins.config.blankline")
        end
    }

    -- Auto pair brackets, parenthesis, etc. 
    use {
        'windwp/nvim-autopairs',
        config = function()
            require("plugins.config.autopairs")
        end
    }
    use {
        'windwp/nvim-ts-autotag',
        config = function ()
            require("plugins.config.ts-autotag")
        end
    }

    -- Smooth scrolling
    use {
        'karb94/neoscroll.nvim',
        config = function ()
            require("plugins.config.neoscroll")
        end
    }

    -- GENERAL/CORE

    -- Which key
    use {
        'folke/which-key.nvim',
        config = function ()
            require("plugins.config.which-key")
        end
    }

    -- Autocompletion
    use {
        'hrsh7th/nvim-cmp',
        requires = {"L3MON4D3/LuaSnip", tag = "v1.*"},
        config = function()
            require("plugins.config.cmp")
        end
    }
    use 'hrsh7th/cmp-path'          -- nvim-cmp source for filesystem paths
    use 'hrsh7th/cmp-cmdline'       -- nvim-cmp source for vim's cmdline

    -- Telescope
    use {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.0',
        requires = {
            {'nvim-lua/plenary.nvim'},                      -- general 
            {'nvim-treesitter/nvim-treesitter'},            -- finder/preview highlighting
            {'BurntSushi/ripgrep'},                         -- required for live_grep and grep_string
            {'nvim-telescope/telescope-fzf-native.nvim'},   -- better sorting performance
            {'nvim-telescope/telescope-file-browser.nvim'}, -- file browser
        },
        cmd='Telescope',                                     -- lazy load
        config = function()
            require("plugins.config.telescope")
        end
    }

    -- Better syntax highlighting
    use {
        'nvim-treesitter/nvim-treesitter',
        commit = '4cccb6f494eb255b32a290d37c35ca12584c74d0',
        run = ':TSUpdate',
        config = function()
            require("plugins.config.treesitter")
        end
    }

    use {
        'sindrets/diffview.nvim',
        requires = 'nvim-lua/plenary.nvim'
    }

    use({
        "iamcco/markdown-preview.nvim",
        run = function() vim.fn["mkdp#util#install"]() end,
    })
    
    use({ "iamcco/markdown-preview.nvim", run = "cd app && npm install", setup = function() vim.g.mkdp_filetypes = { "markdown" } end, ft = { "markdown" }, })

end)
