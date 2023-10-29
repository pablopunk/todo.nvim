local TodoWindow = {}
TodoWindow.__index = TodoWindow

function TodoWindow.new()
  local self = setmetatable({}, TodoWindow)
  self.buf = nil
  self.win = nil
  self.todo_folder = nil
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
  local width = vim.api.nvim_get_option_value("columns", {})
  local height = vim.api.nvim_get_option_value("lines", {})
  local win_height = math.ceil(height * 0.5 - 4)
  local win_width = math.ceil(width * 0.5)
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
    title = vim.fn.fnamemodify(self.todo_folder, ":h:t") .. " - TODO",
    title_pos = "center",
  }
  self.win = vim.api.nvim_open_win(self.buf, true, opts)
end

function TodoWindow:destroy_window()
  vim.api.nvim_set_current_win(self.win)
  vim.cmd "silent w" -- save before closing
  self.win = nil
end

function TodoWindow:destroy_buffer()
  vim.cmd "silent bd" -- delete buffer
  self.buf = nil
end

function TodoWindow:create_buffer()
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("modifiable", true, { buf = self.buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = self.buf })
end

function TodoWindow:open_file()
  local todo_file = self.todo_folder .. "/.TODO.md"
  vim.cmd("silent edit" .. todo_file)
  vim.cmd "normal G" -- go to EOF
end

function TodoWindow:setup_keymaps()
  local close_window_keymaps = { "q", "<esc>", "<c-c>" }
  for _, key in ipairs(close_window_keymaps) do
    vim.cmd("nnoremap <buffer> <silent> " .. key .. " :" .. close_window_vim_cmd .. "<cr>")
  end
end

function TodoWindow:setup_autocmds()
  vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("TodoNvim", { clear = true }),
    pattern = "<buffer>",
    callback = function()
      self:close_todo_window()
    end,
  })
end

function TodoWindow:open_todo_window()
  self.todo_folder = self:get_todo_folder()
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
  setup = function(opts)
    vim.cmd "command! TodoToggle :lua require('todo').toggle_todo_window()"
    if opts ~= nil and opts.map ~= nil then
      vim.keymap.set("n", opts.map, "<cmd>TodoToggle<cr>", { silent = true, desc = "Open todo.nvim" })
    end
  end,
}
