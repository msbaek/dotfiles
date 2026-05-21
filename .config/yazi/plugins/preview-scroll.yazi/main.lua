--- @sync entry
--- Scroll the preview pane by a fixed number of lines (not proportional to
--- the pane height like the built-in `seek`). Pass the line delta as an arg:
---   plugin preview-scroll -- 1    (down 1 line)
---   plugin preview-scroll -- -1   (up 1 line)

return {
	entry = function(_, job)
		local step = tonumber(job.args[1]) or 1

		local hovered = cx.active.current.hovered
		if not hovered then
			return
		end

		ya.emit("peek", {
			math.max(0, cx.active.preview.skip + step),
			only_if = hovered.url,
		})
	end,
}
