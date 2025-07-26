local M = {}

--- @param file_name string
--- @param lnum integer
--- @param col integer?
--- @param keeps boolean?
local function reopen_and_gotoline(file_name, lnum, col, keeps)
  local bufn = vim.api.nvim_get_current_buf()

  vim.cmd.edit{vim.fn.fnameescape(file_name), mods = { keepalt = true }}

  --- Deleting the buffer in BufNewFile might cause problems with other
  --- BufNewFile autocmds so defer the deletion of the buffer.
  if not keeps then vim.schedule(function() vim.api.nvim_buf_delete(bufn, {}) end) end

  lnum = math.min(math.max(1, lnum), vim.api.nvim_buf_line_count(0))
  vim.api.nvim_win_set_cursor(0, { lnum, col and col - 1 or 0 })

  if vim.fn.foldlevel(lnum) > 0 then
    vim.cmd.normal{'zv', bang = true }
  end
  vim.cmd.normal{'zz', bang = true }

  vim.cmd.filetype('detect')
end

--- Separate filename and line/column number.
--- Accepted formats:
---   - file.lua(10)
---   - file.lua(10:99)
---   - file.lua:10
---   - file.lua:10:99
--- @param name string
--- @return string file_name
--- @return integer? lnum
--- @return integer? col
local function process_name(name)
  --- @type string?, string
  local file_name, suffix = name:match('^([^:]+):([0-9:]+)$')
  if not file_name then
    --- @type string?, string
    file_name, suffix = name:match('^([^%(]+)%(([0-9:]+)%)$')
  end

  if not file_name then
    return name
  end

  if suffix:match('^%d+$') then
    return file_name, tonumber(suffix)
  end

  local line, col = suffix:match('^(%d+):(%d+)$')
  return file_name, tonumber(line), tonumber(col)
end

function M.gotoline()
  local file = vim.api.nvim_buf_get_name(0)

  if file == '' then
    return file
  end

  local file_name, line, col = process_name(file)

  if line then
    if vim.fn.filereadable(file_name) == 0 then
      return
    end
    reopen_and_gotoline(file_name, line, col)
  end

  return file_name
end

--- Go to a line specified under cursor.
--- @param keeps boolean?
function M.gotoline_at_cursor(keeps)
  --  get the text of the current line
  local current = vim.api.nvim_get_current_line()

  -- find the first instance of ": ", discard from that point
  local newCurrent = ''
  for i = 1, #current do
    if current:sub(i, i + 1) == ': ' then break end
    newCurrent = newCurrent .. current:sub(i, i)
  end

  local file_name, line, col = process_name(newCurrent)

  if line then
    if vim.fn.filereadable(file_name) == 0 then return end
    reopen_and_gotoline(file_name, line, col, keeps)
  end

  return file_name
end
return M
