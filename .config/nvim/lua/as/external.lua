local M = {
  tmux = {},
  kitty = {},
}

local hl_ok, mod = as.safe_require('as.highlights', { silent = true })

---@module "as.highlights"
local H = mod

local fn = vim.fn
local fmt = string.format

--- Get the color of the current vim background and update tmux accordingly
---@param reset boolean?
function M.tmux.set_statusline(reset)
  if not hl_ok then
    return
  end
  local hl = reset and 'Normal' or 'MsgArea'
  local bg = H.get_hl(hl, 'bg')
  -- TODO: we should correctly derive the previous bg value
  fn.jobstart(fmt('tmux set-option -g status-style bg=%s', bg))
end

local function get_colors(color)
  local colors = {
    active_tab_background = color,
    inactive_tab_background = color,
    tab_bar_background = color,
  }
  local str = as.fold(function(acc, c, name)
    acc = acc .. fmt(' %s=%s', name, c)
    return acc
  end, colors, '')
  return str, colors
end

function M.kitty.set_colors()
  if not hl_ok then
    return
  end
  local bg = H.get('BufferlineFill', 'bg')
  if vim.env.KITTY_LISTEN_ON then
    fn.jobstart(fmt('kitty @ --to %s set-colors %s', vim.env.KITTY_LISTEN_ON, get_colors(bg)))
  end
end

---Reset the kitty terminal colors
function M.kitty.clear_colors()
  if not hl_ok then
    return
  end
  if vim.env.KITTY_LISTEN_ON then
    local bg = H.get('Normal', 'bg')
    -- this is intentionally synchronous so it has time to execute fully
    fn.system(fmt('kitty @ --to %s set-colors %s', vim.env.KITTY_LISTEN_ON, get_colors(bg)))
  end
end

local function fileicon()
  local name = fn.bufname()
  local icon, hl
  local loaded, devicons = as.safe_require('nvim-web-devicons')
  if loaded then
    icon, hl = devicons.get_icon(name, fn.fnamemodify(name, ':e'), { default = true })
  end
  return icon, hl
end

function M.title_string()
  if not hl_ok then
    return
  end
  local dir = fn.fnamemodify(fn.getcwd(), ':t')
  local icon, hl = fileicon()
  if not hl then
    return (icon or '') .. ' '
  end
  local has_tmux = vim.env.TMUX ~= nil
  return has_tmux and fmt('%s #[fg=%s]%s ', dir, H.get_hl(hl, 'fg'), icon) or dir .. ' ' .. icon
end

function M.tmux.clear_pane_title()
  fn.jobstart('tmux set-window-option automatic-rename on')
end

return M
