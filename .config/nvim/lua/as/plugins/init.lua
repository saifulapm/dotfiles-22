local utils = require 'as.utils.plugins'

local conf = utils.conf
local use_local = utils.use_local
local packer_notify = utils.packer_notify

local fn = vim.fn
local fmt = string.format

local PACKER_COMPILED_PATH = fn.stdpath 'cache' .. '/packer/packer_compiled.lua'

-----------------------------------------------------------------------------//
-- Bootstrap Packer {{{3
-----------------------------------------------------------------------------//
utils.bootstrap_packer()
----------------------------------------------------------------------------- }}}1
-- cfilter plugin allows filter down an existing quickfix list
vim.cmd 'packadd! cfilter'

---@see: https://github.com/lewis6991/impatient.nvim/issues/35
as.safe_require 'impatient'

local packer = require 'packer'
--- NOTE "use" functions cannot call *upvalues* i.e. the functions
--- passed to setup or config etc. cannot reference aliased functions
--- or local variables
packer.startup {
  function(use, use_rocks)
    -- FIXME: this no longer loads the local plugin since the compiled file now
    -- loads packer.nvim so the local alias(local-packer) does not work
    use_local { 'wbthomason/packer.nvim', local_path = 'contributing', opt = true }
    -----------------------------------------------------------------------------//
    -- Core {{{3
    -----------------------------------------------------------------------------//
    use_rocks 'penlight'

    -- TODO: this fixes a bug in neovim core that prevents "CursorHold" from working
    -- hopefully one day when this issue is fixed this can be removed
    -- @see: https://github.com/neovim/neovim/issues/12587
    use 'antoinemadec/FixCursorHold.nvim'

    use {
      'ahmedkhalf/project.nvim',
      config = function()
        require('project_nvim').setup()
      end,
    }

    use {
      'nvim-telescope/telescope.nvim',
      cmd = 'Telescope',
      keys = { '<c-p>', '<leader>fo', '<leader>ff', '<leader>fs' },
      module_pattern = 'telescope.*',
      config = conf 'telescope',
      requires = {
        {
          'nvim-telescope/telescope-fzf-native.nvim',
          run = 'make',
          after = 'telescope.nvim',
          config = function()
            require('telescope').load_extension 'fzf'
          end,
        },
        {
          'nvim-telescope/telescope-frecency.nvim',
          after = 'telescope.nvim',
          requires = 'tami5/sqlite.lua',
        },
        {
          'nvim-telescope/telescope-smart-history.nvim',
          after = 'telescope.nvim',
          config = function()
            require('telescope').load_extension 'smart_history'
          end,
        },
      },
    }

    use 'kyazdani42/nvim-web-devicons'

    use { 'folke/which-key.nvim', config = conf 'whichkey' }

    use {
      'folke/trouble.nvim',
      keys = { '<leader>ld' },
      cmd = { 'TroubleToggle' },
      requires = 'nvim-web-devicons',
      setup = conf('trouble').setup,
      config = conf('trouble').config,
    }

    use {
      'rmagatti/auto-session',
      config = function()
        require('auto-session').setup {
          log_level = 'error',
          auto_session_root_dir = ('%s/session/auto/'):format(vim.fn.stdpath 'data'),
        }
      end,
    }

    -- NOTE: this and the plugin below it should never be active at the same time
    -- so they have inverse conditions
    use {
      'christoomey/vim-tmux-navigator',
      cond = function()
        return vim.env.TMUX ~= nil
      end,
      config = function()
        vim.g.tmux_navigator_no_mappings = 1
        as.nnoremap('<C-H>', '<cmd>TmuxNavigateLeft<cr>')
        as.nnoremap('<C-J>', '<cmd>TmuxNavigateDown<cr>')
        as.nnoremap('<C-K>', '<cmd>TmuxNavigateUp<cr>')
        as.nnoremap('<C-L>', '<cmd>TmuxNavigateRight<cr>')
        -- Disable tmux navigator when zooming the Vim pane
        vim.g.tmux_navigator_disable_when_zoomed = 1
        vim.g.tmux_navigator_preserve_zoom = 1
        vim.g.tmux_navigator_save_on_switch = 2
      end,
    }

    use {
      'knubie/vim-kitty-navigator',
      run = 'cp ./*.py ~/.config/kitty/',
      cond = function()
        return vim.env.TMUX == nil
      end,
    }

    use {
      'nvim-lua/plenary.nvim',
      config = function()
        as.augroup('PlenaryTests', {
          {
            event = 'BufEnter',
            pattern = { '*/personal/*/tests/*_spec.lua' },
            command = function()
              require('which-key').register({
                t = {
                  name = '+plenary',
                  f = { '<Plug>PlenaryTestFile', 'test file' },
                  d = {
                    "<cmd>PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal.vim'}<CR>",
                    'test directory',
                  },
                },
              }, {
                prefix = '<localleader>',
                buffer = 0,
              })
            end,
          },
        })
      end,
    }

    use { 'lukas-reineke/indent-blankline.nvim', config = conf 'indentline' }

    use {
      'nvim-neo-tree/neo-tree.nvim',
      branch = 'v2.x',
      keys = '<C-N>',
      cmd = 'NeoTree',
      config = conf 'neo-tree',
      requires = {
        'nvim-lua/plenary.nvim',
        'MunifTanjim/nui.nvim',
        'kyazdani42/nvim-web-devicons',
      },
    }
    -- }}}
    -----------------------------------------------------------------------------//
    -- LSP,Completion & Debugger {{{1
    -----------------------------------------------------------------------------//
    use { 'neovim/nvim-lspconfig', config = conf 'lspconfig' }
    use 'lukas-reineke/lsp-format.nvim'
    use {
      'williamboman/nvim-lsp-installer',
      requires = 'nvim-lspconfig',
      config = function()
        local lsp_installer_servers = require 'nvim-lsp-installer.servers'
        for name, _ in pairs(as.lsp.servers) do
          ---@type boolean, table|string
          local ok, server = lsp_installer_servers.get_server(name)
          if ok then
            if not server:is_installed() then
              server:install()
            end
          end
        end
      end,
    }

    use {
      'narutoxy/dim.lua',
      requires = { 'nvim-treesitter/nvim-treesitter', 'neovim/nvim-lspconfig' },
      config = function()
        require('dim').setup {
          disable_lsp_decorations = true,
        }
      end,
    }

    use {
      'jose-elias-alvarez/null-ls.nvim',
      requires = { 'nvim-lua/plenary.nvim' },
      config = conf 'null-ls',
    }

    use {
      'ray-x/lsp_signature.nvim',
      config = function()
        require('lsp_signature').setup {
          bind = true,
          fix_pos = false,
          auto_close_after = 15, -- close after 15 seconds
          hint_enable = false,
          handler_opts = { border = as.style.current.border },
        }
      end,
    }

    use {
      'hrsh7th/nvim-cmp',
      module = 'cmp',
      event = 'InsertEnter',
      requires = {
        { 'hrsh7th/cmp-nvim-lsp', after = 'nvim-lspconfig' },
        { 'hrsh7th/cmp-nvim-lsp-document-symbol', after = 'nvim-cmp' },
        { 'hrsh7th/cmp-cmdline', after = 'nvim-cmp' },
        { 'f3fora/cmp-spell', after = 'nvim-cmp' },
        { 'hrsh7th/cmp-path', after = 'nvim-cmp' },
        { 'hrsh7th/cmp-buffer', after = 'nvim-cmp' },
        {
          'petertriho/cmp-git',
          opt = true,
          -- after = 'nvim-cmp',
          config = function()
            require('cmp_git').setup { filetypes = { 'gitcommit', 'NeogitCommitMessage' } }
          end,
        },
        { 'saadparwaiz1/cmp_luasnip', after = 'nvim-cmp' },
      },
      config = conf 'cmp',
    }

    use {
      'AckslD/nvim-neoclip.lua',
      config = function()
        require('neoclip').setup {
          enable_persistent_history = true,
          keys = {
            telescope = {
              i = { select = '<c-p>', paste = '<CR>', paste_behind = '<c-k>' },
              n = { select = 'p', paste = '<CR>', paste_behind = 'P' },
            },
          },
        }
        local function clip()
          require('telescope').extensions.neoclip.default(
            require('telescope.themes').get_dropdown()
          )
        end
        require('which-key').register {
          ['<localleader>p'] = { clip, 'neoclip: open yank history' },
        }
      end,
    }

    -- FIXME: https://github.com/L3MON4D3/LuaSnip/issues/129
    -- causes formatting bugs on save when updateevents are TextChanged{I}
    use {
      'L3MON4D3/LuaSnip',
      event = 'InsertEnter',
      module = 'luasnip',
      requires = 'rafamadriz/friendly-snippets',
      config = conf 'luasnip',
    }
    -- }}}
    -----------------------------------------------------------------------------//
    -- Testing and Debugging {{{1
    -----------------------------------------------------------------------------//
    use {
      'vim-test/vim-test',
      cmd = { 'Test*' },
      keys = { '<localleader>tf', '<localleader>tn', '<localleader>ts' },
      setup = function()
        require('which-key').register({
          t = {
            name = '+vim-test',
            f = 'test: file',
            n = 'test: nearest',
            s = 'test: suite',
          },
        }, {
          prefix = '<localleader>',
        })
      end,
      config = function()
        vim.cmd [[
          function! ToggleTermStrategy(cmd) abort
            call luaeval("require('toggleterm').exec(_A[1])", [a:cmd])
          endfunction

          let g:test#custom_strategies = {'toggleterm': function('ToggleTermStrategy')}
        ]]
        vim.g['test#strategy'] = 'toggleterm'
        as.nnoremap('<localleader>tf', '<cmd>TestFile<CR>')
        as.nnoremap('<localleader>tn', '<cmd>TestNearest<CR>')
        as.nnoremap('<localleader>ts', '<cmd>TestSuite<CR>')
      end,
    }

    use {
      'rcarriga/vim-ultest',
      cmd = 'Ultest',
      wants = 'vim-test',
      event = { 'BufEnter *_test.*,*_spec.*' },
      requires = { 'vim-test' },
      run = ':UpdateRemotePlugins',
      config = function()
        local test_patterns = { '*_test.*', '*_spec.*' }
        as.augroup('UltestTests', {
          {
            event = { 'BufWritePost' },
            pattern = test_patterns,
            command = 'UltestNearest',
          },
        })
        as.nmap(']t', '<Plug>(ultest-next-fail)', {
          label = 'ultest: next failure',
          buffer = 0,
        })
        as.nmap('[t', '<Plug>(ultest-prev-fail)', {
          label = 'ultest: previous failure',
          buffer = 0,
        })
      end,
    }

    use {
      'mfussenegger/nvim-dap',
      setup = conf('dap').setup,
      config = conf('dap').config,
      requires = {
        {
          'rcarriga/nvim-dap-ui',
          after = 'nvim-dap',
          config = conf 'dapui',
        },
        {
          'theHamsta/nvim-dap-virtual-text',
          after = 'nvim-dap',
          config = function()
            require('nvim-dap-virtual-text').setup { all_frames = true }
          end,
        },
      },
    }

    use { 'jbyuki/one-small-step-for-vimkind', requires = 'nvim-dap' }
    use 'folke/lua-dev.nvim'

    --}}}
    -----------------------------------------------------------------------------//
    -- UI
    -----------------------------------------------------------------------------//
    use {
      'petertriho/nvim-scrollbar',
      config = function()
        require('scrollbar').setup {
          handle = {
            color = require('as.highlights').get_hl('PmenuSbar', 'bg'),
          },
          -- NOTE: If telescope is not explicitly excluded this garbles input into its prompt buffer
          excluded_buftypes = { 'nofile', 'terminal', 'prompt' },
          excluded_filetypes = { 'packer', 'TelescopePrompt', 'NvimTree' },
        }
      end,
    }

    use {
      'stevearc/dressing.nvim',
      -- NOTE: Defer loading till telescope is loaded
      -- this implicitly loads telescope so needs to be delayed
      after = 'telescope.nvim',
      config = function()
        require('as.highlights').plugin(
          'dressing',
          { FloatTitle = { inherit = 'Visual', bold = true } }
        )
        require('dressing').setup {
          input = {
            insert_only = false,
            winblend = 2,
            border = as.style.current.border,
          },
          select = {
            telescope = require('telescope.themes').get_cursor {
              layout_config = {
                -- NOTE: the limit is half the max lines because this is the cursor theme so
                -- unless the cursor is at the top or bottom it realistically most often will
                -- only have half the screen available
                height = function(self, _, max_lines)
                  local results = #self.finder.results
                  local PADDING = 4 -- this represents the size of the telescope window
                  local LIMIT = math.floor(max_lines / 2)
                  return (results <= (LIMIT - PADDING) and results + PADDING or LIMIT)
                end,
              },
            },
          },
        }
      end,
    }

    --------------------------------------------------------------------------------
    -- Utilities {{{1
    --------------------------------------------------------------------------------
    use 'nanotee/luv-vimdocs'
    use 'milisims/nvim-luaref'

    use {
      'folke/todo-comments.nvim',
      requires = 'nvim-lua/plenary.nvim',
      config = function()
        -- this plugin is not safe to reload
        if vim.g.packer_compiled_loaded then
          return
        end
        require('todo-comments').setup {
          highlight = {
            exclude = { 'org', 'orgagenda', 'vimwiki', 'markdown' },
          },
        }
        as.nnoremap('<leader>lt', '<Cmd>TodoTrouble<CR>', 'trouble: todos')
      end,
    }

    use {
      'github/copilot.vim',
      config = function()
        vim.g.copilot_no_tab_map = true
        as.imap('<Plug>(vimrc:copilot-dummy-map)', "copilot#Accept('<Tab>')", { expr = true })
        as.inoremap('<M-]>', '<Plug>(copilot-next)')
        as.inoremap('<M-[>', '<Plug>(copilot-previous)')
        as.inoremap('<C-\\>', '<Cmd>vertical Copilot panel<CR>')

        vim.g.copilot_filetypes = {
          ['*'] = true,
          gitcommit = false,
          NeogitCommitMessage = false,
          ['neo-tree-popup'] = false,
        }
        require('as.highlights').plugin('copilot', { CopilotSuggestion = { link = 'Comment' } })
      end,
    }

    use {
      'simeji/winresizer',
      setup = function()
        vim.g.winresizer_start_key = '<leader>w'
      end,
    }

    use {
      'klen/nvim-config-local',
      config = function()
        require('config-local').setup {
          config_files = { '.localrc.lua', '.vimrc', '.vimrc.lua' },
        }
      end,
    }

    -- prevent select and visual mode from overwriting the clipboard
    use {
      'kevinhwang91/nvim-hclipboard',
      event = 'InsertCharPre',
      config = function()
        require('hclipboard').start()
      end,
    }

    use { 'chentau/marks.nvim', config = conf 'marks' }

    use { 'monaqa/dial.nvim', config = conf 'dial' }

    use {
      'jghauser/fold-cycle.nvim',
      config = function()
        require('fold-cycle').setup()
        as.nnoremap('<BS>', function()
          require('fold-cycle').open()
        end)
      end,
    }

    use {
      'rainbowhxch/beacon.nvim',
      config = function()
        require('beacon').setup {
          ignore_buffers = { 'terminal', 'nofile' },
          ignore_filetypes = {
            'neo-tree',
            'qf',
            'NeogitCommitMessage',
            'NeogitStatus',
            'packer',
            'trouble',
          },
        }
      end,
    }
    use {
      'windwp/nvim-autopairs',
      after = 'nvim-cmp',
      config = function()
        require('nvim-autopairs').setup {
          close_triple_quotes = true,
          check_ts = true,
          ts_config = {
            lua = { 'string' },
            dart = { 'string' },
            javascript = { 'template_string' },
          },
          fast_wrap = {
            map = '<c-e>',
          },
        }
      end,
    }
    use {
      'karb94/neoscroll.nvim',
      config = function()
        require('neoscroll').setup {
          mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', 'zt', 'zz', 'zb' },
          stop_eof = false,
          hide_cursor = true,
        }
      end,
    }
    use {
      'mg979/vim-visual-multi',
      config = function()
        vim.g.VM_highlight_matches = 'underline'
        vim.g.VM_theme = 'codedark'
        vim.g.VM_maps = {
          ['Find Under'] = '<C-e>',
          ['Find Subword Under'] = '<C-e>',
          ['Select Cursor Down'] = '\\j',
          ['Select Cursor Up'] = '\\k',
        }
      end,
    }
    use {
      'itchyny/vim-highlighturl',
      config = function()
        vim.g.highlighturl_guifg = require('as.highlights').get_hl('Keyword', 'fg')
      end,
    }

    use {
      'danymat/neogen',
      setup = function()
        require('which-key').register {
          ['<localleader>nc'] = 'comment: generate',
        }
      end,
      keys = { '<localleader>nc' },
      requires = 'nvim-treesitter/nvim-treesitter',
      config = function()
        require('neogen').setup { snippet_engine = 'luasnip' }
        as.nnoremap('<localleader>nc', require('neogen').generate, 'comment: generate')
      end,
    }

    use {
      'j-hui/fidget.nvim',
      local_path = 'contributing',
      config = function()
        require('fidget').setup {
          text = {
            spinner = 'moon',
          },
          window = {
            blend = 0,
          },
        }
      end,
    }

    -- TODO: causes blocking output in headless mode
    use { 'rcarriga/nvim-notify', cond = utils.not_headless, config = conf 'notify' }

    use {
      'mbbill/undotree',
      cmd = 'UndotreeToggle',
      keys = '<leader>u',
      setup = function()
        require('which-key').register {
          ['<leader>u'] = 'undotree: toggle',
        }
      end,
      config = function()
        vim.g.undotree_TreeNodeShape = '◦' -- Alternative: '◉'
        vim.g.undotree_SetFocusWhenToggle = 1
        as.nnoremap('<leader>u', '<cmd>UndotreeToggle<CR>')
      end,
    }

    use {
      'iamcco/markdown-preview.nvim',
      run = 'cd app && yarn install',
      ft = { 'markdown' },
      config = function()
        vim.g.mkdp_auto_start = 0
        vim.g.mkdp_auto_close = 1
      end,
    }

    use {
      'norcalli/nvim-colorizer.lua',
      config = function()
        require('colorizer').setup({ '*' }, {
          RGB = false,
          mode = 'background',
        })
      end,
    }
    use {
      'moll/vim-bbye',
      config = function()
        as.nnoremap('<leader>qq', '<Cmd>Bwipeout<CR>')
      end,
    }
    -----------------------------------------------------------------------------//
    -- Quickfix
    -----------------------------------------------------------------------------//
    use {
      'https://gitlab.com/yorickpeterse/nvim-pqf',
      event = 'BufReadPre',
      config = function()
        require('as.highlights').plugin('pqf', { qfPosition = { link = 'Tag' } })
        require('pqf').setup {}
      end,
    }

    use {
      'kevinhwang91/nvim-bqf',
      ft = 'qf',
      config = function()
        require('as.highlights').plugin('bqf', { BqfPreviewBorder = { foreground = 'Gray' } })
      end,
    }
    --------------------------------------------------------------------------------
    -- Knowledge and task management {{{1
    --------------------------------------------------------------------------------
    use {
      'vimwiki/vimwiki',
      branch = 'dev',
      keys = { '<leader>ww', '<leader>wt', '<leader>wi' },
      event = { 'BufEnter *.wiki' },
      setup = conf('vimwiki').setup,
      config = conf('vimwiki').config,
    }

    use {
      'vhyrro/neorg',
      -- tag = '*', FIXME: add tag once neorg reaches 0.1
      requires = { 'vhyrro/neorg-telescope' },
      config = conf 'neorg',
    }

    use {
      'lukas-reineke/headlines.nvim',
      setup = function()
        -- https://observablehq.com/@d3/color-schemes?collection=@d3/d3-scale-chromatic
        -- NOTE: this must be set in the setup function or it will crash nvim...
        require('as.highlights').plugin('Headlines', {
          Headline1 = { background = '#003c30', foreground = 'White' },
          Headline2 = { background = '#00441b', foreground = 'White' },
          Headline3 = { background = '#084081', foreground = 'White' },
          Dash = { background = '#0b60a1', bold = true },
        })
      end,
      config = function()
        require('headlines').setup {
          markdown = {
            headline_highlights = { 'Headline1', 'Headline2', 'Headline3' },
          },
        }
      end,
    }
    -- }}}
    --------------------------------------------------------------------------------
    -- Profiling & Startup {{{1
    --------------------------------------------------------------------------------
    -- TODO: this plugin will be redundant once https://github.com/neovim/neovim/pull/15436 is merged
    use 'lewis6991/impatient.nvim'
    use {
      'dstein64/vim-startuptime',
      cmd = 'StartupTime',
      config = function()
        vim.g.startuptime_tries = 15
        vim.g.startuptime_exe_args = { '+let g:auto_session_enabled = 0' }
      end,
    }
    -- }}}
    --------------------------------------------------------------------------------
    -- TPOPE {{{1
    --------------------------------------------------------------------------------
    use 'tpope/vim-eunuch'
    use 'tpope/vim-sleuth'
    use 'tpope/vim-repeat'
    use {
      'tpope/vim-abolish',
      config = function()
        local opts = { silent = false }
        as.nnoremap('<localleader>[', ':S/<C-R><C-W>//<LEFT>', opts)
        as.nnoremap('<localleader>]', ':%S/<C-r><C-w>//c<left><left>', opts)
        as.xnoremap('<localleader>[', [["zy:%S/<C-r><C-o>"//c<left><left>]], opts)
      end,
    }
    -- sets searchable path for filetypes like go so 'gf' works
    use 'tpope/vim-apathy'
    use { 'tpope/vim-projectionist', config = conf 'vim-projectionist' }
    use {
      'tpope/vim-surround',
      config = function()
        as.xmap('s', '<Plug>VSurround')
        as.xmap('s', '<Plug>VSurround')
      end,
    }
    -- }}}
    -----------------------------------------------------------------------------//
    -- Filetype Plugins {{{1
    -----------------------------------------------------------------------------//
    use_local {
      'akinsho/flutter-tools.nvim',
      requires = { 'nvim-dap', 'plenary.nvim' },
      local_path = 'personal',
      config = conf 'flutter-tools',
    }

    use {
      'ray-x/go.nvim',
      ft = 'go',
      config = function()
        local path = require 'nvim-lsp-installer.path'
        local install_root_dir = path.concat { vim.fn.stdpath 'data', 'lsp_servers' }
        require('go').setup {
          gopls_cmd = { install_root_dir .. '/go/gopls' },
          max_line_len = 100,
          goimport = 'goimports',
          lsp_cfg = true,
          lsp_gofumpt = true,
          lsp_on_attach = as.lsp.on_attach,
          lsp_diag_virtual_text = false,
          dap_debug_keymap = false,
        }
        as.augroup('Golang', {
          {
            event = { 'BufWritePre' },
            pattern = { '*.go' },
            command = 'silent! lua require("go.format").goimport()',
          },
        })
      end,
    }

    use 'dart-lang/dart-vim-plugin'
    use 'mtdl9/vim-log-highlighting'
    use 'fladson/vim-kitty'
    use {
      'SmiteshP/nvim-gps',
      requires = 'nvim-treesitter/nvim-treesitter',
      config = function()
        require('nvim-gps').setup {}
      end,
    }
    -- }}}
    --------------------------------------------------------------------------------
    -- Syntax {{{1
    --------------------------------------------------------------------------------
    use {
      'nvim-treesitter/nvim-treesitter',
      run = ':TSUpdate',
      config = conf 'treesitter',
      local_path = 'contributing',
      wants = { 'null-ls.nvim', 'lua-dev.nvim' },
      requires = {
        { 'p00f/nvim-ts-rainbow', after = 'nvim-treesitter' },
        { 'nvim-treesitter/nvim-treesitter-textobjects', after = 'nvim-treesitter' },
        {
          'nvim-treesitter/playground',
          keys = '<leader>E',
          cmd = { 'TSPlaygroundToggle', 'TSHighlightCapturesUnderCursor' },
          setup = function()
            require('which-key').register { ['<leader>E'] = 'treesitter: highlight cursor group' }
          end,
          config = function()
            as.nnoremap('<leader>E', '<Cmd>TSHighlightCapturesUnderCursor<CR>')
          end,
        },
      },
    }

    -- Use <Tab> to escape from pairs such as ""|''|() etc.
    use {
      'abecodes/tabout.nvim',
      wants = { 'nvim-treesitter' },
      after = { 'nvim-cmp' },
      config = function()
        require('tabout').setup {
          completion = false,
          ignore_beginning = false,
        }
      end,
    }

    use {
      'lewis6991/spellsitter.nvim',
      config = function()
        require('spellsitter').setup {
          enable = true,
        }
      end,
    }
    ---}}}
    --------------------------------------------------------------------------------
    -- Git {{{1
    --------------------------------------------------------------------------------
    use {
      'ruifm/gitlinker.nvim',
      requires = 'plenary.nvim',
      keys = { '<localleader>gu', '<localleader>go' },
      setup = function()
        require('which-key').register(
          { gu = 'gitlinker: get line url', go = 'gitlinker: open repo url' },
          { prefix = '<localleader>' }
        )
      end,
      config = function()
        local linker = require 'gitlinker'
        linker.setup { mappings = '<localleader>gu' }
        as.nnoremap('<localleader>go', function()
          linker.get_repo_url { action_callback = require('gitlinker.actions').open_in_browser }
        end)
      end,
    }

    use {
      'pwntester/octo.nvim',
      requires = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
        'kyazdani42/nvim-web-devicons',
      },
      cmd = 'Octo',
      keys = { '<leader>Oli', '<leader>Olp' },
      config = conf 'octo',
    }

    use { 'lewis6991/gitsigns.nvim', config = conf 'gitsigns' }

    use {
      'TimUntersberger/neogit',
      cmd = 'Neogit',
      keys = { '<localleader>gs', '<localleader>gl', '<localleader>gp' },
      requires = 'plenary.nvim',
      setup = conf('neogit').setup,
      config = conf('neogit').config,
    }

    use {
      'sindrets/diffview.nvim',
      cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
      module = 'diffview',
      keys = '<localleader>gd',
      setup = function()
        require('which-key').register { ['<localleader>gd'] = 'diffview: diff HEAD' }
      end,
      config = function()
        as.nnoremap('<localleader>gd', '<Cmd>DiffviewOpen<CR>')
        require('diffview').setup {
          enhanced_diff_hl = true,
          key_bindings = {
            file_panel = { q = '<Cmd>DiffviewClose<CR>' },
            view = { q = '<Cmd>DiffviewClose<CR>' },
          },
        }
      end,
    }

    use {
      'rlch/github-notifications.nvim',
      -- don't load this plugin if the gh cli is not installed
      cond = function()
        return as.executable 'gh'
      end,
      requires = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
    }
    ---}}}
    --------------------------------------------------------------------------------
    -- Text Objects {{{1
    --------------------------------------------------------------------------------
    use {
      'AckslD/nvim-trevJ.lua',
      module = 'trevj',
      setup = function()
        as.nnoremap('gS', function()
          require('trevj').format_at_cursor()
        end, { label = 'splitjoin: split' })
      end,
      config = function()
        require('trevj').setup()
      end,
    }

    use { 'Matt-A-Bennett/vim-surround-funk', config = conf 'surround-funk' }

    use 'chaoren/vim-wordmotion'

    use {
      'numToStr/Comment.nvim',
      config = function()
        require('Comment').setup()
      end,
    }

    use {
      'gbprod/substitute.nvim',
      config = function()
        require('substitute').setup()
        as.nnoremap('S', function()
          require('substitute').operator()
        end)
        as.xnoremap('S', function()
          require('substitute').visual()
        end)
        as.nnoremap('X', function()
          require('substitute.exchange').operator()
        end)
        as.xnoremap('X', function()
          require('substitute.exchange').visual()
        end)
        as.nnoremap('Xc', function()
          require('substitute.exchange').cancel()
        end)
      end,
    }

    use 'wellle/targets.vim'
    use {
      'kana/vim-textobj-user',
      requires = {
        'kana/vim-operator-user',
        {
          'glts/vim-textobj-comment',
          config = function()
            vim.g.textobj_comment_no_default_key_mappings = 1
            as.xmap('ax', '<Plug>(textobj-comment-a)')
            as.omap('ax', '<Plug>(textobj-comment-a)')
            as.xmap('ix', '<Plug>(textobj-comment-i)')
            as.omap('ix', '<Plug>(textobj-comment-i)')
          end,
        },
      },
    }
    -- }}}
    --------------------------------------------------------------------------------
    -- Search Tools {{{1
    --------------------------------------------------------------------------------
    use { 'phaazon/hop.nvim', keys = { { 'n', 's' }, 'f', 'F' }, config = conf 'hop' }

    -- }}}
    --------------------------------------------------------------------------------
    -- Themes  {{{1
    --------------------------------------------------------------------------------
    use {
      'NTBBloodbath/doom-one.nvim',
      config = function()
        require('doom-one').setup {
          pumblend = {
            enable = true,
            transparency_amount = 3,
          },
        }
      end,
    }
    -- }}}
    ---------------------------------------------------------------------------------
    -- Dev plugins  {{{1
    ---------------------------------------------------------------------------------
    use { 'rafcamlet/nvim-luapad', cmd = 'Luapad' }
    -- }}}
    ---------------------------------------------------------------------------------
    -- Personal plugins {{{1
    -----------------------------------------------------------------------------//
    use_local {
      'akinsho/pubspec-assist.nvim',
      local_path = 'personal',
      rocks = {
        {
          'lyaml',
          server = 'http://rocks.moonscript.org',
          env = { YAML_DIR = '/opt/homebrew/Cellar/libyaml/0.2.5/' },
        },
      },
      config = function()
        require('pubspec-assist').setup()
      end,
    }

    use_local {
      'akinsho/toggleterm.nvim',
      local_path = 'personal',
      config = conf 'toggleterm',
    }

    use_local {
      'akinsho/bufferline.nvim',
      config = conf 'bufferline',
      local_path = 'personal',
      requires = 'nvim-web-devicons',
    }

    use_local {
      'akinsho/git-conflict.nvim',
      local_path = 'personal',
      config = function()
        require('git-conflict').setup {
          disable_diagnostics = true,
        }
      end,
    }
    --}}}
    ---------------------------------------------------------------------------------
  end,
  log = { level = 'info' },
  config = {
    compile_path = PACKER_COMPILED_PATH,
    display = {
      prompt_border = as.style.current.border,
      open_cmd = 'silent topleft 65vnew',
    },
    git = {
      clone_timeout = 240,
    },
    profile = {
      enable = true,
      threshold = 1,
    },
  },
}

as.command('PackerCompiledEdit', function()
  vim.cmd(fmt('edit %s', PACKER_COMPILED_PATH))
end)

as.command('PackerCompiledDelete', function()
  vim.fn.delete(PACKER_COMPILED_PATH)
  packer_notify(fmt('Deleted %s', PACKER_COMPILED_PATH))
end)

if not vim.g.packer_compiled_loaded and vim.loop.fs_stat(PACKER_COMPILED_PATH) then
  as.source(PACKER_COMPILED_PATH)
  vim.g.packer_compiled_loaded = true
end

as.augroup('PackerSetupInit', {
  {
    event = 'BufWritePost',
    pattern = { '*/as/plugins/*.lua' },
    description = 'Packer setup and reload',
    command = function()
      as.invalidate('as.plugins', true)
      packer.compile()
    end,
  },
  --- Open a repository from an authorname/repository string
  --- e.g. 'akinso/example-repo'
  {
    event = 'BufEnter',
    buffer = 0,
    command = function()
      as.nnoremap('gf', function()
        local repo = fn.expand '<cfile>'
        if not repo or #vim.split(repo, '/') ~= 2 then
          return vim.cmd 'norm! gf'
        end
        local url = fmt('https://www.github.com/%s', repo)
        fn.jobstart('open ' .. url)
        vim.notify(fmt('Opening %s at %s', repo, url))
      end)
    end,
  },
  {
    event = 'User',
    pattern = 'PackerCompileDone',
    description = 'Inform me that packer has finished compiling',
    command = function()
      vim.notify('Packer compile complete', nil, { title = 'Packer' })
    end,
  },
})

as.nnoremap('<leader>ps', [[<Cmd>PackerSync<CR>]])
as.nnoremap('<leader>pc', [[<Cmd>PackerClean<CR>]])

-- vim:foldmethod=marker
