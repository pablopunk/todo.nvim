local function get_todo_folder()
  local function get_closest_git_folder(path)
    if path == nil or path == "/" then
      return "~"
    end
    local git_path = path .. "/.git"
    local f = io.open(git_path, "r")
    if f ~= nil then
      io.close(f)
      return path .. "/.git"
    end
    return get_closest_git_folder(vim.fn.fnamemodify(path, ":h"))
  end
  return get_closest_git_folder(vim.fn.expand "%:p:h")
end

local buf, win

local function open_todo_window()
  buf = vim.api.nvim_create_buf(false, true)

  local width = vim.api.nvim_get_option "columns"
  local height = vim.api.nvim_get_option "lines"
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    border = "rounded",
  }

  win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_var(win, "float_title", "TODO.md")

  local repo_folder = get_todo_folder()
  local todo_file = repo_folder .. "/.TODO.md"

  -- setup buffer
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

  -- open file
  vim.api.nvim_command("silent edit" .. todo_file)
  vim.api.nvim_command "normal G" -- go to EOF

  -- setup keymaps
  local close_window_keymaps = { "q", "<esc>", "<c-c>" }
  for _, key in ipairs(close_window_keymaps) do
    vim.api.nvim_command("nnoremap <buffer> <silent> " .. key .. " :lua require('todo').close_todo_window()<cr>")
  end

  -- when buf loses focus, let's close it
  vim.api.nvim_command "autocmd BufLeave <buffer> lua require('todo').close_todo_window()"
end

local function is_window_invalid()
  return win == nil or not vim.api.nvim_win_is_valid(win)
end

local function close_todo_window()
  if is_window_invalid() then
    return
  end
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_command "silent w | silent bd" -- save and quit
  win = nil
  buf = nil
end

local is_window_open = function()
  return buf ~= nil and vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_win_is_valid(win)
end

local function toggle_todo_window()
  if is_window_open() then
    close_todo_window()
  else
    open_todo_window()
  end
end

return {
  toggle_todo_window = toggle_todo_window,
  open_todo_window = open_todo_window,
  close_todo_window = close_todo_window,
  setup = function()
    -- Create the custom command ":Todo"
    vim.api.nvim_command "command! TodoToggle :lua require('todo').toggle_todo_window()"
  end,
}
