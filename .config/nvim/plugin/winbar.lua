---@diagnostic disable: duplicate-doc-param

local devicons = require('nvim-web-devicons')
local highlights = require('as.highlights')
local utils = require('as.utils.statusline')
local component = utils.component
local component_raw = utils.component_raw
local empty = as.empty

local fn = vim.fn
local api = vim.api
local icons = as.style.icons.misc

local dir_separator = '/'
local separator = icons.arrow_right
local ellipsis = icons.ellipsis

vim.cmd([[
function! HandleWinbarClick(minwid, clicks, btn, modifiers) abort
  call v:lua.as.winbar_click(a:minwid, a:clicks, a:btn, a:modifiers)
endfunction
]])

--- A mapping of each winbar items ID to its path
--- @type table<string, string>
as.winbar_state = {}

---@param id number
---@param _ number number of clicks
---@param _ "l"|"r"|"m" the button clicked
---@param _ string modifiers
function as.winbar_click(id, _, _, _)
  if id then
    vim.cmd('edit ' .. as.winbar_state[id])
  end
end

highlights.plugin('winbar', {
  Winbar = { bold = false },
  WinbarNC = { bold = false },
  WinbarCrumb = { bold = true },
  WinbarIcon = { inherit = 'Function' },
  WinbarDirectory = { inherit = 'Directory' },
})

local function breadcrumbs()
  local ok, navic = pcall(require, 'nvim-navic')
  if not ok or not navic.is_available() then
    return { component(ellipsis, 'NonText', { priority = 0 }) }
  end
  local win = api.nvim_get_current_win()
  return { component_raw(navic.get_location(), { priority = 1, win_id = win, type = 'winbar' }) }
end

---@return string
function as.ui.winbar()
  local winbar = {}
  local add = utils.winline(winbar)

  add(utils.spacer(1))

  local bufname = api.nvim_buf_get_name(api.nvim_get_current_buf())
  if empty(bufname) then
    return add(component('[No name]', 'Winbar', { priority = 0 }))
  end

  local parts = vim.split(fn.fnamemodify(bufname, ':.'), '/')
  local icon, color = devicons.get_icon(bufname, nil, { default = true })

  as.foreach(function(part, index)
    local priority = (#parts - (index - 1)) * 2
    local is_first = index == 1
    local is_last = index == #parts
    local sep = is_last and separator or dir_separator
    local hl = is_last and 'Winbar' or 'NonText'
    local suffix_hl = is_last and 'WinbarDirectory' or 'NonText'
    as.winbar_state[priority] = table.concat(vim.list_slice(parts, 1, index), '/')
    add(component(part, hl, {
      id = priority,
      priority = priority,
      click = 'HandleWinbarClick',
      suffix = sep,
      suffix_color = suffix_hl,
      prefix = is_first and icon or nil,
      prefix_color = is_first and color or nil,
    }))
  end, parts)
  add(unpack(breadcrumbs()))
  return utils.display(winbar, api.nvim_win_get_width(api.nvim_get_current_win()))
end

local blocked = {
  'NeogitStatus',
  'NeogitCommitMessage',
  'toggleterm',
  'DressingInput',
}
local allowed = { 'toggleterm' }

as.augroup('AttachWinbar', {
  {
    event = { 'BufWinEnter', 'BufEnter', 'WinClosed' },
    desc = 'Toggle winbar',
    command = function()
      for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
        local buf = api.nvim_win_get_buf(win)
        if
          not vim.tbl_contains(blocked, vim.bo[buf].filetype)
          and empty(fn.win_gettype(win))
          and empty(vim.bo[buf].buftype)
          and not empty(vim.bo[buf].filetype)
        then
          vim.wo[win].winbar = '%{%v:lua.as.ui.winbar()%}'
        elseif not vim.tbl_contains(allowed, vim.bo[buf].filetype) then
          vim.wo[win].winbar = ''
        end
      end
    end,
  },
})
