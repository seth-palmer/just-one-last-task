-- A class to store task information
--- @class Group: LuaObject
Task = {}
function Task.new(params)
    -- Handle empty params
    if params == nil then
        params = {}
    end

    local self = {}

    local title = params.title or ""
    local groupId = params.groupId or -1
    local description = params.description or ""

    -- default to 'not complete'
    local isComplete = params.isComplete or false
    
    local assignedPlayer = params.assignedPlayer or "[Unasigned]"

    -- todo: store datetime https://www.lua.org/pil/22.1.html

    --- Get the title of the task
    --- @return string
    function self.getTitle()
        return title
    end

    --- Set the title of the task
    --- @param newTitle string
    function self.setTitle(newTitle)
        title = newTitle
    end

    --- Mark task as complete
    function self.markComplete()
        isComplete = true
    end

    -- Set up metatable with __tostring metamethod
    -- https://gist.github.com/oatmealine/655c9e64599d0f0dd47687c1186de99f
    local mt = {
        __tostring = function()
            local completeStatus = isComplete and "Yes" or "No"
            return string.format("GroupId: %d Title: %s, Complete: %s, Desc: %s", 
            groupId, title, completeStatus, description)
        end
    }
    
    setmetatable(self, mt)

    return self
end
