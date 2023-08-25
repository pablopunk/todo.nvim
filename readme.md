# todo.nvim

> Project-specific notes

![screencast](./screencast.gif)

This plugin opens a floating window to write quick notes/todo list for your project.
It will create a `TODO.md` file hidden in the nearest `.git` folder, so every time you
open a different project you'll only see your notes for that project.

If you're not on a repo, it wil keep a global `~/TODO.md` file.

## Installation

For example using `lazy.nvim`

```lua
{
  "pablopunk/todo.nvim",
  config = true, -- initialize it
}
```

## Usage

It will give you a new command `:TodoToggle` to open close the `TODO.md` file. You can map it to whatever you want. I map it to `<leader>t`:

```lua
{
  "pablopunk/todo.nvim",
  config = function()
    require("todo").setup {}
    vim.keymap.set("n", "<leader>t", "<cmd>TodoToggle<cr>", { silent = true })
  end,
}
```

