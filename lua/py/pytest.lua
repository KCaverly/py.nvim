local poetry = require("py.poetry")
local Job = require("plenary.job")


local M = {}

function M.launchPytest(opts)

  local cwd = vim.fn.getcwd()
  local current_path = vim.api.nvim_exec(":echo @%", 1)

  local poetry_dir = poetry.findPoetry(current_path, cwd)
  
  -- Launch Pytests
  require("notify")("Running pytests...", "info", {title="py.nvim"} )

  Job:new({
    --command = 'poetry run pytest',
    command = 'poetry',
    args = {'run', 'pytest'},
    cwd = poetry_dir,
    on_exit = function(j, return_val)

      if return_val == 1 then 
      
        local err = {}
        for k, val in pairs(j:result()) do
          table.insert(err, val)
        end
        require("notify")(err, "error", {
          title="py.nvim",
          keep=function() return false end})
        
      else
        require("notify")("Tests Passed Successfully!", "info", {title="py.nvim"})

      end

    end,
  }):start() 


  -- local test_term = vim.fn.termopen('cd '..poetry_dir..' && poetry run pytest', {
  --   on_stdout = function(message)
  --     require("notify")(message)
  --   end
  -- })

end

return M
