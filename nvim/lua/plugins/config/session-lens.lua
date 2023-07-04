local status_ok, lens = pcall(require, "session-lens")
if not status_ok then
  return
end

lens.setup {
    path_display = {'truncate'},    -- Changes path behavoir
    theme_conf = { winbar = 100 },  -- Makes window opaque
    previewer = false               -- Disabled previewer
}
