
local M = {}

function M.getOutput(result)

    res = {}
    for k, val in pairs(j:result()) do
        table.insert(res, val)
    end
    
    return res

end

return M
