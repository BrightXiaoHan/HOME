local status, gitsigns = pcall(require, "gitsigns")
if (not status) then return end

local status, wk = pcall(require, "which-key")
if (not status) then return end

gitsigns.setup {
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    -- Navigation
    vim.keymap.set('n', ']c', function()
      if vim.wo.diff then return '[c' end
      vim.schedule(function() gs.prev_hunk() end)
      return '<Ignore>'
    end, { expr = true, buffer = bufnr })

    vim.keymap.set('n', '[c', function()
      if vim.wo.diff then return ']c' end
      vim.schedule(function() gs.next_hunk() end)
      return '<Ignore>'
    end, { expr = true, buffer = bufnr })

    -- Text object
    vim.keymap.set({ 'o', 'x' }, 'ih', function()
      if vim.wo.diff then return 'ih' end
      return '<cmd>lua require"gitsigns".select_hunk()<CR>'
    end, { expr = true, buffer = bufnr })

    wk.register({
      h = {
        name = "+hunk",
        s = { gs.stage_hunk, "Stage hunk" },
        r = { gs.reset_hunk, "Reset hunk" },
        S = { gs.stage_buffer, "Stage buffer" },
        u = { gs.undo_stage_hunk, "Undo stage hunk" },
        R = { gs.reset_buffer, "Reset buffer" },
        p = { gs.preview_hunk, "Preview hunk" },
        b = { gs.blame_line, "Blame line" },
        t = { gs.toggle_current_line_blame, "Toggle current line blame" },
        d = { gs.diffthis, "Diff this" },
        D = { gs.diffthis, "Diff this (vertical split)" },
      },
    }, { prefix = "<leader>", mode = "n", buffer = bufnr })

    wk.register({
      t = {
        name = "+toggle",
        b = { gs.toggle_current_line_blame, "Toggle current line blame" },
        d = { gs.toggle_deleted, "Toggle deleted" },
      },
    }, { prefix = "<leader>", mode = "n", buffer = bufnr })

    -- visual mode mappings
    wk.register({
      h = {
        name = "+hunk",
        s = { function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, "Stage hunk" },
        r = { function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, "Reset hunk" },
      },
    }, { prefix = "<leader>", mode = "v", buffer = bufnr })
  end
}
