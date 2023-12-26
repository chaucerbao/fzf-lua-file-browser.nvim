-- Imports
local actions = require('fzf-lua.actions')
local path = require('fzf-lua.path')
local utils = require('fzf-lua-file-browser.utils')

-- Helpers
local entry_to_fullpath = utils.entry_to_fullpath
local input = utils.input

-- Actions
local create = {
  function(selected, opts)
    local fullpath = entry_to_fullpath(opts.cwd or vim.loop.cwd(), opts)
    local relpath = path.HOME_to_tilde(fullpath)

    local target_file =
      input('Create ' .. relpath .. (path.ends_with_separator(relpath) and '' or path.separator()), nil, 'file')
    if not target_file or #target_file == 0 then
      return false
    end

    local fullpath_to_target_file = entry_to_fullpath(target_file, opts)
    if vim.fn.filereadable(fullpath_to_target_file) > 0 then
      require('fzf_lua.utils').err('Already exists!')
      return false
    end

    if path.ends_with_separator(fullpath_to_target_file) then
      vim.loop.fs_mkdir(fullpath_to_target_file, 493) -- 0x755
    else
      local file_handler = vim.loop.fs_open(fullpath_to_target_file, 'w', 420) -- 0x644
      if file_handler then
        vim.loop.fs_close(file_handler)
      end
    end

    return true
  end,
  actions.resume,
}

local rename = {
  function(selected, opts)
    if #selected == 0 then
      return false
    end

    local fullpath_to_file = entry_to_fullpath(selected[1], opts)
    local relpath_to_file = path.HOME_to_tilde(fullpath_to_file)

    local target_file = input('Rename to ' .. path.parent(relpath_to_file), path.basename(relpath_to_file), 'file')
    if not target_file or #target_file == 0 then
      return false
    end

    local fullpath_to_target_file = entry_to_fullpath(target_file, opts)
    if vim.fn.filereadable(fullpath_to_target_file) == 0 or (input('Overwrite? [y/n] ') == 'y') then
      vim.loop.fs_rename(fullpath_to_file, fullpath_to_target_file)
    end

    return true
  end,
  actions.resume,
}

local copy = {
  function(selected, opts)
    if #selected == 0 then
      return false
    end

    local fullpath_to_file = entry_to_fullpath(selected[1], opts)
    local relpath_to_file = path.HOME_to_tilde(fullpath_to_file)

    local target_file = input('Copy to ', relpath_to_file, 'file')
    if not target_file or #target_file == 0 then
      return false
    end

    local fullpath_to_target_file = entry_to_fullpath(target_file, opts)
    if vim.fn.filereadable(fullpath_to_target_file) == 0 or (input('Overwrite? [y/n] ') == 'y') then
      vim.loop.fs_copyfile(fullpath_to_file, fullpath_to_target_file)
    end

    return true
  end,
  actions.resume,
}

local move = {
  function(selected, opts)
    if #selected == 0 then
      return false
    end

    local fullpath_to_file = entry_to_fullpath(selected[1], opts)
    local relpath_to_file = path.HOME_to_tilde(fullpath_to_file)

    local target_file = input('Move to ', relpath_to_file, 'file')
    if not target_file or #target_file == 0 then
      return false
    end

    local fullpath_to_target_file = entry_to_fullpath(target_file, opts)
    if vim.fn.filereadable(fullpath_to_target_file) == 0 or (input('Overwrite? [y/n] ') == 'y') then
      if vim.loop.fs_copyfile(fullpath_to_file, fullpath_to_target_file) then
        vim.loop.fs_unlink(fullpath_to_file)
      end
    end

    return true
  end,
  actions.resume,
}

local delete = {
  function(selected, opts)
    if #selected == 0 then
      return false
    end

    local msg
    if #selected > 1 then
      msg = 'Delete ' .. #selected .. ' entries?'
    else
      local fullpath_to_file = entry_to_fullpath(selected[1], opts)
      msg = 'Delete "'
        .. path.basename(fullpath_to_file)
        .. (path.ends_with_separator(fullpath_to_file) and path.separator() or '')
        .. '"?'
    end

    if input(msg .. ' [y/n] ') ~= 'y' then
      return false
    end

    for _, entry in ipairs(selected) do
      local fullpath_to_file = entry_to_fullpath(entry, opts)

      if vim.fn.isdirectory(fullpath_to_file) > 0 then
        vim.loop.fs_rmdir(fullpath_to_file)
      elseif vim.fn.filereadable(fullpath_to_file) > 0 then
        vim.loop.fs_unlink(fullpath_to_file)
      end
    end

    return true
  end,
  actions.resume,
}

return {
  create = create,
  rename = rename,
  copy = copy,
  move = move,
  delete = delete,
}
