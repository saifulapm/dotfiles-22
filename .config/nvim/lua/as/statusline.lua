--- =====================================================================
--- Resources:
--- =====================================================================
--- 1. https://gabri.me/blog/diy-vim-statusline
--- 2. https://github.com/elenapan/dotfiles/blob/master/config/nvim/statusline.vim
--- 3. https://got-ravings.blogspot.com/2008/08/vim-pr0n-making-statuslines-that-own.html
--- 4. Right sided truncation - https://stackoverflow.com/a/20899652

local utils = require('as.utils.statusline')
local H = require('as.highlights')

local api = vim.api
local P = as.style.palette
local icons = as.style.icons

local M = {}

local function colors()
  --- NOTE: Unicode characters including vim devicons should NOT be highlighted
  --- as italic or bold, this is because the underlying bold font is not necessarily
  --- patched with the nerd font characters
  --- terminal emulators like kitty handle this by fetching nerd fonts elsewhere
  --- but this is not universal across terminals so should be avoided

  local indicator_color = P.bright_blue
  local warning_fg = as.style.lsp.colors.warn

  local error_color = as.style.lsp.colors.error
  local info_color = as.style.lsp.colors.info
  local normal_fg = H.get_hl('Normal', 'fg')
  local pmenu_bg = H.get_hl('Pmenu', 'bg')
  local string_fg = H.get_hl('String', 'fg')
  local number_fg = H.get_hl('Number', 'fg')
  local identifier_fg = H.get_hl('Identifier', 'fg')
  local inc_search_bg = H.get_hl('Search', 'bg')

  local normal_bg = H.get_hl('Normal', 'bg')
  local dim_color = H.alter_color(normal_bg, 40)
  local bg_color = H.alter_color(normal_bg, -16)

  H.all({
    StMetadata = { background = bg_color, inherit = 'Comment' },
    StMetadataPrefix = {
      background = bg_color,
      inherit = 'Comment',
      italic = false,
      bold = false,
    },
    StIndicator = { background = bg_color, foreground = indicator_color },
    StModified = { foreground = string_fg, background = bg_color },
    StGit = { foreground = P.light_red, background = bg_color },
    StGreen = { foreground = string_fg, background = bg_color },
    StBlue = { foreground = P.dark_blue, background = bg_color, bold = true },
    StNumber = { foreground = number_fg, background = bg_color },
    StCount = { foreground = 'bg', background = indicator_color, bold = true },
    StPrefix = { background = pmenu_bg, foreground = normal_fg },
    StDirectory = { background = bg_color, foreground = 'Gray', italic = true },
    StDirectoryInactive = { background = bg_color, foreground = dim_color, italic = true },
    StParentDirectory = { background = bg_color, foreground = string_fg, bold = true },
    StIdentifier = { foreground = identifier_fg, background = bg_color },
    StTitle = { background = bg_color, foreground = 'LightGray', bold = true },
    StComment = { background = bg_color, inherit = 'Comment' },
    StInactive = { foreground = bg_color, background = P.comment_grey },
    StatusLine = { background = bg_color },
    StatusLineNC = { link = 'VertSplit' },
    StInfo = { foreground = info_color, background = bg_color, bold = true },
    StWarning = { foreground = warning_fg, background = bg_color },
    StError = { foreground = error_color, background = bg_color },
    StFilename = { background = bg_color, foreground = 'LightGray', bold = true },
    StFilenameInactive = {
      foreground = P.comment_grey,
      background = bg_color,
      bold = true,
      italic = true,
    },
    StModeNormal = { background = bg_color, foreground = P.whitesmoke, bold = true },
    StModeInsert = { background = bg_color, foreground = P.dark_blue, bold = true },
    StModeVisual = { background = bg_color, foreground = P.magenta, bold = true },
    StModeReplace = { background = bg_color, foreground = P.dark_red, bold = true },
    StModeCommand = { background = bg_color, foreground = inc_search_bg, bold = true },
  })
end

--- @param tbl table
--- @param next string
--- @param priority table
local function append(tbl, next, priority)
  priority = priority or 0
  local component, length = unpack(next)
  if component and component ~= '' and next and tbl then
    table.insert(tbl, { component = component, priority = priority, length = length })
  end
end

--- @param statusline table
--- @param available_space number
local function display(statusline, available_space)
  local str = ''
  local items = utils.prioritize(statusline, available_space)
  for _, item in ipairs(items) do
    if type(item.component) == 'string' then
      str = str .. item.component
    end
  end
  return str
end

---Aggregate pieces of the statusline
---@param tbl table
---@return function
local function make_status(tbl)
  return function(...)
    for i = 1, select('#', ...) do
      local item = select(i, ...)
      append(tbl, unpack(item))
    end
  end
end

local separator = { '%=' }
local end_marker = { '%<' }

local item = utils.item
local item_if = utils.item_if

---A very over-engineered statusline, heavily inspired by doom-modeline
---@return string
function _G.__statusline()
  -- use the statusline global variable which is set inside of statusline
  -- functions to the window for *that* statusline
  local curwin = vim.g.statusline_winid or 0
  local curbuf = api.nvim_win_get_buf(curwin)

  local available_space = vim.o.columns

  local ctx = {
    bufnum = curbuf,
    winid = curwin,
    bufname = api.nvim_buf_get_name(curbuf),
    preview = vim.wo[curwin].previewwindow,
    readonly = vim.bo[curbuf].readonly,
    filetype = vim.bo[curbuf].ft,
    buftype = vim.bo[curbuf].bt,
    modified = vim.bo[curbuf].modified,
    fileformat = vim.bo[curbuf].fileformat,
    shiftwidth = vim.bo[curbuf].shiftwidth,
    expandtab = vim.bo[curbuf].expandtab,
  }
  ----------------------------------------------------------------------------//
  -- Modifiers
  ----------------------------------------------------------------------------//
  local plain = utils.is_plain(ctx)
  local file_modified = utils.modified(ctx, icons.misc.circle)
  local focused = vim.g.vim_in_focus or true
  ----------------------------------------------------------------------------//
  -- Setup
  ----------------------------------------------------------------------------//
  local statusline = {}
  local add = make_status(statusline)

  add(
    { item_if(icons.misc.block, not plain, 'StIndicator', { before = '', after = '' }), 0 },
    { utils.spacer(1), 0 }
  )
  ----------------------------------------------------------------------------//
  -- Filename
  ----------------------------------------------------------------------------//
  local segments = utils.file(ctx, plain)
  local dir, parent, file = segments.dir, segments.parent, segments.file
  local dir_item = utils.item(dir.item, dir.hl, dir.opts)
  local parent_item = utils.item(parent.item, parent.hl, parent.opts)
  local file_item = utils.item(file.item, file.hl, file.opts)
  local readonly_hl = H.adopt_winhighlight(curwin, 'StatusLine', 'StCustomError', 'StError')
  local readonly_item = utils.item(utils.readonly(ctx), readonly_hl)
  ----------------------------------------------------------------------------//
  -- Mode
  ----------------------------------------------------------------------------//
  -- show a minimal statusline with only the mode and file component
  ----------------------------------------------------------------------------//
  if plain or not focused then
    add({ readonly_item, 1 }, { dir_item, 3 }, { parent_item, 2 }, { file_item, 0 })
    return display(statusline, available_space)
  end
  -----------------------------------------------------------------------------//
  -- Variables
  -----------------------------------------------------------------------------//
  local status = vim.b.gitsigns_status_dict or {}
  local updates = vim.g.git_statusline_updates or {}
  local ahead = updates.ahead and tonumber(updates.ahead) or 0
  local behind = updates.behind and tonumber(updates.behind) or 0

  -- Github notifications
  local ghn_ok, ghn = pcall(require, 'github-notifications')
  local notifications = ghn_ok and ghn.statusline_notification_count() or ''

  -- LSP Diagnostics
  local diagnostics = utils.diagnostic_info(ctx)
  local flutter = vim.g.flutter_tools_decorations or {}
  -----------------------------------------------------------------------------//
  -- Left section
  -----------------------------------------------------------------------------//
  add(
    { item_if(file_modified, ctx.modified, 'StModified'), 1 },
    { readonly_item, 2 },
    { item(utils.mode()), 0 },
    { item_if(utils.search_count(), vim.v.hlsearch > 0, 'StCount'), 1 },
    { dir_item, 3 },
    { parent_item, 2 },
    { file_item, 0 },
    { item_if('Saving…', vim.g.is_saving, 'StComment', { before = ' ' }), 1 },
    -- LSP Status
    { item(utils.current_function(), 'StMetadataPrefix', { before = '  ' }), 4 },
    -- Local plugin dev indicator
    {
      item_if(available_space > 100 and 'local dev' or '', vim.env.DEVELOPING ~= nil, 'StComment', {
        prefix = icons.misc.tools,
        padding = 'none',
        before = '  ',
        prefix_color = 'StWarning',
        small = 1,
      }),
      2,
    },
    { separator },
    -----------------------------------------------------------------------------//
    -- Middle section
    -----------------------------------------------------------------------------//
    -- Neovim allows unlimited alignment sections so we can put things in the
    -- middle of our statusline - https://neovim.io/doc/user/vim_diff.html#vim-differences
    -----------------------------------------------------------------------------//
    -- Start of the right side layout
    { separator },
    -----------------------------------------------------------------------------//
    -- Right section
    -----------------------------------------------------------------------------//
    { item(flutter.app_version, 'StMetadata'), 4 },
    { item(flutter.device and flutter.device.name or '', 'StMetadata'), 4 },
    { item(utils.lsp_client(ctx), 'StMetadata'), 4 },
    { item(utils.debugger(), 'StMetadata', { prefix = icons.misc.bug }), 4 },
    {
      item_if(diagnostics.error.count, diagnostics.error, 'StError', {
        prefix = diagnostics.error.sign,
      }),
      1,
    },
    {
      item_if(diagnostics.warning.count, diagnostics.warning, 'StWarning', {
        prefix = diagnostics.warning.sign,
      }),
      3,
    },
    {
      item_if(diagnostics.info.count, diagnostics.info, 'StInfo', {
        prefix = diagnostics.info.sign,
      }),
      4,
    },
    { item(notifications, 'StTitle'), 3 },
    -- Git Status
    { item(status.head, 'StBlue', { prefix = icons.git.logo, prefix_color = 'StGit' }), 1 },
    { item(status.changed, 'StTitle', { prefix = icons.git.mod, prefix_color = 'StWarning' }), 3 },
    {
      item(status.removed, 'StTitle', {
        prefix = icons.git.remove,
        prefix_color = 'StError',
      }),
      3,
    },
    {
      item(status.added, 'StTitle', {
        prefix = icons.git.add,
        prefix_color = 'StGreen',
      }),
      3,
    },
    {
      item(ahead, 'StTitle', {
        prefix = icons.misc.up,
        prefix_color = 'StGreen',
        before = '',
      }),
      5,
    },
    {
      item(behind, 'StTitle', { prefix = icons.misc.down, prefix_color = 'StNumber', after = ' ' }),
      5,
    },
    -- Current line number/total line number
    {
      utils.line_info({
        prefix = icons.misc.line,
        prefix_color = 'StMetadataPrefix',
        current_hl = 'StTitle',
        total_hl = 'StComment',
        sep_hl = 'StComment',
      }),
      7,
    },
    { -- column
      item('%-3c', 'StTitle', {
        prefix = 'Col:',
        prefix_color = 'StMetadataPrefix',
      }),
      7,
    },
    -- (Unexpected) Indentation
    {
      item_if(ctx.shiftwidth, ctx.shiftwidth > 2 or not ctx.expandtab, 'StTitle', {
        prefix = ctx.expandtab and icons.misc.indent or icons.misc.tab,
        prefix_color = 'StatusLine',
      }),
      6,
    },
    { end_marker }
  )
  -- removes 5 columns to add some padding
  return display(statusline, available_space - 5)
end

local function setup_autocommands()
  as.augroup('CustomStatusline', {
    { event = { 'FocusGained' }, pattern = { '*' }, command = 'let g:vim_in_focus = v:true' },
    { event = { 'FocusLost' }, pattern = { '*' }, command = 'let g:vim_in_focus = v:false' },
    {
      event = { 'VimEnter', 'ColorScheme' },
      pattern = { '*' },
      command = function()
        colors()
      end,
    },
    {
      event = { 'BufReadPre' },
      once = true,
      pattern = { '*' },
      command = function()
        utils.git_updates()
      end,
    },
    {
      event = { 'BufWritePre' },
      pattern = { '*' },
      command = function()
        if not vim.g.is_saving and vim.bo.modified then
          vim.g.is_saving = true
          vim.defer_fn(function()
            vim.g.is_saving = false
          end, 1000)
        end
      end,
    },
    {
      event = 'User',
      pattern = {
        'NeogitPushComplete',
        'NeogitCommitComplete',
        'NeogitStatusRefresh',
      },
      command = function()
        utils.git_updates_refresh()
      end,
    },
  })
end

-- attach autocommands
setup_autocommands()

-- :h qf.vim, disable qf statusline
vim.g.qf_disable_statusline = 1

-- set the statusline
vim.o.statusline = '%!v:lua.__statusline()'

return M
