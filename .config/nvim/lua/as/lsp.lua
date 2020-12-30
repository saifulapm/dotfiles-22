-----------------------------------------------------------------------------//
-- Native LSP config
-----------------------------------------------------------------------------//
local M = {}

local fn = vim.fn
local extend = vim.list_extend
local api = vim.api

local lspconfig = require "lspconfig"
local lsp_status = require "lsp-status"
local flutter = require "flutter-tools"

local autocommands = require "as.autocommands"
local utils = require "as.utils"

-----------------------------------------------------------------------------//
-- Highlights
-----------------------------------------------------------------------------//
function M.highlight()
  local highlights = {
    {"LspReferenceText", {link = "Visual"}},
    {"LspReferenceRead", {link = "Visual"}},
    {"LspDiagnosticsDefaultHint", {guifg = "#fab005"}},
    {"LspDiagnosticsDefaultError", {guifg = "#E06C75"}},
    {"LspDiagnosticsDefaultWarning", {guifg = "#ff922b"}},
    {"LspDiagnosticsDefaultInformation", {guifg = "#15aabf"}},
    {"LspDiagnosticsUnderlineError", {gui = "undercurl", guisp = "#E06C75"}},
    {"LspDiagnosticsUnderlineHint", {gui = "undercurl", guisp = "#fab005"}},
    {"LspDiagnosticsUnderlineWarning", {gui = "undercurl", guisp = "orange"}},
    {"LspDiagnosticsUnderlineInformation", {gui = "undercurl", guisp = "#15aabf"}}
  }
  for _, hl in pairs(highlights) do
    require("as.highlights").highlight(unpack(hl))
  end
end

-----------------------------------------------------------------------------//
-- Helpers
-----------------------------------------------------------------------------//
function _G.reload_lsp()
  vim.lsp.stop_client(vim.lsp.get_active_clients())
  vim.cmd [[edit]]
end

function _G.open_lsp_log()
  local path = vim.lsp.get_log_path()
  vim.cmd("edit " .. path)
end

vim.cmd [[command! ReloadLSP lua reload_lsp()]]
vim.cmd [[command! DebugLSP lua print(vim.inspect(vim.lsp.get_active_clients()))]]
vim.cmd [[command! LogLSP lua open_lsp_log()]]

function M.tagfunc(pattern, flags)
  if flags ~= "c" then
    return vim.NIL
  end
  local params = vim.lsp.util.make_position_params()
  local client_id_to_results, err =
    vim.lsp.buf_request_sync(0, "textDocument/definition", params, 500)
  assert(not err, vim.inspect(err))

  local results = {}
  for _, lsp_results in ipairs(client_id_to_results) do
    for _, location in ipairs(lsp_results.result or {}) do
      local start = location.range.start
      table.insert(
        results,
        {
          name = pattern,
          filename = vim.uri_to_fname(location.uri),
          cmd = string.format("call cursor(%d, %d)", start.line + 1, start.character + 1)
        }
      )
    end
  end
  return results
end
-----------------------------------------------------------------------------//
-- Autocommands
-----------------------------------------------------------------------------//

local function setup_autocommands(client)
  local commands = {
    LspCursorCommands = {
      {"CursorHold", "<buffer>", "lua vim.lsp.diagnostic.show_line_diagnostics()"}
    },
    LspHighlights = {{"VimEnter,ColorScheme", "*", "lua require('as.lsp').highlight()"}}
  }
  if client and client.resolved_capabilities.signature_help then
    extend(
      commands.LspCursorCommands,
      {{"CursorHoldI", "<buffer>", "lua vim.lsp.buf.signature_help()"}}
    )
  end
  if client and client.resolved_capabilities.document_highlight then
    extend(
      commands.LspCursorCommands,
      {
        {"CursorHold", "<buffer>", "lua vim.lsp.buf.document_highlight()"},
        {"CursorHoldI", "<buffer>", "lua vim.lsp.buf.document_highlight()"},
        {"CursorMoved", "<buffer>", "lua vim.lsp.buf.clear_references()"}
      }
    )
  end
  if client and client.resolved_capabilities.document_formatting then
    -- format on save
    commands.LspFormat = {{"BufWritePre", "<buffer>", "lua vim.lsp.buf.formatting_sync(nil, 1000)"}}
  end
  autocommands.create(commands)
end
-----------------------------------------------------------------------------//
-- Mappings
-----------------------------------------------------------------------------//

local function map(...)
  api.nvim_buf_set_keymap(0, ...)
end

local function setup_mappings(client)
  local opts = {nowait = true, noremap = true, silent = true}
  map("n", "[c", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
  map("n", "]c", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
  map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  map("n", "<c-]>", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
  if client.resolved_capabilities.hover then
    map("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
  end
  if client.resolved_capabilities.implementation then
    map("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
  end
  map("i", "<c-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
  map("n", "<leader>gd", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
  map("n", "gI", "<cmd>vim.lsp.buf.incoming_calls()<CR>", opts)
  map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
  map("n", "<leader>cs", "<cmd>lua vim.lsp.buf.document_symbol()<CR>", opts)
  map("n", "<leader>cw", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>", opts)
  map("n", "<leader>rf", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
  map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
  map("x", "<leader>a", "<cmd>'<'>lua vim.lsp.buf.range_code_action()<CR>", opts)
end
-----------------------------------------------------------------------------//
-- Signs
-----------------------------------------------------------------------------//
local signs = {
  {"LspDiagnosticsSignError", {text = "✗", texthl = "LspDiagnosticsSignError"}},
  {"LspDiagnosticsSignWarning", {text = "", texthl = "LspDiagnosticsSignWarning"}},
  {"LspDiagnosticsSignInformation", {text = "", texthl = "LspDiagnosticsSignInformation"}},
  {"LspDiagnosticsSignHint", {text = "", texthl = "LspDiagnosticsSignHint"}}
}

local function on_attach(client, bufnr)
  setup_autocommands(client)
  setup_mappings(client)

  if client.resolved_capabilities.goto_definition then
    api.nvim_buf_set_option(bufnr, "tagfunc", "v:lua.require('as.lsp').tagfunc")
  end
  lsp_status.on_attach(client)
end

function M.setup()
  M.highlight()

  for _, sign in pairs(signs) do
    fn.sign_define(unpack(sign))
  end

  -----------------------------------------------------------------------------//
  -- Setup plugins
  -----------------------------------------------------------------------------//
  flutter.setup {}

  lsp_status.config {
    kind_labels = vim.g.completion_customize_lsp_label,
    indicator_hint = "",
    indicator_info = "",
    indicator_errors = "✗",
    indicator_warnings = "",
    status_symbol = ""
  }
  lsp_status.register_progress()

  -----------------------------------------------------------------------------//
  -- Handler overrides
  -----------------------------------------------------------------------------//
  vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics,
    {
      underline = true,
      virtual_text = false,
      signs = true,
      update_in_insert = false
    }
  )

  vim.lsp.handlers["textDocument/formatting"] = function(err, _, result, _, bufnr)
    if err ~= nil or result == nil then
      return
    end
    if not vim.bo[bufnr].modified then
      local view = vim.fn.winsaveview()
      vim.lsp.util.apply_text_edits(result, bufnr)
      vim.fn.winrestview(view)
      if bufnr == vim.api.nvim_get_current_buf() then
        vim.cmd("noautocmd :update")
      end
    end
  end
  -----------------------------------------------------------------------------//
  -- Language servers
  -----------------------------------------------------------------------------//
  local function get_lua_runtime()
    local result = {
      -- This loads the `lua` files from nvim into the runtime.
      [fn.expand("$VIMRUNTIME/lua")] = true,
      [fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true
    }
    for _, path in pairs(api.nvim_list_runtime_paths()) do
      local lua_path = path .. "/lua"
      if fn.isdirectory(lua_path) > 0 then
        result[lua_path] = true
      end
    end
    return result
  end

  local prettier = {formatCommand = "prettier"}

  local servers = {
    rust_analyzer = {},
    vimls = {},
    gopls = {},
    flow = {},
    jsonls = {},
    html = {},
    tsserver = {},
    sumneko_lua = {
      settings = {
        Lua = {
          diagnostics = {
            globals = {"vim"},
            workspaceDelay = -1
          },
          completion = {keywordSnippet = "Both"},
          runtime = {
            version = "LuaJIT",
            path = vim.split(package.path, ";")
          },
          awakened = {cat = true},
          workspace = {
            maxPreload = 1000,
            preloadFileSize = 1000,
            library = get_lua_runtime()
          }
        }
      }
    },
    efm = {
      init_options = {documentFormatting = true},
      filetypes = {"yaml", "json", "html", "css", "markdown", "lua"},
      settings = {
        -- add ".lua-format" to root if using lua-format
        rootMarkers = {".git/"},
        languages = {
          yaml = {prettier},
          json = {prettier},
          html = {prettier},
          css = {prettier},
          markdown = {prettier},
          -- npm i -g lua-fmt
          -- 'lua-format -i -c ./.lua-format'
          lua = {
            {formatCommand = "luafmt --indent-count 2 --line-width 100 --stdin", formatStdin = true}
          }
        }
      }
    },
    dartls = {
      flags = {allow_incremental_sync = true},
      init_options = {
        closingLabels = true,
        outline = true,
        flutterOutline = true
      },
      on_attach = on_attach,
      handlers = {
        ["dart/textDocument/publishClosingLabels"] = flutter.closing_tags,
        ["dart/textDocument/publishOutline"] = flutter.outline
      }
    }
  }

  for server, config in pairs(servers) do
    config.on_attach = on_attach
    local status_capabilities = lsp_status.capabilities
    config.capabilities = utils.deep_merge(config.capabilities or {}, status_capabilities)
    lspconfig[server].setup(config)
  end
end

return M
