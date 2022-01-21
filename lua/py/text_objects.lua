local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

function M.getStatementDefinition()

  local node = ts_utils.get_node_at_cursor()
  if (node:named() == false) then
    error("Node not recognized. Check to ensure treesitter parser is installed.")
  end

  while (string.match(node:sexpr(), "statement") == nil and string.match(node:sexpr(), "definition") == nil) do
    node = node:parent()
  end

  return node

end

function M.getObject(bufn)
  local node = M.getStatementDefinition()

  if node == nil then
    return nil
  end

  local bufn = bufn or vim.api.nvim_get_current_buf()
  local text = ts_utils.get_node_text(node, bufn)
  local _, start_column, _, _ = node:range()
  local message = table.concat(text, "\r")
  while start_column ~= 0 do
    message = string.gsub(message, '\r%s%s%s%s', '\r')
    start_column = start_column - 4
  end
  return message
end

function M.getImports()
  
  root = ts_utils.get_root_for_position(1, 1, nil)

  if root == nil then
    return nil
  end

  local import_nodes = {}
  for k, v in pairs(ts_utils.get_named_children(root)) do
    if v:type() == 'import_statement' then 
      table.insert(import_nodes, v)
    end

    if v:type() == 'import_from_statement' then
      table.insert(import_nodes, v)
    end
  end

  local import_text = ''
  for k, v in pairs(import_nodes) do
    local node_text = ts_utils.get_node_text(v)
    
    for j, v in pairs(node_text) do
      if import_text ~= '' then
        import_text = import_text.."\r"..v
      else
        import_text = v
      end
    end

  end

  return import_text

end

local function visual_selection_range()

  local _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
  local _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))

  print(csrow)
  print(cscol)
  print(cerow)
  print(cscol)

  if csrow < cerow or (csrow == cerow and cscol <= cecol) then
    return csrow - 1, cscol - 1, cerow - 1, cecol - 1
  else
    return cerow - 1, cecol - 1, csrow - 1, cscol - 1
  end
end

function M.getHighlighted()
  return vim.fn.getreg("z")
end

return M
