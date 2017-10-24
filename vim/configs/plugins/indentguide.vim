""---------------------------------------------------------------------------//
"Indent Guide {{{
""---------------------------------------------------------------------------//
let g:indentLine_fileType       = [
      \ 'c',
      \ 'cpp',
      \ 'typescript',
      \ 'javascript',
      \ 'javascript.jsx',
      \ 'typescript.tsx'
      \ ]
let g:indentLine_bufNameExclude = [
      \ 'NERD_tree.*',
      \ 'Startify',
      \ 'terminal',
      \ 'help',
      \ 'magit',
      \ 'peekabo' ]
let g:indentLine_faster         = 1
let g:indentLine_setConceal     = 0
let g:indentLine_concealcursor  = ''
let g:indentLine_char           = '┊'
let g:indentLine_color_term     = 228
" let g:indentLine_char = " ︙"
nnoremap <leader>il :IndentLinesToggle<CR>
"}}}
