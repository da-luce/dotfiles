require'nvim-treesitter.configs'.setup {
    -- A list of parser names, or "all"
    ensure_installed = { "c", "lua", "javascript", "cpp", "python", "markdown", "html", "svelte", "typescript"},

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    auto_install = true,

    highlight = {
        -- `false` will disable the whole extension
        enable = true,
    },
}
