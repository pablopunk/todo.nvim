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

local function toggle_todo_window()
  -- check if buf is already open
  if buf ~= nil and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_command "w|bd" -- save and close
    win = nil
    buf = nil
    return
  end

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
  local todo_file = repo_folder .. "/TODO.md"

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

  vim.api.nvim_command("edit" .. todo_file)
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":TodoToggle<cr>", { noremap = true, silent = true }) -- make 'q' exit the window
  vim.api.nvim_command "normal G" -- go to EOF
end

return {
  toggle_todo_window = toggle_todo_window,
  setup = function()
    -- Create the custom command ":Todo"
    vim.cmd [[command! TodoToggle :lua require('todo').toggle_todo_window()]]
  end,
}
