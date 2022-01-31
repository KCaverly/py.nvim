local Job = require("plenary.job")
local Path = require("plenary.path")
local scan = require("plenary.scandir")

local M = {}


---------------------------
-- General Functionality --
---------------------------


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

function M.showPackageDetails(package)

  poetry_dir, _ = M.findPoetry()
  if poetry_dir ~= nil then

    Job:new({
      command = "poetry",
      args = {"show", package},
      cwd = poetry_dir,
      on_exit = function(j, return_val)
        
        if return_val == 0 then
          res = {}
          for k, val in pairs(j:result()) do
            table.insert(res, val)
          end
          require("notify")(res, "info", { title = "py.nvim" })
        end

      end
    }):start()

  end

end


function M.showPackage()

  poetry_dir, _ = M.findPoetry()

  if poetry_dir ~= nil then

    vim.ui.input({ prompt = "Show Package: "},
    function(package)
      M.showPackageDetails(package)
    end)
  end

end


function M.installPoetry()

  poetry_dir, _ = M.findPoetry()

  if poetry_dir ~= nil then
    Job:new({
      command = "poetry",
      args = {"install"},
      cwd = poetry_dir
    })

  end

end


------------------------------
-- Dependency Functionality --
------------------------------


function M.parseDependency(package)

  args = {'add'}
  sep = ' '
  for str in string.gmatch(package, "([^"..sep.."]+)") do
    table.insert(args, str)
  end

  return args

end


function M.addDependency(package, opts)

  opts = opts or {silent = false}

  poetry_dir, _ = M.findPoetry()

  if poetry_dir == nil then
    return nil
  end
  
  if opts.silent ~= true then
    require("notify")("Adding "..package.." to Poetry Environment", "info", { title = "py.nvim" })
  end

  Job:new({
    command = "poetry",
    args = M.parseDependency(package),
    cwd = poetry_dir,
    on_exit = function(j, return_val)

      if return_val == 1 then
        res = {}
        for k, val in pairs(j:result()) do
          table.insert(res, val)
        end

        if opts.silent ~= true then
          require("notify")(res, "error", { title = "py.nvim" })
        end

      else
        if opts.silent ~= true then
          require("notify")("Added Successfully: "..package, "info", { title = "py.nvim" })
        end
      end

    end

  }):start()

end


function M.inputDependency()

  vim.ui.input({ prompt = "Add Package: " },
  function(package)
    
    M.addDependency(package, {silent=false})

  end)

end


return M
