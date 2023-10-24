local null_ls = require("null-ls")

local b = null_ls.builtins

local sources = {

	-- webdev stuff
	b.formatting.deno_fmt, -- choosed deno for ts/js files cuz its very fast!
	b.formatting.prettier.with({
		filetypes = {
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"vue",
			"css",
			"scss",
			"less",
			"html",
			"json",
			"jsonc",
			"yaml",
			"markdown",
			"markdown.mdx",
			"graphql",
			"handlebars",
		},
	}), -- so prettier works only on these filetypes

	-- Lua
	b.formatting.stylua,

	-- cpp
	b.formatting.clang_format,

	-- python
	b.formatting.prettier.with({ extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" } }),
	b.formatting.black.with({ extra_args = { "--fast" } }),
	b.formatting.stylua,
	b.formatting.isort,
	b.formatting.autoflake.with({ extra_args = { "--remove-all-unused-imports", "--remove-unused-variables" } }),

	-- bash sh
	b.formatting.shfmt.with({ filetypes = { "sh" } }), -- sh
}

null_ls.setup({
	debug = false,
	sources = sources,
})
