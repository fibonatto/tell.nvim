local M = {}

local function get_visual_selection()
	local start = vim.fn.getpos("'<")
	local finish = vim.fn.getpos("'>")

	local lines = vim.api.nvim_buf_get_lines(0, start[2] - 1, finish[2], false)

	if #lines == 0 then
		return ""
	end

	local mode = vim.fn.visualmode()

	if mode == "V" then
		return table.concat(lines, "\n")
	end

	lines[1] = string.sub(lines[1], start[3])
	lines[#lines] = string.sub(lines[#lines], 1, finish[3])

	return table.concat(lines, "\n")
end

local function insert_after_selection(bufnr, finish, output)
	local lines = vim.split(output, "\n", {
		plain = true,
	})

	local mode = vim.fn.visualmode()

	if mode == "V" then
		vim.api.nvim_buf_set_lines(bufnr, finish[2], finish[2], false, { "", unpack(lines) })

		return
	end

	local line = vim.api.nvim_buf_get_lines(bufnr, finish[2] - 1, finish[2], false)[1]

	local before = string.sub(line, 1, finish[3])
	local after = string.sub(line, finish[3] + 1)

	local replacement = { before }

	for _, output_line in ipairs(lines) do
		table.insert(replacement, output_line)
	end

	replacement[#replacement + 1] = after

	vim.api.nvim_buf_set_lines(bufnr, finish[2] - 1, finish[2], false, replacement)
end

function M.tell()
	local bufnr = vim.api.nvim_get_current_buf()
	local selection = get_visual_selection()

	if selection == "" then
		vim.notify("tell.nvim: no selection", vim.log.levels.WARN)
		return
	end

	local finish = vim.fn.getpos("'>")
	local changedtick = vim.b.changedtick

	vim.notify("tell.nvim: thinking...", vim.log.levels.INFO)

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

			if vim.b[bufnr].changedtick ~= changedtick then
				vim.notify("tell.nvim: buffer changed while waiting", vim.log.levels.WARN)
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

			insert_after_selection(bufnr, finish, output)
		end)
	end)
end

function M.setup()
	vim.keymap.set("v", "%", M.tell, {
		silent = true,
		desc = "Ask Tell about selection",
	})
end

return M
