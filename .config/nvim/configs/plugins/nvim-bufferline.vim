if !PluginLoaded('nvim-bufferline.lua')
  finish
endif


lua << EOF
require'bufferline'.setup {
  options = {
    view = "multiwindow",
    mappings = true,
    sort_by = "extension"
  };
}
EOF

nnoremap <silent> gb :BufferLinePick<CR>
nnoremap <silent><leader><tab>  :BufferLineCycleNext<CR>
nnoremap <silent><S-tab> :BufferLineCyclePrev<CR>
