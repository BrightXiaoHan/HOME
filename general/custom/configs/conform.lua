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

    python = { "black", "isort", "autoflake" },
  },
}

require("conform").setup(options)
