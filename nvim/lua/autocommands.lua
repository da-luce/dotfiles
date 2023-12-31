-- Toggle trailing whitespaces
local toggle_trailing = vim.api.nvim_create_augroup("ToggleTrailing", {clear = true})

vim.api.nvim_create_autocmd(
    "InsertEnter",
    {
        desc = "Don't show trailing whitespaces in insert mode",
        command = "set listchars-=trail:⋅",
        group = toggle_trailing,
    }
)

vim.api.nvim_create_autocmd(
    "InsertLeave",
    {
        desc = "Show trailing whitespaces when leaving insert mode",
        command = "set listchars+=trail:⋅",
        group = toggle_trailing,
    }
)
--[[
TODO: add spell check to markdown files
vim.api.nvim_create_autocmd(
    "FileType markdown",
    {
        command = 
    }
)
]] 
