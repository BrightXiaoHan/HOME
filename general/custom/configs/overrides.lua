local M = {}

M.treesitter = {
	ensure_installed = {
		"lua",
		"c",
		"cpp",
		"fish",
		"python",
		"bash",
	},
	indent = {
		enable = true,
		disable = {},
	},
}

M.mason = {
	ensure_installed = {
		-- lua stuff
		"lua-language-server",
		"stylua",

		-- web dev stuff
		"css-lsp",
		"html-lsp",
		"typescript-language-server",
		"deno",
		"prettier",

		-- c/cpp stuff
		"clangd",
		"clang-format",

		-- python stuff
		"pyright",
		"black",
		"isort",
		"mypy",
	},
}

local function nvimtree_attach(bufnr)
	local api = require("nvim-tree.api")

	local function opts(desc)
		return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
	end

	api.config.mappings.default_on_attach(bufnr)

	vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))
	vim.keymap.set("n", "v", api.node.open.vertical, opts("Open: Vertical Split"))
	vim.keymap.set("n", "h", api.node.open.horizontal, opts("Open: Horizontal Split"))
end

-- git support in nvimtree
M.nvimtree = {
	git = {
		enable = true,
	},

	on_attach = nvimtree_attach,

	renderer = {
		highlight_git = true,
		icons = {
			show = {
				git = true,
			},
		},
	},
}

M.cmp = {
	mapping = {
		["<Up>"] = require("cmp").mapping.select_prev_item(),
		["<Down>"] = require("cmp").mapping.select_next_item(),
		["<C-e>"] = require("cmp").mapping.close(),
		["<Tab>"] = require("cmp").config.disable,
	},
	sources = {
		{ name = "path" },
		{ name = "nvim_lsp", max_item_count = 3 },
		{ name = "buffer" },
		{ name = "nvim_lua" },
		{ name = "treesitter" },
	},
	-- disable auto-complete
	-- completion = {
	-- 	autocomplete = false,
	-- },
}

-- if win32 then use powershell else fish
if vim.fn.has("win32") == 1 then
	SHELL = "powershell.exe"
else
	SHELL = "fish"
end

M.nvterm = {
	terminals = {
		shell = SHELL,
		type_opts = {
			horizontal = { location = "rightbelow", split_ratio = 0.5, size = 50 },
		},
	},
}

return M
