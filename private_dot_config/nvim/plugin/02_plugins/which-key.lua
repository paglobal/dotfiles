require('core.utils').pack_add 'folke/which-key.nvim'
require('which-key').setup {
  delay = 0,
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { '<leader>f', group = '[F]ind', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
  },
}
