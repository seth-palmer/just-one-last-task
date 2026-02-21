-- outcome.lua
local Outcome = {}

function Outcome.success(value)
    return { success = true, value = value or true, error = nil }
end

function Outcome.fail(error_message)
    return { success = false, value = nil, message = error_message }
end

return Outcome