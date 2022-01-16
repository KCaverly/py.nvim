local Path = require'plenary.path'
local scan = require'plenary.scandir'
local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

M.term = {
  opened = 0,
  win_id = nil,
  buf_id = nil,
  chan_id = nil
}

function M.getImports()
  
  local bufn = vim.api.nvim_get_current_buf()

  root = ts_utils.get_root_for_position(1, 1, nil)
  print(root)

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

function M.sendImportsToIPython()

  local message = M.getImports()
  M.sendToIPython(message)
  
end

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

function M.sendToIPython(message)
  
  message = vim.api.nvim_replace_termcodes("<esc>[200~" .. message .. "<esc>[201~", true, false, true)

  if M.term.chan_id ~= nil then
    vim.api.nvim_chan_send(M.term.chan_id, message)
  end

end

function M.launchIPython() 
  
  -- Get current details
  local launch_buf = vim.api.nvim_get_current_buf()
  local cwd = vim.fn.getcwd()
  local current_path = vim.api.nvim_exec(":echo @%", 1)

  -- Ensure Current File is .py
  local filetype = require("plenary.filetype").detect(current_path)

  -- Get Poetry File in Parent
  if filetype == 'python' then
    poetry_dir, poetry_file = M.findPoetry(current_path, cwd)
  else 
    print('Current File is not Python File')
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
  ipython_str = ipython_str.." && poetry run ipython"

  if M.config.ipython_editor_vi == 1 then
    ipython_str = ipython_str.." --TerminalInteractiveShell.editing_mode=vi"
  end

  if M.config.ipython_auto_reload == 1 then
    ipython_str = ipython_str.." --ext=autoreload --InteractiveShellApp.exec_lines='autoreload 2'"
  end

  -- Launch Terminal
  if M.config.open_in_vsplit == 1 then
    vim.api.nvim_exec(':vsplit', 0)
  end
  
  local bufn = vim.api.nvim_create_buf(true, true)
  local current_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(current_win, bufn)

  -- ipython_str = "cd "..poetry_dir.." && poetry run ipython"
  
  local chan = vim.fn.termopen(ipython_str, {
    on_exit = function()
      M.term.opened = 0
      M.term.win_id = current_win
      M.term.buf_id = bufn
      M.term.chan_id = chan
    end
  })

  M.term.opened = 1
  M.term.win_id = current_win
  M.term.buf_id = bufn
  M.term.chan_id = chan

end

do

  local default_config = {
    max_depth = 0,
    mappings = true, 
    leader = "<space>p",
    open_in_vsplit = 1,
    poetry_every_install = 1,
    ipython_auto_install = 1,
    ipython_editor_vi = 0,
    ipython_auto_reload = 1,
    send_imports = 1
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
