local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

require("nvim-treesitter.install").compilers = { vim.fn.getenv "CC", "x86_64-conda-linux-gnu-gcc", "aarch64-conda-linux-gnu-gcc", "cc", "gcc", "clang", "cl", "zig" }

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
    "toml",
    "fish",
    "json",
    "yaml",
    "lua",
    "python",
    "cpp",
  },
  autotag = {
    enable = true,
  },
}
