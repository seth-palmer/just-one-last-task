local Utils = require("utils")
local Outcome = require("outcome")
local constants = require("constants")


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

    log("jolt error")
    log(serpent.block(storage))

    -- Store group, player, and task data
    local players = storage.players

    local groups = (storage.jolt or storage.task_data).groups
    local group_order = (storage.jolt or storage.task_data).group_order
    
    -- A list of taskIds and priorities
    local tasks = (storage.jolt or storage.task_data).tasks
    local task_priorities = (storage.jolt or storage.task_data).priorities



    --- Set the show completed setting to the new boolean
    ---@param new_value boolean
    function self.set_setting_show_completed(player, new_value)
        storage.players[player.index].jolt.ui.show_completed_tasks = new_value
    end

    --- Returns the show completed setting 
    --- @return show_completed boolean the value
    function self.get_setting_show_completed(player)
        return storage.players[player.index].jolt.ui.show_completed_tasks
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

    --- Returns the position the task is in
    ---@param task_id any
    function self.get_task_order_position(task_id)
        -- Loop through the priorities list (order of tasks)
        for index, list_task_id in ipairs(task_priorities) do
            -- If the provided task id is found return the index
            if task_id == list_task_id then
                return index
            end
        end
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

            -- Delete all tasks in group
            for task_id, task in pairs(tasks) do
                -- Only delete tasks that have that have a matching group_id
                if task.group_id == group_id then
                    -- delete the task
                    self.delete_task(task_id)
                end
            end

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
        local new_task = {
            id=id,
            group_id=task_params.group_id,
            title=task_params.title,
            description=task_params.description,
            is_complete = false,
            show_details = false,
            parent_id = task_params.parent_id or nil,
            subtasks = {}
        }

        tasks[id] = new_task

        if not (new_task.parent_id == nil) then
            -- If this is a subtask add its id to the parent 
            local parent_task = tasks[new_task.parent_id]
            table.insert(parent_task.subtasks, id)

            -- end early since we don't need to set task priority
            return
        end

        -- Add id to end of priorities list
        if not add_to_top then
            table.insert(task_priorities, id)
         
        else -- or insert top shifing everything else down  
            table.insert(task_priorities, 1, id)
        end
    end

    --- Deletes the task removing its data
    ---@param task_id string - id of the task to delete
    ---@param skip_parent_removal boolean|nil
    function self.delete_task(task_id, skip_parent_removal)
        -- Get the full task data
        local task = self.get_task(task_id)

        -- If it has subtasks remove those first 
        if task.subtasks and #task.subtasks > 0 then

            for _, subtask_id in ipairs(task.subtasks) do
                -- If we are recursively deleting all subtasks 
                -- then skip removing them from their parent
                -- (since the parent task data will be deleted)
                self.delete_task(subtask_id, true)
                -- Note: prevents a problem since we can't modify this
                --       list we are going over or it will skip some
            end
        end

        -- If it is a subtask remove it from its parent's list
        -- (skip if deleting recursively since we will delete the full task anyway)
        if not skip_parent_removal and task.parent_id then

            -- Get the parent task
            local parent_task = self.get_task(task.parent_id)

            -- Loop through to find the task id to remove 
            for index, subtask_id in ipairs(parent_task.subtasks) do
                -- Look for id of the deleting task 
                if subtask_id == task_id then
                    -- remove it from the list
                    table.remove(parent_task.subtasks, index)
                    break -- exit once it has been found
                end
            end
        end

        -- Only remove from task_priorities if it's a root-level task
        -- (no parent) regardless of skip_parent_removal
        if not task.parent_id then
            
            -- Get the position of the task
            local task_position = self.get_task_order_position(task_id)
            
            -- Remove it from the priorities list
            table.remove(task_priorities, task_position)
        end

        -- Delete the task data
        tasks[task_id] = nil
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

    --- Returns the list of subtasks for the provided parent task
    --- Defaults to not include completed
    ---@param parent_id string - id of the parent task
    ---@param include_completed boolean|nil - if completed subtasks are included
    ---@return table subtasks
    function self.get_subtasks(parent_id, include_completed)
        -- Defaults to not include completed
        include_completed = include_completed or false

        -- Get the parent task 
        local parent_task = self.get_task(parent_id)
        local subtask_id_list = parent_task.subtasks

        -- Store tasks in table 
        local subtasks = {}

        -- Loop through the list of ids and get the full subtasks
        for index, subtask_id in ipairs(subtask_id_list) do
            -- Get the full task info
            local subtask = self.get_task(subtask_id)

            -- Only return tasks that match the target complete status
            if include_completed or subtask.is_complete == false then
                -- Add to table
                table.insert(subtasks, subtask)
            end
        end

        -- Return the list of full subtasks
        return subtasks
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
        return storage.jolt.group_order
    end

    --- Returns the saved location of the window for the player
    ---@param player any with the window
    ---@param window_name string name of the window
    function self.get_saved_window_position(player, window_name)
        -- Retrieve saved location
        local saved_location = storage.players 
            and storage.players[player.index] 
            and storage.players[player.index].jolt.ui.saved_window_locations 
            and storage.players[player.index].jolt.ui.saved_window_locations[window_name]
        
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
        -- Save
        storage.players[player.index].jolt.ui.saved_window_locations[window_name] = new_location
    end

    --- Returns the last interacted with element for the player
    ---@param player any player associated 
    ---@return string|nil last_interacted_task_id or nil if an error 
    function self.get_last_interacted_task_id(player)
        local last_interacted_task_id = storage.players
            and storage.players[player.index]
            and storage.players[player.index].jolt.ui.last_interacted_task_id
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
        -- bind close button to window 
        storage.players[player.index].jolt.ui.close_button_registry[button_name] = window_name
    end

    --- Returns and removes the window name mapping for the button, or nil if not found
    ---@param player any player associated
    ---@param button_name string button to remove the mapping from
    ---@return string|nil window_name The name of the window to close
    function self.pop_close_button(player, button_name)
        local registry = storage.players[player.index].jolt.ui.close_button_registry
        local window_name = registry[button_name]
        registry[button_name] = nil  -- Remove the mapping
        return window_name
    end


    --- Save the task element last interacted with
    ---@param player any player associated
    ---@param id any task_id to save
    function self.save_last_interacted_task_id(player, id)
        -- initialize if needed 
        storage.players[player.index].jolt.ui.last_interacted_task_id = storage.players[player.index].jolt.ui.last_interacted_task or {}

        -- save
        storage.players[player.index].jolt.ui.last_interacted_task_id = id
    end

    --- Returns the current group id
    ---@param player any player associated
    ---@return string current_group_id id of the current group for the player
    function self.get_current_group_id(player)
        local current_group_id = storage.players[player.index].jolt.ui.selected_group_tab_id

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
        storage.players[player.index].jolt.ui.selected_group_tab_id = new_id
    end

    --- Determines if the provided group exists or not
    ---@param group_id any id of group to check
    ---@return boolean does_group_exist true if the group exists, false otherwise
    function self.does_group_exist(group_id)
        return groups[group_id] ~= nil
    end


    local function tasks_are_siblings(task1_id, task2_id)
        local task1 = tasks[task1_id]
        local task2 = tasks[task2_id]
        -- Both top-level (no parent)
        -- Or both subtasks with the same parent
        return task1.parent_id == task2.parent_id
    end

    --- Save the 
    ---@param player any
    ---@param task_id any
    function self.add_selected_task(player, task_id)
        -- If task was already selected deselect it 
        if self.is_task_selected(player, task_id) then
            local selected_tasks = self.get_selected_tasks(player)
            selected_tasks[task_id] = nil
            return Outcome.success()
        end

        -- Only allow selecting tasks on the same level
        local selected_tasks = self.get_selected_tasks(player)
        local first_selected_id = next(selected_tasks)
        if first_selected_id and not tasks_are_siblings(task_id, first_selected_id) then
            -- Return error
            local error_message = {"jolt_task_list_window.error_cannot_select_non_sibling_tasks"}
            return Outcome.fail(error_message)
        end

        -- Set the task_id to true
        storage.players[player.index].jolt.ui.selected_tasks[task_id] = true
        return Outcome.success()
    end

    --- Returns the selected tasks for the player
    ---@param player any player associated
    ---@return table selected_tasks tasks for the player 
    function self.get_selected_tasks(player)
        return storage.players[player.index].jolt.ui.selected_tasks
    end

    function self.is_any_task_selected(player)
        -- Returns nil if the table is empty
        return next(self.get_selected_tasks(player)) ~= nil
    end

    --- Clears all selected tasks for the player
    ---@param player any player associated
    function self.clear_selected_tasks(player)
        storage.players[player.index].jolt.ui.selected_tasks = {}
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
    local function swap_task_positions(list_order, task1_id, task2_id)
        -- Store the positions 
        local task1_pos
        local task2_pos

        -- Loop through first to find the indexes then swap 
        for index, task_id in ipairs(list_order) do
            if task_id == task1_id then
                task1_pos = index
            end

            if task_id == task2_id then
                task2_pos = index
            end
        end

        -- If both exist swap 
        if task1_pos and task2_pos then
            list_order[task1_pos] = task2_id
            list_order[task2_pos] = task1_id
        end
    end

    --- Move selected tasks in the provided list up or down
    ---@param direction any - either Direction.Up or Direction.Down
    ---@param tasks_list table - list of tasks
    ---@param list_order table - numbered table with the order and ids
    ---@param tasks_to_move table - selected tasks to move
    local function move_tasks(direction, tasks_list, list_order, tasks_to_move)

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
                    swap_task_positions(list_order, task.id, previous_task_id)
                end
            
            -- if not one of our selected tasks save it 
            -- as a previous task 
            else
                previous_task_id = task.id
            end
        end
    end

    --- Move the currently selected tasks up
    ---@param player any - for this player
    function self.move_selected_tasks(player, direction)
        -- Get the selected tasks
        local selected_tasks = Task_manager.get_selected_tasks(player)
        
        -- Get tasks for selected group 
        local current_group_id = Task_manager.get_current_group_id(player)
        local include_completed = Task_manager.get_setting_show_completed(player)
        local tasks_in_group
        local list_order

        local first_selected_task_id, value = next(selected_tasks)
        local first_selected_task = Task_manager.get_task(first_selected_task_id)
        
        -- If selected task is a subtask fetch those as the group instead 
        if first_selected_task.parent_id then
            local parent_task = Task_manager.get_task(first_selected_task.parent_id)

            -- Fetch list of full task details
            local subtasks = Task_manager.get_subtasks(parent_task.id, include_completed)

            -- Only swap around with other subtasks
            tasks_in_group = subtasks

            -- Use the list stored in the parent for subtask order
            list_order = parent_task.subtasks

        else -- otherwise get tasks from the top level
            tasks_in_group = Task_manager.get_tasks(current_group_id, include_completed)
            -- Use our global list of priorites
            list_order = task_priorities
        end

        -- Move the selected tasks
        move_tasks(direction, tasks_in_group, list_order, selected_tasks)
    end

    --- Returns if it is a window from my mod "just-one-last-task" AKA JOLT
    ---@param window_name any
    function self.is_jolt_window(window_name)
        return window_name:find("^jolt")
    end

    --- Returns if the task list window is pinned open for the player
    ---@param player any - associated player
    function self.is_task_list_pinned_open(player)
        local is_task_list_pinned_open = storage.players[player.index].jolt.ui.is_task_list_pinned_open
        return is_task_list_pinned_open
    end

    --- Toggle the pinned state of the task list window
    ---@param player any - associated player
    function self.toggle_task_list_pinned_open(player)
        -- Invert the boolean
        storage.players[player.index].jolt.ui.is_task_list_pinned_open = 
        not storage.players[player.index].jolt.ui.is_task_list_pinned_open
    end

    --- Returns the selected group in the group management window
    ---@param player any - player associated
    function self.get_group_management_selected_group_id(player)
        local group_id = storage.players[player.index].jolt.ui.selected_group_icon_id
        return group_id
    end

    --- Sets the selected group in the group management window
    ---@param player any - player associated
    ---@param new_id string - new group_id to save
    function self.set_group_management_selected_group_id(player, new_id)
        storage.players[player.index].jolt.ui.selected_group_icon_id = new_id
    end

    --- Clears the selected group in the group management window
    ---@param player any - player associated
    function self.clear_group_management_selected_group_id(player)
        storage.players[player.index].jolt.ui.selected_group_icon_id = nil
    end

    --- Delete all tasks that the player has selected
    ---@param player any - player to get selected tasks from
    function self.delete_selected_tasks(player)
        -- Get the selected tasks
        local selected_tasks = Task_manager.get_selected_tasks(player)
        
        -- Loop through deleting each one
        for task_id, _ in pairs(selected_tasks) do
            self.delete_task(task_id)
        end

        -- Clear selected tasks 
        self.clear_selected_tasks(player)
    end

    --- Save current group selected in group management window
    ---@param player any - player with the window open
    function self.save_current_group(player)
        local screen = player.gui.screen
        local window = screen[constants.jolt.group_management.window_name]
        local main_frame = window[constants.jolt.group_management.main_frame]
        local form_frame = main_frame[constants.jolt.group_management.form_frame]
        local form_container = form_frame[constants.jolt.group_management.form_container]

        -- Get form elements
        local textbox_title = form_container[constants.jolt.group_management.task_title_textbox]
        local icon_button = form_container[constants.jolt.group_management.change_group_icon_button]

        -- Get Values
        local new_name = textbox_title.text
        local elem = icon_button.elem_value

        -- Calculate the type because there are some edge cases :(
        local type

        -- If no 'type' then make it the default of 'item'
        -- (Required for the icon to show up)
        if elem.type == nil then 
            type = "item"
        -- Translate for edge case where it uses 'virtual'
        -- in a choose elem button, but 'virtual-signal' in a sprite (why?)
        elseif elem.type == "virtual" then
            type = "virtual-signal"
        else
            type = elem.type
        end

        -- Combine to make the path
        local new_icon = type .. "/" .. elem.name

        -- Get selected group id
        local group_id = self.get_group_management_selected_group_id(player)
        log("selected group id")
        log (group_id)
        
        -- Params to send to update group function
        local params = {name=new_name, icon=new_icon}

        log("jolt updating group")
        log(group_id)
        log(serpent.block(params))

        -- Update group with new values 
        Task_manager.update_group(params, group_id)
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
