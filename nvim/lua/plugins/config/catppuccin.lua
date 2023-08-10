local status_ok, catppuccin = pcall(require, "catppuccin")
if not status_ok then
    return
end

local flavour = vim.api.nvim_get_option("background") == "dark" and "mocha" or "latte"
vim.g.catppuccin_flavour = flavour

catppuccin.setup({
})
