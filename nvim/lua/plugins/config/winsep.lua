local status_ok, winsep = pcall(require, "colorful-winsep")
if not status_ok then
    return
end

winsep.setup {
  -- timer refresh rate
  interval = 30,
  -- This plugin will not be activated for filetype in the following table.
  no_exec_files = { "packer", "TelescopePrompt", "mason", "CompetiTest", "NvimTree" },
  -- Symbols for separator lines, the order: horizontal, vertical, top left, top right, bottom left, bottom right.
  --symbols = { "━", "┃", "┏", "┓", "┗", "┛" },
  symbols = { " ", "┃", "┏", "┓", "┗", "┛" },
  close_event = function()
    -- Executed after closing the window separator
  end,
    create_event = function()
    if vim.fn.winnr('$') == 3 then
      local win_id = vim.fn.win_getid(vim.fn.winnr('h'))
      local filetype = vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(win_id), 'filetype')
      if filetype == "NvimTree" then
        winsep.NvimSeparatorDel()
      end
    end
  end
}
