return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>bf',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[B]uffer [F]ormat',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      local disable_filetypes = { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      else
        return {
          timeout_ms = 500,
          lsp_format = 'fallback',
        }
      end
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      javascript = { 'prettier', 'prettierd', stop_after_first = true },
      javascriptreact = { 'prettier', 'prettierd', stop_after_first = true },
      typescript = { 'prettier', 'prettierd', stop_after_first = true },
      typescriptreact = { 'prettier', 'prettierd', stop_after_first = true },
      html = { 'prettier', 'prettierd', stop_after_first = true },
      css = { 'prettier', 'prettierd', stop_after_first = true },
      json = { 'prettier', 'prettierd', stop_after_first = true },
      yaml = { 'prettierd', 'prettier' },
      python = { 'isort', 'black' },
    },
  },
}
