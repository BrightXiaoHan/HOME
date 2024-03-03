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

-- prepend_args can be a function, just like args
require("conform").formatters.autoflake = {
	prepend_args = { "-i", "--remove-all-unused-imports" },
}
