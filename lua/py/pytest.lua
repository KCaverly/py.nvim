local poetry = require("py.poetry")

local M = {}

function M.launchPytest()

  local cwd = vim.fn.getcwd()
  local current_path = vim.api.nvim_exec(":echo @%", 1)

  local poetry_dir = poetry.findPoetry(current_path, cwd)
  print(poetry_dir)
  
  local bufn = vim.api.nvim_create_buf(true, true)
  local current_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(current_win, bufn)

  local test_term = vim.fn.termopen('cd '..poetry_dir..' && poetry run pytest', {
    on_exit = function() end
  })

end

return M
