if vim.g.loaded_tell then
	return
end

vim.g.loaded_tell = true

require("tell").setup()
