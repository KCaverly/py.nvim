local Path = require'plenary.path'
local scan = require'plenary.scandir'

local M = {}

function M.testFunction()
  print("Test")  
end 

function M.findPoetry()

  local cwd = vim.fn.getcwd()
  local current_path = vim.api.nvim_exec(":echo @%", 1)

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

function M.sendToIPython()

end

function M.launchIPython() 

  local poetry_dir, poetry_file = M.findPoetry()

  if poetry_dir == nil then
    print("Poetry File Note Found in: "..vim.fn.getcwd())
    return nil
  end
  
  -- Launch Terminal in Split
  ipython_str = "cd "..poetry_dir

  -- If poetry_auto_install
  -- Install ipython as a dev dependency automatically
  if M.config.ipython_auto_install == 1 then
    ipython_str = ipython_str.." && poetry add --dev ipython"
  end

  -- If poetry_every_install
  -- Run 'poetry install' on every launch
  if M.config.poetry_every_install == 1 then
    ipython_str = ipython_str.." && poetry install"
  end

  -- Start IPython
  ipython_str = ipython_str.." && poetry run ipython --TerminalInteractiveShell.editing_mode=vi"

  if M.config.ipython_auto_reload == 1 then
    ipython_str = ipython_str.." --ext=autoreload --InteractiveShellApp.exec_lines='autoreload 2'"
  end

  -- Launch Terminal
  vim.api.nvim_exec(":term "..ipython_str, 0)

end

do

  local default_config = {
    max_depth = 0,
    mappings = true, 
    leader = "<space>p",
    poetry_every_install = 1,
    ipython_auto_install = 1,
    ipython_auto_reload = 1
  }
  
  function M.setup(user_config)
    
    -- Check if Poetry is Executable in Path
    if vim.fn.executable("poetry") == 0 then
      error("poetry is not executable.")
    end

    -- Manage Config
    user_config = user_config or {}
    M.config = vim.tbl_extend("keep", user_config, default_config)

    -- Set mappings
    if M.config.mappings == true then
      require('poetry/mappings').set_mappings()
    end 

  end

end


return M
