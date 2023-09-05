local TodoWindow = {}
TodoWindow.__index = TodoWindow
function TodoWindow.new()
  local self = setmetatable({}, TodoWindow)
  self.buf = nil
  self.win = nil
  return self
end
function TodoWindow:get_todo_folder()
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
local import_plugin_and_close_window = "lua require('todo').close_todo_window()"
function TodoWindow:open_todo_window()
  self.buf = vim.api.nvim_create_buf(false, true)
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
  self.win = vim.api.nvim_open_win(self.buf, true, opts)
  vim.api.nvim_win_set_var(self.win, "float_title", "TODO.md")
  local repo_folder = self:get_todo_folder()
  local todo_file = repo_folder .. "/.TODO.md"
  -- setup buffer
  vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
  vim.api.nvim_buf_set_option(self.buf, "filetype", "markdown")
  -- open file
  vim.api.nvim_command("silent edit" .. todo_file)
  vim.api.nvim_command "normal G" -- go to EOF
  -- setup keymaps
  local close_window_keymaps = { "q", "<esc>", "<c-c>" }
  for _, key in ipairs(close_window_keymaps) do
    vim.api.nvim_command("nnoremap <buffer> <silent> " .. key .. " :" .. import_plugin_and_close_window .. "<cr>")
  end
  -- when buf loses focus, let's close it
  vim.api.nvim_command("autocmd BufLeave <buffer> " .. import_plugin_and_close_window)
end
function TodoWindow:is_window_invalid()
  return self.win == nil or not vim.api.nvim_win_is_valid(self.win)
end
function TodoWindow:close_todo_window()
  if self:is_window_invalid() then
    return
  end
  vim.api.nvim_set_current_win(self.win)
  vim.api.nvim_command "silent w | silent bd" -- save and quit
  self.win = nil
  self.buf = nil
end
function TodoWindow:is_window_open()
  return self.buf ~= nil and vim.api.nvim_buf_is_loaded(self.buf) and vim.api.nvim_win_is_valid(self.win)
end
function TodoWindow:toggle_todo_window()
  if self:is_window_open() then
    self:close_todo_window()
  else
    self:open_todo_window()
  end
end
local todo_window = TodoWindow.new()
return {
  toggle_todo_window = function()
    todo_window:toggle_todo_window()
  end,
  close_todo_window = function()
    todo_window:close_todo_window()
  end,
  setup = function()
    -- Create the custom command ":Todo"
    vim.api.nvim_command "command! TodoToggle :lua require('todo').toggle_todo_window()"
  end,
}
