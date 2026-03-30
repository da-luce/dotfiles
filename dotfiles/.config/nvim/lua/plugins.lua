-- Enable Neovim's experimental fast Lua loader
vim.loader.enable()

-- ==========================================
-- HELPER FUNCTION: "author/repo" shorthand
-- ==========================================
local function add(repo)
    -- vim.pack.add strictly expects a list, so we wrap the string in { }
    vim.pack.add({ "https://github.com/" .. repo })
end

-- ==========================================
-- 1. BUILD HOOKS (Must be defined first)
-- ==========================================
vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("PluginBuildHooks", { clear = true }),
    callback = function(args)
        local spec = args.data.spec
        if not spec or (args.data.kind ~= "update" and args.data.kind ~= "install") then return end

        if spec.name == "nvim-treesitter" then
            vim.cmd("TSUpdate")
        elseif spec.name == "markdown-preview.nvim" then
            vim.fn["mkdp#util#install"]()
        end
    end
})

-- ==========================================
-- 2. COLORSCHEMES (Load early)
-- ==========================================
add("folke/tokyonight.nvim")
add("sainnhe/everforest")
add("AlexvZyl/nordic.nvim")
vim.g.everforest_background = 'hard'

add("sainnhe/gruvbox-material")
vim.g.gruvbox_material_background = 'medium'
vim.cmd.colorscheme('gruvbox-material')

-- ==========================================
-- 3. CORE DEPENDENCIES
-- ==========================================
add("nvim-lua/plenary.nvim")

-- Treesitter (needed by Telescope and others)
add("nvim-treesitter/nvim-treesitter")

-- ==========================================
-- 4. UTILITIES & GIT
-- ==========================================
add("alec-gibson/nvim-tetris")
add("tpope/vim-sleuth")
add("tpope/vim-rhubarb")
add("tpope/vim-fugitive")

add("lewis6991/gitsigns.nvim")
require("config.gitsigns")

-- ==========================================
-- 5. TELESCOPE
-- ==========================================
add("nvim-telescope/telescope-fzf-native.nvim")
add("nvim-telescope/telescope-file-browser.nvim")
add("nvim-telescope/telescope.nvim")
require("config.telescope")

-- ==========================================
-- 6. LSP CONFIGURATION (Order is strict)
-- ==========================================
add("williamboman/mason.nvim")
require("mason").setup()

add("williamboman/mason-lspconfig.nvim")
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls", "rust_analyzer" }
})

add("neovim/nvim-lspconfig")
-- 1. Configure and enable lua_ls
vim.lsp.config("lua_ls", {
    settings = {
        Lua = { diagnostics = { globals = { 'vim' } } }
    }
})
vim.lsp.enable("lua_ls")


-- 2. Configure and enable rust_analyzer
vim.lsp.config("rust_analyzer", {
    settings = {
        ['rust-analyzer'] = { rustfmt = { extraArgs = { "--edition=2018" } } },
    },
})
vim.lsp.enable("rust_analyzer")

-- ==========================================
-- 7. UI PLUGINS
-- ==========================================
add("nvim-lualine/lualine.nvim")
require("config.lualine")

add("lukas-reineke/indent-blankline.nvim")
require("config.blankline")

add("folke/which-key.nvim")
require("config.which-key")

-- ==========================================
-- 8. NATIVE LAZY LOADING
-- ==========================================
-- nvim-autopairs: Load only on InsertEnter
vim.api.nvim_create_autocmd("InsertEnter", {
    once = true,
    callback = function()
        add("windwp/nvim-autopairs")
        require("nvim-autopairs").setup({
            disable_filetype = { "TelescopePrompt", "vim" },
        })
    end,
})

-- markdown-preview: Load only when opening a Markdown file
vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    once = true,
    callback = function()
        add("iamcco/markdown-preview.nvim")
    end,
})