return function()
  local telescope = require 'telescope'
  local actions = require 'telescope.actions'

  local H = require 'as.highlights'
  H.plugin(
    'telescope',
    { 'TelescopeMatching', { link = 'Title', force = true } },
    { 'TelescopeBorder', { link = 'GreyFloatBorder', force = true } },
    {
      'TelescopeSelectionCaret',
      {
        guifg = H.get_hl('Identifier', 'fg'),
        guibg = H.get_hl('TelescopeSelection', 'bg'),
      },
    }
  )

  telescope.setup {
    defaults = {
      set_env = { ['TERM'] = vim.env.TERM },
      prompt_prefix = ' ',
      selection_caret = '» ',
      mappings = {
        i = {
          ['<c-c>'] = function()
            vim.cmd 'stopinsert!'
          end,
          ['<esc>'] = actions.close,
          ['<c-s>'] = actions.select_horizontal,
          ['<c-j>'] = actions.cycle_history_next,
          ['<c-k>'] = actions.cycle_history_prev,
        },
      },
      file_ignore_patterns = { '%.jpg', '%.jpeg', '%.png', '%.otf', '%.ttf' },
      path_display = { 'smart', 'absolute' },
      layout_strategy = 'flex',
      layout_config = {
        horizontal = {
          preview_width = 0.45,
        },
      },
      winblend = 10,
      history = {
        path = vim.fn.stdpath 'data' .. '/telescope_history.sqlite3',
      },
    },
    extensions = {
      frecency = {
        workspaces = {
          conf = vim.env.DOTFILES,
          project = vim.env.PROJECTS_DIR,
          wiki = vim.g.wiki_path,
        },
      },
      fzf = {
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
      },
    },
    pickers = {
      buffers = {
        sort_mru = true,
        sort_lastused = true,
        show_all_buffers = true,
        ignore_current_buffer = true,
        previewer = false,
        theme = 'dropdown',
        mappings = {
          i = { ['<c-x>'] = 'delete_buffer' },
          n = { ['<c-x>'] = 'delete_buffer' },
        },
      },
      oldfiles = {
        theme = 'dropdown',
      },
      live_grep = {
        file_ignore_patterns = { '.git/' },
      },
      current_buffer_fuzzy_find = {
        theme = 'dropdown',
        previewer = false,
        shorten_path = false,
      },
      lsp_code_actions = {
        theme = 'cursor',
      },
      colorscheme = {
        enable_preview = true,
      },
      find_files = {
        hidden = true,
      },
      git_branches = {
        theme = 'dropdown',
      },
      git_bcommits = {
        layout_config = {
          horizontal = {
            preview_width = 0.55,
          },
        },
      },
      git_commits = {
        layout_config = {
          horizontal = {
            preview_width = 0.55,
          },
        },
      },
      reloader = {
        theme = 'dropdown',
      },
    },
  }

  --- NOTE: this must be required after setting up telescope
  --- otherwise the result will be cached without the updates
  --- from the setup call
  local builtins = require 'telescope.builtin'

  local function project_files(opts)
    local ok = pcall(builtins.git_files, opts)
    if not ok then
      builtins.find_files(opts)
    end
  end

  local function nvim_config()
    builtins.find_files {
      prompt_title = '~ nvim config ~',
      cwd = vim.fn.stdpath 'config',
      file_ignore_patterns = { '.git/.*', 'dotbot/.*' },
    }
  end

  local function dotfiles()
    builtins.find_files {
      prompt_title = '~ dotfiles ~',
      cwd = vim.g.dotfiles,
    }
  end

  local function orgfiles()
    builtins.find_files {
      prompt_title = 'Org',
      cwd = vim.fn.expand '~/Dropbox/org/',
    }
  end

  local function frecency()
    local themes = require 'telescope.themes'
    telescope.extensions.frecency.frecency(themes.get_dropdown {
      default_text = ':CWD:',
      winblend = 10,
      border = true,
      previewer = false,
      shorten_path = false,
    })
  end

  local function installed_plugins()
    require('telescope.builtin').find_files {
      cwd = vim.fn.stdpath 'data' .. '/site/pack/packer',
    }
  end

  local function tmux_sessions()
    telescope.extensions.tmux.sessions {}
  end

  local function tmux_windows()
    telescope.extensions.tmux.windows {
      entry_format = '#S: #T',
    }
  end

  require('which-key').register {
    ['<c-p>'] = { project_files, 'telescope: find files' },
    ['<leader>f'] = {
      name = '+telescope',
      a = { builtins.builtin, 'builtins' },
      b = { builtins.current_buffer_fuzzy_find, 'current buffer fuzzy find' },
      d = { dotfiles, 'dotfiles' },
      f = { builtins.find_files, 'find files' },
      g = {
        name = '+git',
        c = { builtins.git_commits, 'commits' },
        b = { builtins.git_branches, 'branches' },
      },
      m = { builtins.man_pages, 'man pages' },
      h = { frecency, 'history' },
      n = { nvim_config, 'nvim config' },
      o = { builtins.buffers, 'buffers' },
      p = { installed_plugins, 'plugins' },
      O = { orgfiles, 'org files' },
      R = { builtins.reloader, 'module reloader' },
      r = { builtins.resume, 'resume last picker' },
      s = { builtins.live_grep, 'grep string' },
      t = {
        name = '+tmux',
        s = { tmux_sessions, 'sessions' },
        w = { tmux_windows, 'windows' },
      },
      ['?'] = { builtins.help_tags, 'help' },
    },
    ['<leader>c'] = {
      d = { builtins.lsp_workspace_diagnostics, 'telescope: workspace diagnostics' },
      s = { builtins.lsp_document_symbols, 'telescope: document symbols' },
      w = { builtins.lsp_dynamic_workspace_symbols, 'telescope: workspace symbols' },
    },
  }
end
