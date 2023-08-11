local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

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
