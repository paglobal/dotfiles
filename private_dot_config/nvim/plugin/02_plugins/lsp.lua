local utils = require 'core.utils'
utils.pack_add 'j-hui/fidget.nvim'
utils.pack_add 'neovim/nvim-lspconfig'
utils.pack_add 'mason-org/mason.nvim'
utils.pack_add 'mason-org/mason-lspconfig.nvim'
utils.pack_add 'WhoIsSethDaniel/mason-tool-installer.nvim'
require('fidget').setup {}
require('mason').setup {}
require('mason-lspconfig').setup { automatic_enable = false }
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    utils.map('gH', vim.diagnostic.open_float, 'Diagnostic [H]over', nil, event.buf)
    utils.map('gh', vim.lsp.buf.hover, '[H]over', nil, event.buf)
    utils.map('grn', vim.lsp.buf.rename, '[R]e[n]ame', nil, event.buf)
    utils.map('gca', vim.lsp.buf.code_action, '[G]oto [C]ode [A]ction', { 'n', 'x' }, event.buf)
    utils.map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration', nil, event.buf)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
        end,
      })
    end
    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      utils.map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints', nil, event.buf)
    end
  end,
})
---@type table<string, vim.lsp.Config>
local servers = {
  gopls = {},
  emmet_language_server = {},
  vtsls = {},
  html = {},
  cssls = {},
  bashls = {},
  tailwindcss = {},
  svelte = {},
  tombi = {},
  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false
      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then
          return
        end
      end
      local current_settings = client.config.settings or {} --[[@as lspconfig.settings.lua_ls]]
      client.config.settings.Lua = vim.tbl_deep_extend('force', current_settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        },
      })
    end,
    settings = {
      Lua = {
        format = { enable = false },
      },
    },
  },
}
local ensure_installed = vim.tbl_keys(servers)
table.insert(ensure_installed, 'stylua')
require('mason-tool-installer').setup { ensure_installed = ensure_installed }
for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end
local system_servers = {
  qmlls = {
    cmd = { '/usr/lib/qt6/bin/qmlls' },
  },
  nushell = {},
}
for name, server in pairs(system_servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end
