require "group"
require "task"

--Default groups
local nauvis_group = Group.new({group_id=1, name="Nauvis", icon="[img=space-location/nauvis]"})
local space_group = Group.new({group_id=2, name="Space", icon="[img=item/thruster]"})

local defaultGroups = {}
defaultGroups[1] = nauvis_group
defaultGroups[2] = space_group



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
    local groups = params.groups or defaultGroups
    local players = params.players or {}


    -- A list of taskIds and priorities
    local task_data = params.task_data
    local task_priorities = params.task_priorities


    --- Get the list of groups
    function self.get_groups()
        return groups
    end

    --- Get a list with all group names
    function self.get_group_names()
        local names = {}
        for _, g in pairs(groups) do
            -- Get the icon and name to display
            local name = g.get_icon_path() .. " " .. g.get_name()
            table.insert(names, name)
        end
        return names
    end


    --- Add a task using provided parameters
    ---@param task_params any
    ---@param group_id any
    ---@param insert_at_end any
    function self.add_task(task_params, group_id, insert_at_end)
        groups[group_id].add_task(task_params, insert_at_end)
    end

    --- Update the provided task
    ---@param task_params any
    ---@param task_id string
    function self.update_task(task_params, task_id)
        -- Find the original task group 
        local group_id = self.get_task(task_id).get_group_id()

        -- Check if the task needs to be moved 
        local needs_move = task_params.group_id ~= group_id

        -- If task is being moved 
        if needs_move then
            -- Get values to use
            local to_group_id = task_params.group_id
            local add_to_top = task_params.add_to_top

            -- Move the task 
            self.move_task(task_id, to_group_id, add_to_top)
        end

        -- Update any values inside the task, use the new position
        groups[task_params.group_id].update_task(task_id, task_params)
    end

    --- Move the task to the provided group
    ---@param task_id any
    ---@param to_group_id any
    function self.move_task(task_id, to_group_id, add_to_top)
        -- Get the original task group 
        local task = self.get_task(task_id)
        local from_task_group = task.get_group_id()

        -- Copy to new group 
        groups[to_group_id].copy_task(task, add_to_top)

        -- Delete from old group 
        groups[from_task_group].delete_task(task_id)
    end


    --- Gets the task with the provided uuid
    --- @param task_id string - uuid of the task to search for
    function self.get_task(task_id)
        local task
        -- Search through the groups 
        for index, group in ipairs(groups) do
            -- Check if the task exists in the group
            task = group.get_task(task_id)

            -- Exit loop if we have found the task
            if task ~= nil then
                break
            end
        end
        if task == nil then
            error("Task not found with id: " .. task_id)
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