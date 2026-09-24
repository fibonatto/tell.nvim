local M = {}

local function get_selection()
	local start = vim.fn.getpos("'<")
	local finish = vim.fn.getpos("'>")

	local lines = vim.api.nvim_buf_get_lines(0, start[2] - 1, finish[2], false)

	if #lines == 0 then
		return ""
	end

	if vim.fn.visualmode() == "V" then
		return table.concat(lines, "\n")
	end

	lines[1] = string.sub(lines[1], start[3])
	lines[#lines] = string.sub(lines[#lines], 1, finish[3])

	return table.concat(lines, "\n")
end

function M.tell()
	vim.notify("tell.nvim: triggered")

	local selection = get_selection()

	if selection == "" then
		vim.notify("tell.nvim: empty selection", vim.log.levels.ERROR)
		return
	end

	vim.notify("tell.nvim: running tell")

	local start = vim.fn.getpos("'<")
	local finish = vim.fn.getpos("'>")

	local bufnr = vim.api.nvim_get_current_buf()

	vim.system({
		"tell",
		"j-",
		selection,
	}, {
		text = true,
	}, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				vim.notify("tell.nvim: " .. (result.stderr or "tell failed"), vim.log.levels.ERROR)
				return
			end

			local output = vim.trim(result.stdout or "")

			if output == "" then
				vim.notify("tell.nvim: tell returned no output", vim.log.levels.WARN)
				return
			end

			local response = vim.split(output, "\n", {
				plain = true,
			})

			vim.api.nvim_buf_set_lines(bufnr, finish[2], finish[2], false, { "", unpack(response) })

			vim.notify("tell.nvim: response inserted")
		end)
	end)
end

function M.setup()
	vim.keymap.set("v", "%", M.tell, {
		silent = false,
		desc = "Ask Tell about selection",
	})
end

return M
