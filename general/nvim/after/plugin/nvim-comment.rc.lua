local status_ok, nvim_comment = pcall(require, "nvim_comment")
if (not status_ok) then return end

nvim_comment.setup({
  marker_padding = true,
  comment_empty = false,
  create_mappings = false,
  line_mapping = "gcc",
  operator_mapping = "gc",
  hook = nil,
})
