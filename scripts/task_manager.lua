local Utils = require("utils")

TaskManager = {}
local MAX_GUI_GROUPS = 28

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

    --- Set the show completed setting to the new boolean
    ---@param new_value boolean
    function self.set_setting_show_completed(new_value)
        storage.task_data.settings.show_completed = new_value
    end

    --- Returns the show completed setting 
    --- @return show_completed boolean the value
    function self.get_setting_show_completed()
        return storage.task_data.settings.show_completed
    end

    --- Get the list of groups
    --- (Note groups do not contain lists of tasks
    --- use get_tasks and provide the group_id)
    function self.get_groups()
        return groups
    end

    --- Count the number of tasks in a group
    --- @param group_id string the group to search for
    --- @return number task_count the total number of tasks
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
    --- @param group_id string id of the group to fetch tasks from
    ---@param include_completed boolean if completed tasks should be included
    --- @return table tasks with tasks for the group
    function self.get_tasks(group_id, include_completed)
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
                and (include_completed or task.is_complete == false)
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

    --- Swap the position of task priorities 
    --- Important: local functions must be put above where they are used!
    local function swap_priorities(index1, index2)
        local temp = task_priorities[index1]
        task_priorities[index1] = task_priorities[index2]
        task_priorities[index2] = temp
    end

    --- Returns the index of the group in the order
    ---@param group_id string the id of the group you are looking for
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
    --- @param group_id string id of group to move
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
    --- @param group_id string id of group to move
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
    --- @param pos1 string id of group to swap
    --- @param pos2 string id of other group to swap
    function self.swap_group_positions(pos1, pos2)
        local temp = group_order[pos1]
        group_order[pos1] = group_order[pos2]
        group_order[pos2] = temp
    end

    --- Adds the new group with data provided
    ---@param task_params table with id, name, and icon values
    ---@return string id the new group id, or nil if an error
    function self.add_group(task_params)
        -- Check if there are too many groups 
        if #group_order >= MAX_GUI_GROUPS then
            return nil
        end

        -- Create Make a new id for the group
        local id = Utils.uuid()

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
    ---@param group_id string to delete
    ---@return boolean is_deleted  true if successful, false otherwise
    function self.delete_group(group_id)
        -- Return false if it is the only remaining group 
        if #group_order == 1 then
            return false
        end

        -- Check that group exists
        if groups[group_id] ~= nil then

            -- Delete group data
            groups[group_id] = nil

            -- Get position and delete (all elements shifted down)
            local group_pos = self.get_group_position(group_id)
            table.remove(group_order, group_pos)
            return true
        end
        return false
    end

    --- Add a task using provided parameters
    ---@param task_params any
    ---@param add_to_top boolean if the group should be added to the top of the list
    function self.add_task(task_params, add_to_top)
        if type(add_to_top) ~= "boolean" then
            error("New task error: Must provide a boolean for variable [add_to_top]")
        end

        -- Create Make a new id for the task
        local id = Utils.uuid()

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
        -- or insert top shifing everything else down   
        else
            table.insert(task_priorities, 1, id)
        end
    end



    

    --- Update the provided task
    ---@param task_params any with new title, description, group_id
    ---@param task_id string of the task to update
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
    ---@param group_params any with new name and icon
    ---@param group_id string of the group to update
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
    ---@return any - or nil if no matching task exists
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
    ---@return any - or nil if no matching group exists
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
    --- @return table group_order indexed table, access it with group_order[1]
    function self.get_group_order()
        return storage.task_data.group_order
    end

    --- Returns the saved location of the window for the player
    ---@param player any with the window
    ---@param window_name string name of the window
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
    ---@param player any to save location for 
    ---@param window_name any name of window to save
    ---@param new_location any coordinates to save
    function self.save_window_location(player, window_name, new_location)
        -- Initialize if needed
        storage.players = storage.players or {}
        storage.players[player.index] = storage.players[player.index] or {}
        storage.players[player.index].saved_window_locations = storage.players[player.index].saved_window_locations or {}
        
        -- Save
        storage.players[player.index].saved_window_locations[window_name] = new_location
    end

    --- Returns the last interacted with element for the player
    ---@param player any player associated 
    ---@return string|nil last_interacted_task_id or nil if an error 
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
    ---@param player any player associated 
    ---@param button_name any when clicked closes the window
    ---@param window_name any window to close
    function self.bind_close_button(player, button_name, window_name)
        -- initialize if needed 
        storage.players[player.index].close_button_registry = 
        storage.players[player.index].close_button_registry or {}

        -- bind close button to window 
        storage.players[player.index].close_button_registry[button_name] = window_name
    end

    --- Returns and removes the window name mapping for the button, or nil if not found
    ---@param player any player associated
    ---@param button_name string button to remove the mapping from
    ---@return string|nil window_name The name of the window to close
    function self.pop_close_button(player, button_name)
        local registry = storage.players[player.index].close_button_registry
        local window_name = registry[button_name]
        registry[button_name] = nil  -- Remove the mapping
        return window_name
    end


    --- Save the task element last interacted with
    ---@param player any player associated
    ---@param id any task_id to save
    function self.save_last_interacted_task_id(player, id)
        -- initialize if needed 
        storage.players[player.index].last_interacted_task_id = storage.players[player.index].last_interacted_task or {}

        -- save
        storage.players[player.index].last_interacted_task_id = id
    end

    --- Returns the current group id
    ---@param player any player associated
    ---@return string current_group_id id of the current group for the player
    function self.get_current_group_id(player)
        local current_group_id = storage.players[player.index].selected_group_tab_id

        -- If no current_group_id then return the id of the first group 
        if current_group_id == nil then
            return group_order[1]
        end

        return current_group_id
    end

    --- Sets the current group id
    ---@param player any player associated
    ---@param new_id string new group_id to save
    function self.set_current_group_id(player, new_id)
        storage.players[player.index].selected_group_tab_id = new_id
    end

    --- Determines if the provided group exists or not
    ---@param group_id any id of group to check
    ---@return boolean does_group_exist true if the group exists, false otherwise
    function self.does_group_exist(group_id)
        return groups[group_id] ~= nil
    end

    --- Save the 
    ---@param player any
    ---@param task_id any
    function self.add_selected_task(player, task_id)
        -- If task was already selected deselect it 
        if self.is_task_selected(player, task_id) then
            local selected_tasks = self.get_selected_tasks(player)
            selected_tasks[task_id] = nil
            return
        end

        -- For now only allow one selected task 
        -- self.clear_selected_tasks(player)

        -- Initialize if needed
        if not storage.players[player.index].selected_tasks then
            storage.players[player.index].selected_tasks = {}
        end

        -- Set the task_id to true
        storage.players[player.index].selected_tasks[task_id] = true
    end

    --- Returns the selected tasks for the player
    ---@param player any player associated
    ---@return table selected_tasks tasks for the player 
    function self.get_selected_tasks(player)
        return storage.players[player.index].selected_tasks
    end

    function self.is_any_task_selected(player)
        -- Returns nil if the table is empty
        return next(self.get_selected_tasks(player)) ~= nil
    end

    --- Clears all selected tasks for the player
    ---@param player any player associated
    function self.clear_selected_tasks(player)
        storage.players[player.index].selected_tasks = {}
    end

    --- Returns if the task is selected by the player
    ---@param player any player associated
    ---@param task_id any id of the task 
    ---@return boolean is_selected true if selected, false otherwise
    function self.is_task_selected(player, task_id)
        local selected_tasks = self.get_selected_tasks(player)
        if not selected_tasks then
            return false
        end
        -- Return if the task is currently selected
        return selected_tasks[task_id] == true
    end


    --- Swap the position of tasks using their ids
    ---@param task1_id string - id of task 1
    ---@param task2_id string - id of task 2
    function self.swap_task_positions(task1_id, task2_id)
        -- Store the positions 
        local task1_pos
        local task2_pos

        -- Loop through first to find the indexes then swap 
        for index, task_id in ipairs(task_priorities) do
            if task_id == task1_id then
                task1_pos = index
            end

            if task_id == task2_id then
                task2_pos = index
            end
        end

        -- If both exist swap 
        if task1_pos and task2_pos then
            swap_priorities(task1_pos, task2_pos)
        end
    end

    --- Move selected tasks in the provided list up or down
    ---@param direction table - either Direction.Up or Direction.Down
    ---@param tasks_list table - list of tasks
    ---@param tasks_to_move table - selected tasks to move
    function self.move_tasks(direction, tasks_list, tasks_to_move)

        -- If moving down reverse the tasks list 
        -- this prevents a task swaping problem
        if direction == Direction.Down then
            local reversed = {}
            for i = #tasks_list, 1, -1 do
                table.insert(reversed, tasks_list[i])
            end
            tasks_list = reversed
        end
        
        -- Save the previous task id so we can swap with it 
        local previous_task_id

        -- Loop through the tasks 
        for index, task in ipairs(tasks_list) do
            
            -- If it is one of our selected tasks swap it
            if tasks_to_move[task.id] == true then
                -- Ensure their is a previous task to swap with
                if previous_task_id then
                    -- swap 
                    self.swap_task_positions(task.id, previous_task_id)
                end
            
            -- if not one of our selected tasks save it 
            -- as a previous task 
            else
                previous_task_id = task.id
            end
        end
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
