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
    local group_order = storage.task_data.group_order

    local players = storage.players


    -- A list of taskIds and priorities
    local tasks = storage.task_data.tasks
    local task_priorities = storage.task_data.priorities

    local settings = {
        show_completed = false
    }

    function self.set_setting_show_completed(new_value)
        settings.show_completed = new_value
    end

    function self.get_setting_show_completed()
        return settings.show_completed
    end

    --- Get the list of groups
    function self.get_groups()
        return groups
    end

    --- Returns the table of tasks for a group ordered by priority
    --- @return table
    function self.get_tasks(group_id, target_complete_state)
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
            if task.group_id == group_id 
                and task.is_complete == target_complete_state 
                and task.parent_id == nil then
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
            local name = "[img=" .. g.icon .. "] " .. g.name
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

    --- Adds the new group with data provided
    function self.add_group(task_params)
        -- TODO Ok problem I'm using id of `1 and 2` so far for groups and relying on that incrementing (which will break when deleting groups) so I need to switch to using a new system of actual ids and then have a table to store the order.

        -- Create Make a new id for the group
        local id = uuid()

        -- BUG for now just use provided id + 1
--         local id = task_params.id

        -- Make a new group
        local new_group = {
            id=id,
            name=task_params.name,
            icon=task_params.icon
        }

        groups[id] = new_group

        -- TODO: probably add its id to list of group?
        table.insert(group_order, id)

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
            is_complete = false,
            show_details = false,
            parent_id = task_params.parent_id or nil,
            subtasks = {}
        }
        tasks[id] = newTask

        if not (newTask.parent_id == nil) then
            -- If this is a subtask add its id to the parent 
            local parent_task = tasks[newTask.parent_id]
            table.insert(parent_task.subtasks, id)

            -- end early since we don't need to set task priority
            return
        end

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
        if task == nil then error("No task in with matching id: " .. tostring(task_id)) end

        -- Update task values
        task.title = task_params.title
        task.group_id = task_params.group_id
    end

    --- Update the provided group
    ---@param group_params any
    ---@param group_id string
    function self.update_group(group_params, group_id)
        -- Get the group
        local group = groups[group_id]
        if group == nil then error("No group in with matching id: " .. tostring(group_id)) end

        -- Update group values
        group.name = group_params.name
        group.icon = group_params.icon
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

    --- Returns the group with the provied uuid
    --- @param id string - uuid of the group to search for
    ---@return Group - or nil if no matching group exists
    function self.get_group(id)
        local group
        if groups[id] ~= nil then
            return groups[id]
        end
        if group == nil then
            error("Group not found with id: " .. (id or "[nil value]"))
        end

        return group
    end

    --- Returns a table with the order of groups as ids
    --TODO: fix is broken
    function self.get_group_order()
        return storage.task_data.group_order
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
