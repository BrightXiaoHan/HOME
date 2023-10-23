---@type MappingsTable
local M = {}

M.general = {
	n = {
		[";"] = {
			":",
			"enter command mode",
			opts = { nowait = true },
		},
		["<C-a>"] = { "gg<S-v>G", "Select All" },
		-- Window
		["<C-Left>"] = { "<C-w><" },
		["<C-Right>"] = { "<C-w>>", "" },
		["<A-Up>"] = { "<C-w>+", "" },
		["<A-Down>"] = { "<C-w>-", "" },
		["<leader><tab>"] = { "<C-w>w", "" },

		-- Telescope
		["<C-p>"] = { ":Telescope find_files<CR>", "Find file" },
		["<C-f>"] = { ":Telescope live_grep<CR>", "Fuzzy find" },

		["<leader>q"] = { "<cmd>q<cr>", "Quit" },
		["<leader>o"] = { "<cmd>AerialToggle<cr>", "Outline" },
		["<leader>e"] = { "<cmd>NvimTreeToggle<cr>", "Explorer" },
		["<leader>f"] = { "<cmd>Telescope current_buffer_fuzzy_find<cr>", "Find" },

		["<C-`>"] = {
			function()
				require("nvterm.terminal").toggle("horizontal")
			end,
			"Toggle horizontal term",
		},
	},
	v = {
		[">"] = { ">gv", "indent" },
	},
	t = {
		["<C-`>"] = {
			function()
				require("nvterm.terminal").toggle("horizontal")
			end,
			"Toggle horizontal term",
		},
		["<Esc>"] = {
			"<C-\\><C-n>",
		},
	},
}

M.copilot = {
	i = {
		["<C-i>"] = {
			function()
				vim.fn.feedkeys(vim.fn["copilot#Accept"](), "")
			end,
			"Copilot Accept",
			{ replace_keycodes = true, nowait = true, silent = true, expr = true, noremap = true },
		},
	},
}

M.lsp = {
	n = {
		["<leader>lf"] = { "<cmd>lua vim.lsp.buf.format()<cr>", "Format" },
		["<leader>lr"] = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
		["<leader>ld"] = { "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<cr>", "Line diagnostics" },
		["<leader>lp"] = { "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>", "Previous diagnostic" },
		["<leader>ln"] = { "<cmd>lua vim.lsp.diagnostic.goto_next()<cr>", "Next diagnostic" },
	},
}

M.gitsigns = {
	n = {
		["]c"] = {
			function()
				if vim.wo.diff then
					return "[c"
				end
				vim.schedule(function()
					require("gitsigns").prev_hunk()
				end)
				return "<Ignore>"
			end,
			"Next hunk",
			{ expr = true },
		},
		["[c"] = {
			function()
				if vim.wo.diff then
					return "]c"
				end
				vim.schedule(function()
					require("gitsigns").next_hunk()
				end)
				return "<Ignore>"
			end,
			"Previous hunk",
			{ expr = true },
		},
		["<leader>gs"] = { "<cmd>lua require'gitsigns'.stage_hunk()<CR>", "Stage hunk" },
		["<leader>gr"] = { "<cmd>lua require'gitsigns'.reset_hunk()<CR>", "Reset hunk" },
		["<leader>gS"] = { "<cmd>lua require'gitsigns'.stage_buffer()<CR>", "Stage buffer" },
		["<leader>gu"] = { "<cmd>lua require'gitsigns'.undo_stage_hunk()<CR>", "Undo stage hunk" },
		["<leader>gR"] = { "<cmd>lua require'gitsigns'.reset_buffer()<CR>", "Reset buffer" },
		["<leader>gp"] = { "<cmd>lua require'gitsigns'.preview_hunk()<CR>", "Preview hunk" },
		["<leader>gb"] = { "<cmd>lua require'gitsigns'.blame_line()<CR>", "Blame line" },
		["<leader>gt"] = { "<cmd>lua require'gitsigns'.toggle_current_line_blame()<CR>", "Toggle current line blame" },
		["<leader>gd"] = { "<cmd>lua require'gitsigns'.diffthis()<CR>", "Diff this" },
		["<leader>gD"] = { "<cmd>lua require'gitsigns'.diffthis()<CR>", "Diff this (vertical split)" },
	},
}

M.peek = {
	n = {
		["<leader>mo"] = { "<cmd>lua require('peek').open()<cr>", "Markdown Preview" },
		["<leader>mc"] = { "<cmd>lua require('peek').close()<cr>", "Markdown Close" },
	},
}

-- more keybinds!
return M
