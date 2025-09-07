require "utils"


TaskManager = {}


--- A class to store group information and tasks for that group
--- @class TaskManager
function TaskManager.new(params)
    -- Named Arguments as per - lua style https://www.lua.org/pil/5.3.html

    -- Handle empty params
    if params == nil then
        params = {}
    end

    local self = {}


    -- Store group, player, and task data
    local groups = storage.task_data.groups
    local players = storage.players


    -- A list of taskIds and priorities
    local tasks = storage.task_data.tasks
    local task_priorities = storage.task_data.priorities


    --- Get the list of groups
    function self.get_groups()
        return groups
    end

    --- Returns the table of tasks for a group ordered by priority
    --- @return table
    function self.get_tasks(group_id, target_complete_state)
        -- TODO 
        -- search through task list an return only those in 
        -- the provided group 
        -- Save tasks in new table
        local ordered_tasks = {}

        -- Go through the priority table (with task ids)
        -- Add to the ordered tasks so they are returned in the proper order
        for _, task_id in pairs(task_priorities) do
            local task = tasks[task_id]
            -- Only return tasks for the specific group 
            -- and matching the target complete status
            if task.group_id == group_id and task.is_complete == target_complete_state then
                table.insert(ordered_tasks, tasks[task_id])
            end
        end
        return ordered_tasks
    end

    --- Get a list with all group names
    function self.get_group_names()
        local names = {}
        for _, g in pairs(groups) do
            -- Get the icon and name to display
            local name = g.icon .. " " .. g.name
            table.insert(names, name)
        end
        return names
    end

    --- Swap the position of priorities 
    --- Important: local functions must be put above where they are used!
    local function swap_priorities(index1, index2)
        local temp = task_priorities[index1]
        task_priorities[index1] = task_priorities[index2]
        task_priorities[index2] = temp
    end


    --- Add a task using provided parameters
    ---@param task_params any
    function self.add_task(task_params, add_to_top)
        if type(add_to_top) ~= "boolean" then
            error("New task error: Must provide a boolean for variable [add_to_top]")
        end

        -- Create Make a new id for the task
        local id = uuid()

        -- Make a new task
        local newTask = {
            id=id,
            group_id=task_params.group_id,
            title=task_params.title,
            is_complete = false
        }
        tasks[id] = newTask

        -- Add id to end of priorities list
        if not add_to_top then
            table.insert(task_priorities, id)
        -- or insert at end, then swap with first value   
        else
            table.insert(task_priorities, id)
            swap_priorities(1, #task_priorities)
        end
    end

    

    --- Update the provided task
    ---@param task_params any
    ---@param task_id string
    function self.update_task(task_params, task_id)
        -- Get the task
        local task = tasks[task_id]
        if task == nil then error("No task in group " .. name .. " with matching id: " .. task_id) end

        -- Find the original task group 
        -- local group_id = self.get_task(task_id).group_id

        -- Check if the task needs to be moved 
        -- local needs_move = task_params.group_id ~= group_id

        -- If task is being moved 
        -- if needs_move then
        --     -- Get values to use
        --     local to_group_id = task_params.group_id
        --     local add_to_top = task_params.add_to_top

        --     -- Move the task 
        --     self.move_task(task_id, to_group_id, add_to_top)
        -- end

        -- Update any values inside the task, use the new position
        --groups[task_params.group_id].update_task(task_id, task_params)
        
        task.title = task_params.title
        task.group_id = task_params.group_id
    end

    --- Move the task to the provided group
    ---@param task_id any
    ---@param to_group_id any
    function self.move_task(task_id, to_group_id, add_to_top)
        -- Get the original task group 
        local task = self.get_task(task_id)
        local from_task_group = task.group_id

        -- Copy to new group 
        groups[to_group_id].copy_task(task, add_to_top)

        -- Delete from old group 
        groups[from_task_group].delete_task(task_id)
    end


    --- Gets the task with the provided uuid
    --- @param task_id string - uuid of the task to search for
    ---@return Task - or nil if no matching task exists
    function self.get_task(task_id)
        local task
        if tasks[task_id] ~= nil then
            return tasks[task_id]
        end
        if task == nil then
            error("Task not found with id: " .. (task_id or "[nil value]"))
        end

        return task
    end

    -- For debugging
    function self.stats()
        -- '#' before a list makes it return a count (won't work for dictionaries)
        local stats = string.format("Groups: %d, Players: %d, Tasks: %d", #groups, #players, #tasks)
        return stats
    end


    return self
end




return TaskManager