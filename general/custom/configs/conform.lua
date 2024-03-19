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

		python = function(bufnr)
			if require("conform").get_formatter_info("ruff_format", bufnr).available then
				return { "ruff_format" }
			else
				return { "black", "isort", "autoflake" }
			end
		end,
		-- Use the "*" filetype to run formatters on all filetypes.
		["*"] = { "codespell" },
		-- Use the "_" filetype to run formatters on filetypes that don't
		-- have other formatters configured.
		["_"] = { "trim_whitespace" },
	},
}

require("conform").setup(options)

-- prepend_args can be a function, just like args
require("conform").formatters.autoflake = {
	prepend_args = { "-i", "--remove-all-unused-imports", "--ignore-init-module-imports" },
}
