if has_key(g:plugs, "lightline.vim")
  finish
endif

let s:mode_map = {
        \  'n': ['NORMAL',  'NormalMode' ],     'no': ['PENDING', 'NormalMode'  ],  'v': ['VISUAL',  'VisualMode' ],
        \  'V': ['V-LINE',  'VisualMode' ], "\<c-v>": ['V-BLOCK', 'VisualMode'  ],  's': ['SELECT',  'VisualMode' ],
        \  'S': ['S-LINE',  'VisualMode' ], "\<c-s>": ['S-BLOCK', 'VisualMode'  ],  'i': ['INSERT',  'InsertMode' ],
        \ 'ic': ['COMPLETE','InsertMode' ],     'ix': ['CTRL-X',  'InsertMode'  ],  'R': ['REPLACE', 'ReplaceMode'],
        \ 'Rc': ['COMPLETE','ReplaceMode'],     'Rv': ['REPLACE', 'ReplaceMode' ], 'Rx': ['CTRL-X',  'ReplaceMode'],
        \  'c': ['COMMAND', 'CommandMode'],     'cv': ['COMMAND', 'CommandMode' ], 'ce': ['COMMAND', 'CommandMode'],
        \  'r': ['PROMPT',  'CommandMode'],     'rm': ['-MORE-',  'CommandMode' ], 'r?': ['CONFIRM', 'CommandMode'],
        \  '!': ['SHELL',   'CommandMode'],      't': ['TERMINAL', 'CommandMode']}

  let s:ro_sym  = ''
  let s:ma_sym  = "✗"
  let s:mod_sym = "◇"
  let s:ff_map  = { "unix": "␊", "mac": "␍", "dos": "␍␊" }

function! s:file_encoding()
  return winwidth(0) > 70 ? (strlen(&fenc) ? &fenc : &enc) : ''
endfunction

function s:line_info() abort
  " TODO This component should truncate from the left not right
  return winwidth(0) > 100 ? '%.15( %l/%L %p%%%)' : ''
endfunction


function! StatuslineCurrentFunction()
    return get(b:, 'coc_current_function', '')
endfunction

function! StatuslineGitStatus() abort
  let status = get(b:, "coc_git_status", "")
  return winwidth(0) > 120 ? status : ''
endfunction

function StatuslineGitRepoStatus() abort
  return get(g:, "coc_git_status", "")
endfunction

" Find out current buffer's size and output it.
function! s:file_size()
  let bytes = getfsize(expand('%:p'))
  if (bytes >= 1024)
    let kbytes = bytes / 1024
  endif
  if (exists('kbytes') && kbytes >= 1000)
    let mbytes = kbytes / 1000
  endif

  if bytes <= 0
    return '0'
  endif

  if (exists('mbytes'))
    return mbytes . 'MB '
  elseif (exists('kbytes'))
    return kbytes . 'KB '
  else
    return bytes . 'B '
  endif
endfunction

let s:st_mode = {'color': '%#StMode#', 'sep_color': '%#StModeSep#'}
let s:st_info = { 'color': '%#StInfo#', 'sep_color': '%#StInfoSep#' }
let s:st_ok =   { 'color': '%#StOk#', 'sep_color': '%#StOkSep#' }
let s:st_inactive = { 'color': '%#StInactive#', 'sep_color': '%#StInactiveSep#' }

let s:gold         = '#F5F478'
let s:white        = '#abb2bf'
let s:light_red    = '#e06c75'
let s:dark_red     = '#be5046'
let s:green        = '#98c379'
let s:light_yellow = '#e5c07b'
let s:dark_yellow  = '#d19a66'
let s:blue         = '#61afef'
let s:dark_blue    = '#4e88ff'
let s:magenta      = '#c678dd'
let s:cyan         = '#56b6c2'
let s:gutter_grey  = '#636d83'
let s:comment_grey = '#5c6370'

function! s:set_statusline_colors() abort
  let s:normal_bg = synIDattr(hlID('Normal'), 'bg')
  let s:normal_fg = synIDattr(hlID('Normal'), 'fg')
  let s:pmenu_bg  = synIDattr(hlID('Pmenu'), 'bg')
  let s:warning_fg = synIDattr(hlID('WarningMsg'), 'fg')
  let s:error_fg = synIDattr(hlID('ErrorMsg'), 'fg')

  silent! execute 'highlight StItemPrefix guibg='.s:pmenu_bg.' guifg='.s:normal_fg.' gui=italic,bold'
  silent! execute 'highlight StItemPrefixSep guibg='.s:normal_bg.' guifg='.s:pmenu_bg.' gui=italic,bold'
  silent! execute 'highlight StItem guibg='.s:normal_fg.' guifg='.s:normal_bg.' gui=italic,bold'
  silent! execute 'highlight StSep guifg='.s:normal_fg.' guibg=NONE gui=NONE'
  silent! execute 'highlight StInfo guifg='.s:normal_bg.' guibg='.s:dark_blue.' gui=NONE'
  silent! execute 'highlight StInfoSep guifg='.s:dark_blue.' guibg=NONE gui=NONE'
  silent! execute 'highlight StOk guifg='.s:normal_bg.' guibg='.s:dark_yellow.' gui=NONE'
  silent! execute 'highlight StOkSep guifg='.s:dark_yellow.' guibg=NONE gui=NONE'
  silent! execute 'highlight StInactive guifg='.s:normal_bg.' guibg='.s:comment_grey.' gui=NONE'
  silent! execute 'highlight StInactiveSep guifg='.s:comment_grey.' guibg=NONE gui=NONE'
  silent! execute 'highlight Statusline guifg=NONE guibg='.s:normal_bg.' gui=NONE cterm=NONE'
  silent! execute 'highlight StatuslineNC guifg=NONE guibg='.s:normal_bg.' gui=NONE cterm=NONE'
endfunction

function! s:sep(item, ...) abort
  let l:opts = get(a:, '1', {})
  let l:before = get(l:opts, 'before', ' ')
  let l:prefix = get(l:opts, 'prefix', '')
  let l:small = get(l:opts, 'small', 0)
  let l:color = get(l:opts, 'color', '%#StItem#')
  let l:prefix_color = get(l:opts, 'prefix_color', '%#StItem#')
  let l:prefix_sep_color = get(l:opts, 'prefix_sep_color', '%#StItem#')

  let l:sep_color = get(l:opts, 'sep_color', '%#StSep#')
  let l:sep_color_left = !empty(prefix) ? l:prefix_sep_color : l:sep_color
  let l:prefix_item_left = l:prefix_color . l:prefix . " "

  let l:sep_icon_left = !empty(prefix) ? ''. l:prefix_item_left :
        \ l:small ? '' : '█'
  let l:sep_icon_right = l:small ? '%*' : '█%*'

  return l:before.
        \ l:sep_color_left.
        \ l:sep_icon_left.
        \ l:color.
        \ a:item.
        \ l:sep_color.
        \ l:sep_icon_right
endfunction

function! s:sep_if(item, condition, ...) abort
  if !a:condition
    return ''
  endif
  let l:opts = get(a:, '1', {})
  return s:sep(a:item, l:opts)
endfunction

function! s:mode() abort
  let l:mode = mode()
  call s:mode_highlight(l:mode)

  let l:mode_map={
        \ 'n'  : 'NORMAL',
        \ 'no' : 'N·OPERATOR PENDING ',
        \ 'v'  : 'VISUAL',
        \ 'V'  : 'V·LINE',
        \ '' : 'V·BLOCK',
        \ 's'  : 'SELECT',
        \ 'S'  : 'S·LINE',
        \ '^S' : 'S·BLOCK',
        \ 'i'  : 'INSERT',
        \ 'R'  : 'REPLACE',
        \ 'Rv' : 'V·REPLACE',
        \ 'c'  : 'COMMAND',
        \ 'cv' : 'VIM EX',
        \ 'ce' : 'EX',
        \ 'r'  : 'PROMPT',
        \ 'rm' : 'MORE',
        \ 'r?' : 'CONFIRM',
        \ '!'  : 'SHELL',
        \ 't'  : 'TERMINAL'
        \}
  return get(l:mode_map, l:mode, 'UNKNOWN')
endfunction

function! s:mode_highlight(mode) abort
  if a:mode ==? 'i'
    silent! exe 'highlight StMode guibg='.s:dark_blue.' guifg='.s:normal_bg.' gui=bold'
    silent! exe 'highlight StModeSep guifg='.s:dark_blue.' guibg=NONE gui=bold'
  elseif a:mode =~? '\(v\|V\|\)'
    silent! exe 'highlight StMode guibg='.s:magenta.' guifg='.s:normal_bg.' gui=bold'
    silent! exe 'highlight StModeSep guifg='.s:magenta.' guibg=NONE gui=bold'
  elseif a:mode ==? 'R'
    silent! exe 'highlight StMode guibg='.s:dark_red.' guifg='.s:normal_bg.' gui=bold'
    silent! exe 'highlight StModeSep guifg='.s:dark_red.' guibg=NONE gui=bold'
  else
    silent! exe 'highlight StMode guibg='.s:green.' guifg='.s:normal_bg.' gui=bold'
    silent! exe 'highlight StModeSep guifg='.s:green.' guibg=NONE gui=bold'
  endif
endfunction

function! StatusLine(...) abort
  let opts = get(a:, '1', {})
  ""---------------------------------------------------------------------------//
  " Modifiers
  ""---------------------------------------------------------------------------//
  let inactive = get(opts, 'inactive', 0)
  let plain = statusline#show_plain_statusline()

  let title = statusline#filename()
  let current_mode = s:mode()
  let file_type = statusline#filetype()
  let file_format = statusline#file_format()
  let line_info = s:line_info()

  let s:info_item = {component -> "%#StInfoSep#".component}
  ""---------------------------------------------------------------------------//
  " Mode
  ""---------------------------------------------------------------------------//
  "show a minimal statusline with only the mode and file component
  if plain || inactive
    return s:sep(title, s:st_inactive)
  endif
  ""---------------------------------------------------------------------------//
  " Setup
  ""---------------------------------------------------------------------------//
  let statusline =  s:sep(current_mode, extend({'before': ''}, s:st_mode))
  let statusline .= s:sep(" " . title, {
        \ 'prefix': file_type,
        \ 'prefix_color': '%#StItemPrefix#',
        \ 'prefix_sep_color': '%#StItemPrefixSep#'
        \ })

  " Start of the right side layout
  let statusline .= '%='
  let statusline .=" "
  let statusline .= s:info_item("%{StatuslineGitRepoStatus()}")
  let statusline .= s:info_item("%{StatuslineGitStatus()}")
  let statusline .=" "
  let statusline .= '%{coc#status()}'
  let statusline .= s:sep_if("%{StatuslineCurrentFunction()}",
        \ !empty(StatuslineCurrentFunction()), {})

  "Current line number/Total line numbers
  let statusline .= s:sep_if(line_info, !empty(line_info), s:st_mode)
  let statusline .= '%<'
  return statusline
endfunction

function MinimalStatusLine() abort
  return StatusLine({ 'inactive': 1 })
endfunction

augroup custom_statusline
  autocmd!
  autocmd BufEnter,WinEnter * setlocal statusline=%!StatusLine()
  autocmd BufLeave,WinLeave * setlocal statusline=%!MinimalStatusLine()
  autocmd VimEnter,ColorScheme * call s:set_statusline_colors()
augroup END


" =====================================================================
" Resources:
" =====================================================================
" 1. https://gabri.me/blog/diy-vim-statusline
" 2. https://github.com/elenapan/dotfiles/blob/master/config/nvim/statusline.vim
