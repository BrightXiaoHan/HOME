local status, dap = pcall(require, "dap")
if (not status) then return end

-- load .vscode/launch.json
require("dap.ext.vscode").load_launchjs()

local status, dapui = pcall(require, "dapui")
if (not status) then return end

dapui.setup()

if (not status) then return end
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
-- dap.listeners.before.event_terminated["dapui_config"] = function()
--   dapui.close()
-- end
-- dap.listeners.before.event_exited["dapui_config"] = function()
--   dapui.close()
-- end

local status, dappython = pcall(require, "dap-python")
if (not status) then return end
dappython.setup('python')
dappython.test_runner = 'pytest'

-- add keymaps
vim.api.nvim_set_keymap('n', '<F5>', "<cmd>lua require'dap'.continue()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<F10>', "<cmd>lua require'dap'.step_over()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<F11>', "<cmd>lua require'dap'.step_into()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<F12>', "<cmd>lua require'dap'.step_out()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>b', "<cmd>lua require'dap'.toggle_breakpoint()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>B', "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>dp', "<cmd>lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>dr', "<cmd>lua require'dap'.repl.open()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>dl', "<cmd>lua require'dap'.run_last()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>dn', "<cmd>lua require('dap-python').test_method()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<leader>df', "<cmd>lua require('dap-python').test_class()<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('v', '<leader>ds', "<cmd>lua require('dap-python').debug_selection()<CR>", {noremap = true, silent = true})

-- key map dapui.close
vim.api.nvim_set_keymap('n', '<leader>dc', "<cmd>lua require'dapui'.close()<CR>", {noremap = true, silent = true})
