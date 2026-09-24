local M = {}

local fallback_comments = {
	javascript = "// %s",
	javascriptreact = "// %s",
	typescript = "// %s",
	typescriptreact = "// %s",
	rust = "// %s",
	c = "// %s",
	cpp = "// %s",
	java = "// %s",
	go = "// %s",
	swift = "// %s",
	kotlin = "// %s",
	zig = "// %s",
	python = "# %s",
	ruby = "# %s",
	perl = "# %s",
	bash = "# %s",
	sh = "# %s",
	zsh = "# %s",
	fish = "# %s",
	lua = "-- %s",
	haskell = "-- %s",
	sql = "-- %s",
	vim = '" %s',
	lisp = "; %s",
	scheme = "; %s",
	clojure = "; %s",
	css = "/* %s */",
	scss = "// %s",
	less = "// %s",
	html = "<!-- %s -->",
	xml = "<!-- %s -->",
	markdown = "<!-- %s -->",
}

local function get_visual_selection()
	local start = vim.fn.getpos("v")
	local finish = vim.fn.getpos(".")

	local lines = vim.fn.getregion(start, finish, {
		type = vim.fn.mode(),
	})

	return table.concat(lines, "\n"), finish
end

local function get_commentstring(bufnr)
	local commentstring = vim.api.nvim_get_option_value("commentstring", { buf = bufnr })

	if commentstring and commentstring:find("%%s") then
		return commentstring
	end

	local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

	return fallback_comments[filetype]
end

local function comment_output(bufnr, output)
	local commentstring = get_commentstring(bufnr)

	if not commentstring then
		vim.notify("tell.nvim: no comment syntax for filetype", vim.log.levels.WARN)
		return output
	end

	local lines = vim.split(output, "\n", {
		plain = true,
	})

	for i, line in ipairs(lines) do
		if line == "" then
			lines[i] = commentstring:format("")
		else
			lines[i] = commentstring:format(line)
		end
	end

	return table.concat(lines, "\n")
end

function M.tell()
	local bufnr = vim.api.nvim_get_current_buf()

	local selection, finish = get_visual_selection()

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

			output = comment_output(bufnr, output)

			local response = vim.split(output, "\n", {
				plain = true,
			})

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
