local status, neotest = pcall(require, "neotest")
if (not status) then return end

local status, neotest_python = pcall(require, "neotest-python")
if (not status) then return end

-- if windows use .venv/Scripts/python.exe
-- else use .venv/bin/python
-- local python = vim.fn.has("win32") == 1 and ".venv\\Scripts\\python.exe" or ".venv/bin/python"

require("neotest").setup({
    adapters = {
      require("neotest-python")({
          -- Extra arguments for nvim-dap configuration
          -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
          dap = { justMyCode = false },
          -- Command line arguments for runner
          -- Can also be a function to return dynamic values
          args = {"--log-level", "DEBUG"},
          -- Runner to use. Will use pytest if available by default.
          -- Can be a function to return dynamic value.
          runner = "pytest",
          -- Custom python path for the runner.
          -- Can be a string or a list of strings.
          -- Can also be a function to return dynamic value.
          -- If not provided, the path will be inferred by checking for 
          -- virtual envs in the local directory and for Pipenev/Poetry configs
          python = "python",
          -- Returns if a given file path is a test file.
          -- NB: This function is called a lot so don't perform any heavy tasks within it.
          is_test_file = function(file_path)
            -- if start with test_
            return file_path:match("test_.*%.py$") ~= nil
          end,
      })
    }
  })
  
  vim.api.nvim_set_keymap("n", "<leader>tn", "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<CR>", { noremap = true, silent = true })