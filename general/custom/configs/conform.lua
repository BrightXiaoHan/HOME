local options = {
	lsp_fallback = true,
	formatters_by_ft = {
		lua = { "stylua" },

		javascript = { "prettier" },
		css = { "prettier" },
		html = { "prettier" },
		json = { "prettier" },
		jsonc = { "prettier" },
		markdown = { "prettier" },

		sh = { "shfmt" },
		fish = { "fish_indent" },

		python = { "black", "isort", "autoflake" },
	},
}

require("conform").setup(options)
