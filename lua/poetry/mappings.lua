local poetry = require("poetry")

local M = {}

function M.map(key, rhs)
  local lhs = string.format("%s%s", poetry.config.leader, key)
  vim.api.nvim_set_keymap("n", lhs, rhs, {noremap = true, silent = true})
end

function M.set_mappings()
end

return M
