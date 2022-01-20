local config = require("py.config")

local M = {}

function M.map(key, rhs)
  local lhs = string.format("%s%s", config.leader(), key)
  vim.api.nvim_set_keymap("n", lhs, rhs, {noremap = true, silent = true})
end

function M.set_mappings()
  M.map("p", "<cmd>lua require('py.ipython').toggleIPython()<CR>")
  M.map("c", "<cmd>lua require('py.ipython').sendObjectsToIPython()<CR>")


  M.map("t", "<cmd>lua require('py.pytest').launchPytest()<CR>")
  M.map("r", "<cmd>lua require('py.pytest').showPytestResult()<CR>")

  -- Poetry Mappings
  M.map("d", "<cmd>lua require('py.poetry').addDependency()<CR>")
end

return M
