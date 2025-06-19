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

    -- A list of taskIds
    local priorities = params.priorities or {}


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

    --- Gets the task with the provided uuid
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