

-- A class to store task information
--- @class Task
Task = {}
function Task.new(params)
    -- Check required arguments https://www.lua.org/pil/5.3.html
    if type(params.title) ~= "string" then 
        error("New task requires a title")
    elseif type(params.group_id) ~= "number" then
        error("New task requires a group id")
    elseif type(params.task_id) ~= "string" then
        error("New task requires a task uuid")
    end

    local self = {}

    local title = params.title
    local group_id = params.group_id
    local task_id = params.task_id

    -- Default to empty description
    local description = params.description or ""

    -- default to 'not complete'
    local is_complete = params.is_complete or false
    
    local assigned_player = params.assigned_player or "[Unasigned]"

    -- TODO store datetime https://www.lua.org/pil/22.1.html


    --- Get the uuid of the task
    --- @return string - uuid for the task
    function self.get_id()
        return task_id
    end

    --- Get the group id of the task
    --- @return number - uuid for the task
    function self.get_group_id()
        return group_id
    end

    --- Set the group id of the task
    ---@param new_group_id number - the new group id
    function self.set_group_id(new_group_id)
        group_id = new_group_id
    end

    --- Get the title of the task
    --- @return string
    function self.get_title()
        return title
    end

    --- Set the title of the task
    --- @param new_title string
    function self.set_title(new_title)
        title = new_title
    end

    --- Mark task as complete
    function self.mark_complete()
        is_complete = true
    end

    -- Set up metatable with __tostring metamethod
    -- https://gist.github.com/oatmealine/655c9e64599d0f0dd47687c1186de99f
    local mt = {
        __tostring = function()
            local complete_status = is_complete and "Yes" or "No"
            return string.format("group_id: %d Title: %s, Complete: %s, Desc: %s", 
            group_id, title, complete_status, description)
        end
    }
    
    setmetatable(self, mt)

    return self
end