local poetry = require("py.poetry")
local config = require("py.config")

local M = {}

M.ipython = {
  opened = 0,
  win_id = nil,
  buf_id = nil,
  chan_id = nil
}


function M.launchIPython()

  -- Get Current Details
  local launch_buf = vim.api.nvim_get_current_buf()
  local launch_win = vim.api.nvim_get_current_win()
  local cwd = vim.fn.getcwd()
  local current_path = vim.api.nvim_exec(":echo @%", 1)

  -- Ensure Current File is .py
  local filetype = require("plenary.filetype").detect(current_path)

  -- Get Poetry File in Parent
  poetry_dir, _ = poetry.findPoetry()

  if poetry_dir == nil then
    return nil
  end

  -- Install IPython Automatically
  if config.ipython_auto_install() == 1 then
    poetry.addDependency('--dev ipython', {silent = true})
  end

end


function M.killIPython()

end


function M.toggleIPython()

end





return M
