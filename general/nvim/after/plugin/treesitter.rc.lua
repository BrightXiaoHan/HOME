local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

require("nvim-treesitter.install").compilers = { vim.fn.getenv "CC", "cc", "gcc", "clang", "cl", "zig" }

ts.setup {
  highlight = {
    enable = true,
    disable = {},
  },
  indent = {
    enable = true,
    disable = {},
  },
  ensure_installed = {
    "fish",
    "lua",
    "python",
    "cpp",
  },
  autotag = {
    enable = true,
  },
}
