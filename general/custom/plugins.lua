local overrides = require("custom.configs.overrides")

---@type NvPluginSpec[]
local plugins = { -- Override plugin definition options
	{
		"neovim/nvim-lspconfig",
		dependencies = { -- format & linting
			{
				"jose-elias-alvarez/null-ls.nvim",
				config = function()
					require("custom.configs.null-ls")
				end,
			},
		},
		config = function()
			require("plugins.configs.lspconfig")
			require("custom.configs.lspconfig")
		end, -- Override to setup mason-lspconfig
	}, -- override plugin configs
	{
		"williamboman/mason.nvim",
		opts = overrides.mason,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		opts = overrides.treesitter,
	},
	{
		"nvim-tree/nvim-tree.lua",
		opts = overrides.nvimtree,
	}, -- Install a plugin
	{
		"hrsh7th/nvim-cmp",
		opts = overrides.cmp,
	},
	{
		"max397574/better-escape.nvim",
		event = "InsertEnter",
		config = function()
			require("better_escape").setup()
		end,
	},
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_echo_preview_url = 1
      vim.g.mkdp_open_to_the_world = 1
		end,
		ft = { "markdown" },
	},
	{
		"github/copilot.vim",
		lazy = false,
		config = function()
			vim.g.copilot_no_tab_map = true
			vim.g.copilot_assume_mapped = true
			-- vim.g.copilot_tab_fallback = "";
		end,
	},
	{
		"Pocco81/auto-save.nvim",
		lazy = false,
	},
}

return plugins
