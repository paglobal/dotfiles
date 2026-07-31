local utils = require 'core.utils'
utils.pack_add 'nvim-lua/plenary.nvim'
utils.pack_add 'nvim-telescope/telescope.nvim'
utils.pack_add 'nvim-telescope/telescope-ui-select.nvim'
if vim.fn.executable 'make' == 1 then
  utils.pack_add 'nvim-telescope/telescope-fzf-native.nvim'
end
require('telescope').setup {
  extensions = {
    ['ui-select'] = { require('telescope.themes').get_dropdown() },
  },
}
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')
local builtin = require 'telescope.builtin'
utils.map('<leader>fh', builtin.help_tags, '[F]ind [H]elp')
utils.map('<leader>fk', builtin.keymaps, '[F]ind [K]eymaps')
utils.map('<leader>ff', builtin.find_files, '[F]ind [F]iles')
utils.map('<leader>fs', builtin.lsp_document_symbols, '[F]ind Document [S]ymbols')
utils.map('<leader>fw', builtin.grep_string, '[F]ind Current [W]ord', { 'n', 'v' })
utils.map('<leader>fg', builtin.live_grep, '[F]ind By [G]rep')
utils.map('<leader>fd', builtin.diagnostics, '[F]ind [D]iagnostics')
utils.map('<leader>fr', builtin.resume, '[F]ind [R]esume')
utils.map('<leader>f.', builtin.oldfiles, '[F]ind Recent Files ("." for repeat)')
utils.map('<leader>fe', builtin.symbols, '[F]ind Symbols And [E]mojis')
utils.map('<leader>fb', builtin.builtin, '[F]ind [B]uiltin Telescope')
utils.map('<leader><leader>', builtin.buffers, '[ ] Find Existing Buffers')
utils.map('<leader>fc', builtin.commands, '[F]ind [C]ommands')
utils.map('<leader>/', function()
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, '[/] Fuzzily search in current buffer')
utils.map('<leader>f/', function()
  builtin.live_grep {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }
end, '[F]ind [/] in Open Files')
utils.map('<leader>fn', function()
  builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true }
end, '[F]ind [N]eovim files')
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
  callback = function(event)
    utils.map('grr', builtin.lsp_references, '[G]oto [R]eferences', nil, event.buf)
    utils.map('gri', builtin.lsp_implementations, '[G]oto [I]mplementation', nil, event.buf)
    utils.map('gd', builtin.lsp_definitions, '[G]oto [D]efinition', nil, event.buf)
    utils.map('gO', builtin.lsp_document_symbols, '[O]pen Document Symbols', nil, event.buf)
    utils.map('gW', builtin.lsp_dynamic_workspace_symbols, 'Open [W]orkspace Symbols', nil, event.buf)
    utils.map('grt', builtin.lsp_type_definitions, '[G]oto [T]ype Definition', nil, event.buf)
  end,
})
