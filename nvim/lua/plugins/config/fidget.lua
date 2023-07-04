local status_ok, fidget = pcall(require, "fidget")
if not status_ok then
    return
end

fidget.setup({
	text = {
		spinner = "dots",
		done = "",
		commenced = "Started",
		completed = "Completed",
	},
	window = {
		relative = "win",
		blend = 0,
		zindex = nil,
		border = "none",
		},
})
