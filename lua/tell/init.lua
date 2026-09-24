local M = {}

local function get_visual_selection()
	local start = vim.fn.getpos("v")
	local finish = vim.fn.getpos(".")

	local lines = vim.fn.getregion(start, finish, {
		type = vim.fn.mode(),
	})

	return table.concat(lines, "\n"), start, finish
end

function M.tell()
	local bufnr = vim.api.nvim_get_current_buf()

	local selection, start, finish = get_visual_selection()

	if selection == "" then
		vim.notify("tell.nvim: empty selection", vim.log.levels.WARN)
		return
	end

	vim.notify("tell.nvim: running tell")

	vim.system({
		"tell",
		"j-",
		selection,
	}, {
		text = true,
	}, function(result)
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end

			if result.code ~= 0 then
				vim.notify("tell.nvim: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
				return
			end

			local output = vim.trim(result.stdout or "")

			if output == "" then
				vim.notify("tell.nvim: empty response", vim.log.levels.WARN)
				return
			end

			local response = vim.split(output, "\n", {
				plain = true,
			})

			-- Insert after the last selected line.
			vim.api.nvim_buf_set_lines(bufnr, finish[2], finish[2], false, { "", unpack(response) })

			vim.notify("tell.nvim: response inserted")
		end)
	end)
end

function M.setup()
	vim.keymap.set("x", "%", M.tell, {
		silent = false,
		desc = "Ask Tell about selection",
	})
end

return M
