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

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 's', vim.lsp.buf.signature_help, {desc = "Signature help"})
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

-- Auto format rust
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = {"*.rs"},
  callback = function()
    vim.lsp.buf.format()
  end,
})

--[[
TODO: add spell check to markdown files
vim.api.nvim_create_autocmd(
    "FileType markdown",
    {
        command = 
    }
)
]] 

-- Tmux status toggle based on Vim/Neovim state
if vim.env.TMUX then
  local tmux_group = vim.api.nvim_create_augroup("TmuxStatus", { clear = true })
  
  local tmux_events = {
    "VimResume",
    "VimEnter",
    "VimLeave",
    "VimSuspend"
  }

  for _, event in ipairs(tmux_events) do
    vim.api.nvim_create_autocmd(event, {
      group = tmux_group,
      callback = function()
        -- Set status off for Resume and Enter, on for Leave and Suspend
        local status = (event == "VimResume" or event == "VimEnter") and "off" or "on"
        vim.fn.system(string.format("tmux set status %s", status))
      end,
    })
  end
end