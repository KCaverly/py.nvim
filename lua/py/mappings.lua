local py = require("py")

local M = {}

function M.map(key, rhs)
  local lhs = string.format("%s%s", py.config.leader, key)
  vim.api.nvim_set_keymap("n", lhs, rhs, {noremap = true, silent = true})
end

function M.set_mappings()
  M.map("p", "<cmd>lua require('py').launchIPython()<CR>")
  M.map("c", "<cmd>lua require('py').sendObjectsToIPython()<CR>")
end

return M
