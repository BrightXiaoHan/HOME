local M = {}

M.treesitter = {
	ensure_installed = {
		"lua",
		"c",
		"cpp",
		"markdown",
		"markdown_inline",
		"fish",
		"python",
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

		-- markdown stuff
		"marksman",
		"markdownlint",
		"mdformat",
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
    ["<A-Space>"] = require("cmp").mapping.complete(),
    ["<C-e>"] = require("cmp").mapping.close(),
    ["<CR>"] = require("cmp").mapping.confirm({
      behavior = require("cmp").ConfirmBehavior.Replace,
      select = true,
    }),
  },
}

return M
