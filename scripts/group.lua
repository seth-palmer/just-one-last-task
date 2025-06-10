require "scripts.utils"

-- A class to store group information and tasks for that group
--- @class Group: LuaObject
Group = {}
function Group.new(params)
    local self = {}

    local groupId = params.groupId
    local name = params.name
    local icon = params.icon
    local taskCount = 0
    

    -- A list of tasks
    local tasks = params.tasks or {}

    -- A list of taskIds order indicates priority to display
    -- first should appear at the top of the task list in this group
    local priorities = params.priorities or {}

    --- Return the number of tasks
    --- @return number
    function self.getTaskCount()
        count = 0
        for _ in pairs(tasks) do count = count + 1 end
        return count
    end

    --- Returns the table of tasks with string uuid's as the keys
    --- @return table
    function self.getTasks()
        return tasks
    end

    --- Swap the position of priorities 
    --- Important: local functions must be put above where they are used!
    local function swapPriorities(index1, index2)
        local temp = priorities[index1]
        priorities[index1] = priorities[index2]
        priorities[index2] = temp
    end

    --- Adds a task making it with the provided parameters
    --- also adds it to the priority list 
    --- @param taskParams table - with task details
    --- @param insertAtEnd boolean - if the task should be added to the end of the list
    function self.addTask(taskParams, insertAtEnd)
        insertAtEnd = insertAtEnd or false

        -- Create Make a new id for the task
        local id = uuid()

        -- Make a new task
        local newTask = Task.new(taskParams)
        tasks[id] = newTask

        -- Add id to end of priorities list
        if insertAtEnd then
            table.insert(priorities, id)  
        -- or insert at end, then swap with first value   
        else
            table.insert(priorities, id) 
            swapPriorities(1, #priorities)
        end
    end

    --- Setup metatable
    local mt = {
        --- prints out group stats and all tasks in order or priority
        __tostring = function()
            local info = string.format("GroupId: %d, Name: %s, Tasks Count: %d\n",
             groupId, name, self.getTaskCount())
            local displayTasks = ""

            for k, _ in pairs(priorities) do 
                local taskId = priorities[k]
                displayTasks = displayTasks .. k .. ": " .. tostring(tasks[taskId]) .. "\n"
            end

            return info .. displayTasks
        end
    }

    setmetatable(self, mt)
    return self
end

