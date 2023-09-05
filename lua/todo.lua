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

local close_window_vim_cmd = "lua require('todo').close_todo_window()"

function TodoWindow:create_window()
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
    title = "todo.nvim",
    title_pos = "center",
  }
  self.win = vim.api.nvim_open_win(self.buf, true, opts)
end

function TodoWindow:destroy_window()
  vim.api.nvim_set_current_win(self.win)
  vim.api.nvim_command "silent w | silent bd" -- save and quit
  self.win = nil
end

function TodoWindow:destroy_buffer()
  self.buf = nil
end

function TodoWindow:create_buffer()
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(self.buf, "modifiable", true)
  vim.api.nvim_buf_set_option(self.buf, "filetype", "markdown")
end

function TodoWindow:open_file()
  local repo_folder = self:get_todo_folder()
  local todo_file = repo_folder .. "/.TODO.md"
  vim.api.nvim_command("silent edit" .. todo_file)
  vim.api.nvim_command "normal G" -- go to EOF
end

function TodoWindow:setup_keymaps()
  local close_window_keymaps = { "q", "<esc>", "<c-c>" }
  for _, key in ipairs(close_window_keymaps) do
    vim.api.nvim_command("nnoremap <buffer> <silent> " .. key .. " :" .. close_window_vim_cmd .. "<cr>")
  end
end

function TodoWindow:setup_autocmds()
  vim.api.nvim_command("autocmd BufLeave <buffer> " .. close_window_vim_cmd)
end

function TodoWindow:open_todo_window()
  self:create_buffer()
  self:create_window()
  self:open_file()
  self:setup_keymaps()
  self:setup_autocmds()
end

function TodoWindow:is_window_invalid()
  return self.win == nil or not vim.api.nvim_win_is_valid(self.win)
end

function TodoWindow:close_todo_window()
  if self:is_window_invalid() then
    return
  end
  self:destroy_window()
  self:destroy_buffer()
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
    vim.api.nvim_command "command! TodoToggle :lua require('todo').toggle_todo_window()"
  end,
}
