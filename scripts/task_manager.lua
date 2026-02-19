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

    --- Count the number of tasks in a group
    --- @params the group to search for
    --- @return the total number of tasks
    function self.count_tasks_for_group(group_id)
        local task_count = 0

        -- Go through the priority table (with task ids)
        for _, task_id in pairs(task_priorities) do
            local task = tasks[task_id]

            -- Only count tasks for the specific group
            if task.group_id == group_id then
                task_count = task_count + 1
            end
        end

        return task_count
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

    --- Get a list with all group names and icons embedded
    function self.get_group_names()
        -- Store names with icons embedded
        local names = {}

        -- Get the groups in order
        for i, value in pairs(group_order) do
            -- Get the group
            local g = self.get_group(value)

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

    --- Returns the index of the group in the order
    ---@param group_id the id of the group you are looking for
    function self.get_group_position(group_id)
        local position = 1
        -- Search for the index that matches the group
        for index, value in pairs(group_order) do
            if value == group_id then
                position = index
            end
        end

        return position
    end

    --- Move group left
    function self.move_group_left(group_id)
        -- Get position
        local group_position = self.get_group_position(group_id)

        -- If position is number 1 do nothing
        if group_position == 1 then
            return
        end

        self.swap_group_positions(group_position, group_position - 1)
    end

        --- Move group right
    function self.move_group_right(group_id)
        -- Get position
        local group_position = self.get_group_position(group_id)

        -- #group_order to get the length
        local last_position = #group_order

        -- If position is greater than end
        if group_position >= last_position then
            return
        end

        self.swap_group_positions(group_position, group_position + 1)
    end

    --- Swaps the two positions
    function self.swap_group_positions(pos1, pos2)
        local temp = group_order[pos1]
        group_order[pos1] = group_order[pos2]
        group_order[pos2] = temp
    end

    --- Adds the new group with data provided
    ---@param task_params table with id, name, and icon values
    ---@return id returns the new group id
    function self.add_group(task_params)
        -- Create Make a new id for the group
        local id = uuid()

        -- Make a new group
        local new_group = {
            id=id,
            name=task_params.name,
            icon=task_params.icon
        }

        groups[id] = new_group

        -- add its id to list of group order
        table.insert(group_order, id)

        return id
    end

    --- Deletes the provided group matching the id
    ---@param group_id to delete
    ---@returns True if successful, false otherwise
    function self.delete_group(group_id)
        -- Check that group exists
        if groups[group_id] ~= nil then

            -- Delete group data
            groups[group_id] = {}

            -- Get position and delete (all elements shifted down)
            local group_pos = self.get_group_position(group_id)
            table.remove(group_order, group_pos)
            return True
        end
        return False
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
            description=task_params.description,
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
        task.description = task_params.description
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

    --- Returns the saved location of the window for the player
    ---@param player any - with the window
    ---@param window_name string - name of the window
    function self.get_saved_window_position(player, window_name)
        -- Retrieve saved location
        local saved_location = storage.players 
            and storage.players[player.index] 
            and storage.players[player.index].saved_window_locations 
            and storage.players[player.index].saved_window_locations[window_name]
        
        if saved_location then
            return saved_location
        else 
            return nil
        end
    end

    --- Save the window location for the player
    ---@param player any 
    ---@param window_name any 
    ---@param new_location any
    function self.save_window_location(player, window_name, new_location)
        -- Initialize if needed
        storage.players = storage.players or {}
        storage.players[player.index] = storage.players[player.index] or {}
        storage.players[player.index].saved_window_locations = storage.players[player.index].saved_window_locations or {}
        
        -- Save
        storage.players[player.index].saved_window_locations[window_name] = new_location
    end

    --- Returns the last interacted with element for the player
    ---@param player any
    function self.get_last_interacted_task_id(player)
        local last_interacted_task_id = storage.players
            and storage.players[player.index]
            and storage.players[player.index].last_interacted_task_id
        if last_interacted_task_id then
            return last_interacted_task_id
        else
            return nil
        end
    end

    --- Bind a button to close the provided window
    ---@param player any - player associated 
    ---@param button_name any - when clicked closes the window
    ---@param window_name any - window to close
    function self.bind_close_button(player, button_name, window_name)
        -- initialize if needed 
        storage.players[player.index].close_button_registry = 
        storage.players[player.index].close_button_registry or {}

        -- bind close button to window 
        storage.players[player.index].close_button_registry[button_name] = window_name
    end

    --- Returns and removes the window name mapping for the button, or nil if not found
    ---@param player LuaPlayer
    ---@param button_name string
    ---@return string|nil window_name The name of the window to close
    function self.pop_close_button(player, button_name)
        local registry = storage.players[player.index].close_button_registry
        local window_name = registry[button_name]
        registry[button_name] = nil  -- Remove the mapping
        return window_name
    end


    --- Save the task element last interacted with
    ---@param player any
    ---@param id any
    function self.save_last_interacted_task_id(player, id)
        -- initialize if needed 
        storage.players[player.index].last_interacted_task_id = storage.players[player.index].last_interacted_task or {}

        -- save
        storage.players[player.index].last_interacted_task_id = id
    end

    --- Returns the current group id
    ---@param player any
    function self.get_current_group_id(player)
        local current_group_id = storage.players[player.index].selected_group_tab_id
        return current_group_id
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
