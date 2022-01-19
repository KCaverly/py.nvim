local Path = require'plenary.path'
local Job = require("plenary.job")
local scan = require'plenary.scandir'
local poetry = require("py.poetry")
local text_objects = require("py.text_objects")

local M = {}

M.ipython = {
  opened = 0,
  win_id = nil,
  buf_id = nil,
  chan_id = nil
}

M.pytest = {
  status = nil,
  failed = nil,
  result = nil
}


-------------------------
--IPYTHON FUNCTIONALITY--
-------------------------

function M.launchIPython() 

  -- Get current details
  local launch_buf = vim.api.nvim_get_current_buf()
  local launch_win = vim.api.nvim_get_current_win()
  local cwd = vim.fn.getcwd()
  local current_path = vim.api.nvim_exec(":echo @%", 1)

  -- Ensure Current File is .py
  local filetype = require("plenary.filetype").detect(current_path)

  -- Get Poetry File in Parent
  if filetype == 'python' then
    poetry_dir, poetry_file = poetry.findPoetry(current_path, cwd)
  else 
    print('Current File is not Python File')
  end

  if poetry_dir == nil then
    print("No pyproject.toml found in Parents")
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
  if M.config.poetry_isntall_every == 1 then
    ipython_str = ipython_str.." && poetry install"
  end

  -- Start IPython
  ipython_str = ipython_str.." && clear && poetry run ipython"

  if M.config.ipython_editor_vi == 1 then
    ipython_str = ipython_str.." --TerminalInteractiveShell.editing_mode=vi"
  end

  if M.config.ipython_auto_reload == 1 then
    ipython_str = ipython_str.." --ext=autoreload --InteractiveShellApp.exec_lines='autoreload 2'"
  end

  -- Launch Terminal
  if M.config.ipython_in_vsplit == 1 then
    vim.api.nvim_exec(':vsplit', 0)
  end
  
  local bufn = vim.api.nvim_create_buf(true, true)
  local current_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(current_win, bufn)

  local chan = vim.fn.termopen(ipython_str, {
    on_exit = function()
      M.ipython.opened = 0
      M.ipython.win_id = current_win
      M.ipython.buf_id = bufn
      M.ipython.chan_id = chan
    end
  })

  M.ipython.opened = 1
  M.ipython.win_id = current_win
  M.ipython.buf_id = bufn
  M.ipython.chan_id = chan

  if M.config.ipython_send_imports == 1 then
    vim.api.nvim_set_current_win(launch_win)
    M.sendImportsToIPython()
  else
    vim.api.nvim_set_current_win(M.ipython.win_id)
  end

end

function M.killIPython()

  current_win = vim.api.nvim_get_current_win()
  
  if M.ipython.opened == 1 then
    vim.api.nvim_set_current_win(M.ipython.win_id)
    vim.api.nvim_input('<ESC>')
    vim.api.nvim_input(':bd!<CR>')
  end

end

function M.toggleIPython()

  if M.ipython.opened == 1 then
    M.killIPython()
  else
    M.launchIPython()
  end

end

function M.sendToIPython(message)
  
  message = vim.api.nvim_replace_termcodes("<esc>[200~" .. message .. "<esc>[201~", true, false, true)

  if M.ipython.chan_id ~= nil then
    vim.api.nvim_chan_send(M.ipython.chan_id, message)
    vim.api.nvim_set_current_win(M.ipython.win_id)
    vim.api.nvim_exec(":startinsert", 0)
  end

end

function M.sendImportsToIPython()

  local message = text_objects.getImports()
  M.sendToIPython(message)
  
end

function M.sendObjectsToIPython()
  local message = text_objects.getObject()
  M.sendToIPython(message)
end

-------------------------
--PYTEST FUNCTIONALITY--
-------------------------

function M.showPytestResult()

  if M.pytest.status == 'running' then
    require("notify")("Running tests...", "info", {title="py.nvim"})
  elseif M.pytest.status == 'complete' then 

    if M.pytest.failed == 1 then

      require("notify")(M.pytest.result, "error", 
      {
        title = "py.nvim"
      })

    else

      require("notify")(M.pytest.result, "info",
      {
        title = "py.nvim"
      })

    end
  end

end

function M.launchPytest()

  local cwd = vim.fn.getcwd()
  local current_path = vim.api.nvim_exec(":echo @%", 1)
  local poetry_dir = poetry.findPoetry(current_path, cwd)

  -- notify
  if M.pytest.status == 'running' then
    M.showPytestResult()
  else
    require("notify")("Launching pytest...", "info", {title="py.nvim"})

    Job:new({
      command = "poetry",
      args = {'run', 'pytest'},
      cwd = poetry_dir,
      on_start = function() M.pytest.status = "running" end,
      on_exit = function(j, return_val)

        local res = {}
        for k, val in pairs(j:result()) do
          table.insert(res, val)
        end

        -- Set Outcome
        M.pytest.status = "complete"
        M.pytest.failed = return_val
        M.pytest.result = res

        M.showPytestResult()

      end
    }):start()
  end

end

do

  local default_config = {

    -- Setting Default Mappings
    mappings = true,

    -- Default Leader
    leader = "<space>p",

    -- Poetry Settings
    poetry_install_every = 1,

    -- IPython Settings
    ipython_in_vsplit = 1,
    ipython_auto_install = 1,
    ipython_editor_vi = 0,
    ipython_auto_reload = 1,
    ipython_send_imports = 1

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
      require('py/mappings').set_mappings()
    end 

  end

end


return M
