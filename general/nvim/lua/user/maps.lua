vim.g.mapleader = " "
vim.g.maplocalleader = " "
local keymap = vim.keymap

-- Select all
keymap.set('n', '<C-a>', 'gg<S-v>G')
-- Window Resize
keymap.set('n', '<C-Left>', '<C-w><')
keymap.set('n', '<C-Right>', '<C-w>>')
keymap.set('n', '<leader>=', '<C-w>+')
keymap.set('n', '<leader>-', '<C-w>-')

-- Telescope
keymap.set('n', '<C-p>', ':Telescope find_files<CR>')
keymap.set('n', '<C-f>', ':Telescope live_grep<CR>')

-- nvim-comment
keymap.set('n', '<leader>/', ':CommentToggle<CR>')
keymap.set('v', '<leader>/', ':\'<,\'>CommentToggle<CR>')

local leaderkeymap = {
    ["<tab>"] = { "<C-w>w" },
    s = {
      name = '+split',
      s = { "<cmd>split<cr>", "Split" },
      v = { "<cmd>vsplit<cr>", "VSplit" },
    },
    e = { "<cmd>NvimTreeToggle<cr>", "Explorer" },
    f = { "<cmd>Telescope current_buffer_fuzzy_find<cr>", "Find" },
    q = { "<cmd>q<cr>", "Quit" },
    o = { "<cmd>AerialToggle<cr>", "Outline" },
    -- set 1-9 as go to windows 0-9
    ["1"] = { "<cmd>1wincmd w<cr>", "Go to window 1" },
    ["2"] = { "<cmd>2wincmd w<cr>", "Go to window 2" },
    ["3"] = { "<cmd>3wincmd w<cr>", "Go to window 3" },
    ["4"] = { "<cmd>4wincmd w<cr>", "Go to window 4" },
    ["5"] = { "<cmd>5wincmd w<cr>", "Go to window 5" },
    ["6"] = { "<cmd>6wincmd w<cr>", "Go to window 6" },
    ["7"] = { "<cmd>7wincmd w<cr>", "Go to window 7" },
    ["8"] = { "<cmd>8wincmd w<cr>", "Go to window 8" },
    ["9"] = { "<cmd>9wincmd w<cr>", "Go to window 9" },
    ["0"] = { "<cmd>10wincmd w<cr>", "Go to window 10" },
}

local status, wk = pcall(require, "whichkey_setup")
if status then
  wk.register_keymap('leader', leaderkeymap)
end
