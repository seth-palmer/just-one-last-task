
local constants = require("constants")
local DEFAULT_MAX_ENTRIES = 30
local DEFAULT_FIRST_INDEX = 1

local VisualActionLog = {}


function VisualActionLog.initialize()
    
    -- Initialize jolt specific data under a jolt key
    storage.jolt.visual_action_log = storage.jolt.visual_action_log
    or {
        entries = {},
    }
end

function VisualActionLog.add(action_type, data)
    local next_index = VisualActionLog.get_next_index()

    local entry = {
        index = next_index,
        type = action_type,
        data = data,
        tick = game.tick
    }
    local entries = storage.jolt.visual_action_log.entries
    table.insert(entries, 1, entry)

    -- remove old entries if needed
    if #entries > DEFAULT_MAX_ENTRIES then
        table.remove(entries, #entries)
    end
end

function VisualActionLog.get_next_index()
    if #storage.jolt.visual_action_log.entries == 0 then
        return DEFAULT_FIRST_INDEX
    end
    return storage.jolt.visual_action_log.entries[1].index + 1
end

function VisualActionLog.get_entries_since_index(index)
    index = index or 0
    
    local recent_entries = {}
    for i, value in ipairs(storage.jolt.visual_action_log.entries) do
        if value.index > index then
            table.insert(recent_entries, value)
        else -- exit when we've gone more than the index
            break
        end
    end

    return recent_entries
end

function VisualActionLog.get_latest_log_index()
    local entries = storage.jolt.visual_action_log.entries
    if entries and entries[1] then
        return entries[1].index
    end
    return 0
end

--- Returns true if there is an action since the provided index
---@param index any
---@return boolean is_new_action_since_index
function VisualActionLog.is_new_action_since_index(index)
    index = index or 0
    if index ~= nil then
        return VisualActionLog.get_latest_log_index() > index
    end
    
    return false
end

return VisualActionLog