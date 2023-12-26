-- Imports
local fzf_lua = require('fzf-lua')
local actions = require('fzf-lua-file-browser.actions')
local utils = require('fzf-lua-file-browser.utils')

-- Helpers
local entry_to_fullpath = utils.entry_to_fullpath

local function browse(opts)
  opts = opts or {}

  if opts.prompt == nil then
    opts.prompt = 'Browse❯ '
  end

  opts.fn_transform = function(entry)
    local fullpath = entry_to_fullpath(entry, opts)

    if vim.fn.isdirectory(fullpath) > 0 then
      entry = fzf_lua.utils.ansi_codes.magenta(entry) .. '/'
    end

    return fzf_lua.make_entry.file(entry, { file_icons = true, color_icons = true })
  end

  opts.actions = {
    ['default'] = function(selected)
      local fullpath = entry_to_fullpath(selected[1], opts)

      if vim.fn.isdirectory(fullpath) > 0 then
        browse(vim.tbl_deep_extend('force', opts, { cwd = fullpath }))
      elseif vim.fn.filereadable(fullpath) > 0 then
        fzf_lua.actions.file_edit(selected, opts)
      end
    end,

    ['ctrl-g'] = function()
      local fullpath = entry_to_fullpath(opts.cwd or vim.loop.cwd(), opts)
      local parent = fzf_lua.path.parent(fullpath)

      if vim.fn.isdirectory(parent) > 0 then
        browse(vim.tbl_deep_extend('force', opts, { cwd = parent }))
      else
        fzf_lua.actions.resume()
      end
    end,

    ['alt-c'] = actions.create,
    ['alt-r'] = actions.rename,
    ['alt-y'] = actions.copy,
    ['alt-m'] = actions.move,
    ['alt-d'] = actions.delete,
  }

  return fzf_lua.fzf_exec('ls', opts)
end

return { browse = browse, actions = actions }
