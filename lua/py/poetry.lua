local Job = require("plenary.job")
local Path = require("plenary.path")
local scan = require("plenary.scandir")

local M = {}


function M.findPoetry()

  -- Get Current Details
  local cwd = vim.fn.getcwd()
  local current_path = vim.api.nvim_exec(":echo @%", 1)

  parents = Path:new(current_path):parents()
  for i, parent in pairs(parents) do
    files = scan.scan_dir(parent, { hidden = false, depth = 1 })
    for j, file in pairs(files) do
      if file == parent.."/".."pyproject.toml" then
        return parent, file
      end
    end

    if parent == cwd then
      break
    end
  end

  require("notify")("Poetry Environment Not Found", "error", { title = "py.nvim" })

end


function M.addDependency()

  vim.ui.input({ prompt = "Add Package: " },
  function(package)

    require("notify")("Adding "..package.." to Poetry Environment", "info",
                      { title = "py.nvim" })

    poetry_dir, _ = M.findPoetry()

    Job:new({
      command = "poetry",
      args = {'add', package},
      cwd = poetry_dir,
      on_exit = function(j, return_val)

        res = {}
        for k, val in pairs(j:result()) do
          table.insert(res, val)
        end
        
        if return_val == 0 then
          require("notify")("Added Successfully: "..package, 
                            "info", { title = "py.nvim" })
        else
          require("notify")(res, "error", { title = "py.nvim" })
        end

      end
    }):start()

  end)

end


return M
