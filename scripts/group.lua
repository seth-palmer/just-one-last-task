require "scripts.utils"

-- A class to store group information and tasks for that group
--- @class Group
Group = {}
function Group.new(params)
    if type(params.name) ~= "string" then 
        error("New group requires a name")
    elseif type(params.icon) ~= "string" then
        error("New group requires an icon path")
    elseif type(params.group_id) ~= "number" then
        error("New group requires a group id")
    end

    local self = {}
    

    local group_id = params.group_id
    local name = params.name
    local icon = params.icon
    

    -- A list of tasks
    local tasks = params.tasks or {}

    -- A list of taskIds order indicates priority to display
    -- first should appear at the top of the task list in this group
    local priorities = params.priorities or {}

    --- Return the number of tasks
    --- @return number
    function self.get_task_count()
        local count = 0
        for _ in pairs(tasks) do count = count + 1 end
        return count
    end


    --- Get the group name
    function self.get_name()
        return name
    end

    --- Get the icon path
    function self.get_icon_path()
        return icon
    end

    --- Returns the table of tasks ordered by priority
    --- @return table
    function self.get_tasks()
        -- Save tasks in new table
        local ordered_tasks = {}

        -- Go through the priority table (with task ids)
        -- Add to the ordered tasks so they are returned in the proper order
        for _, task_id in pairs(priorities) do
            table.insert(ordered_tasks, tasks[task_id])
        end
        return ordered_tasks
    end

    --- Swap the position of priorities 
    --- Important: local functions must be put above where they are used!
    local function swap_priorities(index1, index2)
        local temp = priorities[index1]
        priorities[index1] = priorities[index2]
        priorities[index2] = temp
    end

    --- Adds a task making it with the provided parameters
    --- also adds it to the priority list 
    --- @param task_params table - with task details
    --- @param add_to_top boolean - if the task should be added to the end of the list
    function self.add_task(task_params, add_to_top)
        if type(add_to_top) ~= "boolean" then
            error("New task error: Must provide a boolean for variable [add_to_top]")
        end

        task_params.group_id = group_id
        -- Create Make a new id for the task
        local id = uuid()

        -- Make a new task
        local newTask = Task.new(task_params)
        tasks[id] = newTask

        -- Add id to end of priorities list
        if not add_to_top then
            table.insert(priorities, id)
        -- or insert at end, then swap with first value   
        else
            table.insert(priorities, id)
            swap_priorities(1, #priorities)
        end
    end

    --- Setup metatable
    local mt = {
        --- prints out group stats and all tasks in order or priority
        __tostring = function()
            local info = string.format("group_id: %d, Name: %s, Tasks Count: %d\n",
             group_id, name, self.get_task_count())
            local display_tasks = ""

            for k, _ in pairs(priorities) do
                local taskId = priorities[k]
                display_tasks = display_tasks .. k .. ": " .. tostring(tasks[taskId]) .. "\n"
            end

            return info .. display_tasks
        end
    }

    setmetatable(self, mt)
    return self
end

