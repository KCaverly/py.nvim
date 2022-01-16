local Path = require'plenary.path'
local scan = require'plenary.scandir'

local M = {}

function M.findPoetry(current_path, cwd)

  -- Ensure Current File is .py
  filetype = require("plenary.filetype").detect(current_path)
  if filetype == 'python' then

    parents = Path:new(current_path):parents()
    for i, parent in pairs(parents) do

      files = scan.scan_dir(parent, { hideen = false, depth = 1})
      for j, file in pairs(files) do
        if file == parent.."/".."pyproject.toml" then
          return parent, file
        end
      end

      -- Stop Loop at Parent Directory
      if parent == cwd then
        break
      end
    end
  end

  return nil
end

return M
