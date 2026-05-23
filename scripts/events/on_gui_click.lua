--- Imports
local TaskManager = require("scripts.task_manager")
local PlayerState = require("scripts.player_state")
local constants = require("constants")
local Gui = require("gui")
local Utils = require("scripts.utils")
local Outcome = require("scripts.outcome")
local VisualActionLog = require("scripts.visual_action_log")

-- Graphical Imports 
local TaskListWindow = require("gui.task_list_window")
local GroupManagerWindow = require("gui.group_manager_window")
local TaskFormWindow = require("gui.task_form_window")


local OnGuiClick = {}

--- When a group is changed in the task list window.
---@param player any target player
function OnGuiClick.group_change_button(player, event)
    -- Save selected group id
    local selected_group_id = event.element.tags.group_id
    PlayerState.set_current_group_id(player, selected_group_id)

    -- Clear selected tasks 
    local selected_tasks = PlayerState.get_selected_tasks(player)
    local data = {tasks = selected_tasks}
    VisualActionLog.add(constants.jolt.actions.cleared_selected_tasks, data)
    PlayerState.clear_selected_tasks(player)

    -- Refresh window
    TaskListWindow.refresh_for_all()
end

function OnGuiClick.toggle_show_completed_checkbox(player)
    -- Invert the setting stored in task manager 
    local old_show_completed = PlayerState.get_setting_show_completed(player)
    PlayerState.set_setting_show_completed(player, not old_show_completed)

    -- clear selected tasks ONLY when toggling off
    if old_show_completed == true then
        PlayerState.clear_selected_tasks(player)
    end

    -- Refresh list of tasks
    TaskListWindow.open(player)

    -- Refresh window
    TaskListWindow.refresh_for_all()
end

--- Tries to add a new task checking the data in the new task window
---@param event any
function OnGuiClick.add_new_task(event)
    local player = game.get_player(event.player_index)

    
    
    -- Get the task data from the form
    local task_data = TaskFormWindow.get_form_data(player)

    -- Fetch the old task data for logging the old group_id
    local old_task_group_id = ""
    local old_task
    if task_data.is_edit_task then
        old_task = Task_manager.get_task(task_data.id)
        old_task_group_id = old_task and old_task.group_id or ""
    end
    

    local outcome = Task_manager.save_task(task_data)

    -- If fails display error and do not close window
    if not outcome.success then

        -- Create "flying text" with error message
        Utils.display_error(player, outcome.message)

    else -- If valid data add task
        -- Log data for editing or adding a new task 
        local action = constants.jolt.actions.added_task
        local task_id
        if task_data.is_edit_task then
            action = constants.jolt.actions.edited_task
            task_id = task_data.id
        else
            task_id = outcome.value
        end

        local group_id = Task_manager.get_parent_group(task_id)

        -- Log the data 
        local data = {task_id = task_id, group_id = group_id}

        -- if editing task, then the group may have changed so 
        -- log it to update both groups in a refresh
        if task_data.is_edit_task and old_task_group_id ~= group_id then
            data.old_group_id = old_task_group_id
        end

        VisualActionLog.add(action, data)

        -- On control keep the window open and clear the form 
        -- But NOT for editing tasks
        if event.control and not task_data.is_edit_task then
            TaskFormWindow.clear_form(player)
            -- TaskFormWindow.open(event, "New Task", nil, {})

        else
            -- Close task form window
            TaskFormWindow.close(player)
        end
        

        -- Refresh data
       TaskListWindow.refresh_for_all()

       return outcome.value
    end
end



--- Watch for clicks on any of the jolt mod gui elements
script.on_event(defines.events.on_gui_click, function(event)
    -- Exit if invalid
    if not Utils.is_element_from_jolt_mod(event) then
        return
    end

    local element = event.element
    local element_name = element.name

    -- Get the player that is interacting with our gui
    local player = game.get_player(event.player_index)
    -- Save last interacted with task (to be able to scroll to it later)
    -- in separate "if" statement so it doesn't block other interactions
    if event.element.tags.task_id then
        -- save task id
        PlayerState.save_last_interacted_task_id(player, event.element.tags.task_id)
    end

    -- Check if element is a close button for one of jolt's windows
    local window_name = PlayerState.pop_close_button(player, element_name)

    -- If it is then attempt to close the window
    if window_name ~= nil then
        -- Check if the frame still exists before destroying
        if player.gui.screen[window_name] and player.gui.screen[window_name].valid then
            player.gui.screen[window_name].destroy()

            -- Update state of shortcut
            if window_name == constants.jolt.task_list.window then
                player.set_shortcut_toggled(constants.jolt.shortcuts.open_task_list_window, false)
            end
            
        end

        -- When closing group management, clear the selected group 
        -- (so the window opens with nothing selected)
        if window_name == constants.jolt.group_management.window_name then
            PlayerState.clear_group_management_selected_group_id(player)
        end

        -- clear selected tasks
        PlayerState.clear_selected_tasks(player)

    -- Keep open button is pressed
    elseif element_name == constants.jolt.task_list.keep_window_open_button then

        -- toggle the keep open state
        PlayerState.toggle_task_list_pinned_open(player)

        -- Refresh window 
       TaskListWindow.open(player)

    -- Open new task window when Add task button clicked
    elseif element_name == constants.jolt.task_list.add_task_button then
        -- clear selected tasks
        PlayerState.clear_selected_tasks(player)

        -- Refresh list of tasks
        TaskListWindow.refresh_for_all()

        -- open window to add a new task
        -- TaskFormWindow.open(event, "New Task", nil, {})
        TaskFormWindow.open(player, {})

    -- Move selected task(s) up
    elseif element_name == constants.jolt.task_list.move_task_up_button then

        -- Move the selected tasks
        Task_manager.move_selected_tasks(player, Direction.Up)

        -- Log movement 
        local data = {group_id = PlayerState.get_current_group_id(player)}
        VisualActionLog.add(constants.jolt.actions.moved_tasks_up, data)

        -- Refresh list of tasks
       TaskListWindow.refresh_for_all()

    -- Move selected task(s) down
    elseif element_name == constants.jolt.task_list.move_task_down_button then
        
        -- Move the selected tasks
        Task_manager.move_selected_tasks(player, Direction.Down)

        -- Log movement 
        local data = {group_id = PlayerState.get_current_group_id(player)}
        VisualActionLog.add(constants.jolt.actions.moved_tasks_down, data)

        -- Refresh list of tasks
       TaskListWindow.refresh_for_all()

    -- Move selected task(s) down
    elseif element_name == constants.jolt.task_list.delete_tasks_button then

        -- Log tasks deleted 
        local data = {tasks = PlayerState.get_selected_tasks(player), group_id = PlayerState.get_current_group_id(player)}
        VisualActionLog.add(constants.jolt.actions.deleted_tasks, data)

        -- Delete the selected tasks
        Task_manager.delete_selected_tasks(player)

        -- Clear selected tasks 
        PlayerState.clear_selected_tasks(player)

        -- Refresh list of tasks
       TaskListWindow.refresh_for_all()

    -- Add a new task confirm button clicked
    elseif element_name == constants.jolt.new_task.confirm_button then
        OnGuiClick.add_new_task(event)

    -- If confirm button for edit task was clicked edit the task 
    elseif element_name == constants.jolt.edit_task.confirm_button then
        OnGuiClick.add_new_task(event)

    -- Edit task when edit button clicked 
    elseif element_name == constants.jolt.task_list.edit_task_button then
        -- Get the stored task id from tags 
        local task_id = event.element.tags.task_id

        -- Get the task 
        local task = Task_manager.get_task(task_id)

        -- Open the new task window with pre-filled data 
        -- IMPORTANT: need to use params or their is bug that a new task will be 
        -- created when editing a task.
        local params = {
            title = task.title,
            group_id = task.group_id,
            description = task.description,
            task_id = task_id,
            status = task.status,
            parent_id = task.parent_id,
            coordinates = task.coordinates,
            surface_index = task.surface_index,
        }
        TaskFormWindow.open(player, params)


    -- Task checkbox clicked to select or mark complete / uncomplete 
    elseif element_name == constants.jolt.task_list.task_checkbox then
        -- Get the stored task id from tags 
        local task_id = event.element.tags.task_id

        -- check for ctrl+click 
        if event.control then
            -- Add selected task to list
            -- Note: (non sibling tasks will not be added)
            local outcome = PlayerState.add_selected_task(player, task_id)

            -- Check if it succeeded
            if outcome.success then
                -- Log the action
                local data = {task_id = task_id}
                VisualActionLog.add(constants.jolt.actions.selected_task, data)
            else
                -- Display error message
                Utils.display_error(player, outcome.message)
            end
        
        else -- Otherwise mark mark complete / uncomplete 
            -- clear selected tasks 
            PlayerState.clear_selected_tasks(player)

            -- Mark the task complete/incomplete
            Task_manager.toggle_task_completed(task_id)

            -- Log action so we know what task to update
            local data = {task_id = task_id}
            VisualActionLog.add(constants.jolt.actions.updated_task_completed_status, data)
        end

        -- Refresh window
        TaskListWindow.refresh_for_all()

    -- Toggle viewing completed/incomplete tasks 
    elseif element_name == constants.jolt.task_list.show_completed_checkbox then
        OnGuiClick.toggle_show_completed_checkbox(player)

    -- Toggle details for individual task
    elseif element_name == constants.jolt.task_list.toggle_details_button then
        -- Get the task 
        local task_id = event.element.tags.task_id
        local task = Task_manager.get_task(task_id)

        -- invert property to mark that details should be shown/hidden
        local task_show_details = PlayerState.get_task_show_details(player, task.id)
        PlayerState.set_task_show_details(player, task.id, not task_show_details)
        
        -- Log the task_id and action
        local data = {task_id = task_id}
        VisualActionLog.add(constants.jolt.actions.updated_show_task_details_status, data)

        -- Refresh list of tasks
       TaskListWindow.refresh_for_all()
    
    -- On click of the "+ Subtask" button 
    elseif element_name == constants.jolt.task_list.add_subtask_button then
        -- Get the task 
        local task_id = event.element.tags.task_id
        local task = Task_manager.get_task(task_id)

        -- Open the add task window
        local subtitle = {"jolt_task_list_window.label_subtask_of", task.title}
        local subtask = {}
        subtask.parent_id = task.id
        -- TaskFormWindow.open(event, "New Subtask", subtitle, subtask)
        TaskFormWindow.open(player, subtask)
        

    -- If selected an tab group icon button change the tasks
    elseif event.element.tags.is_group_change_button then
        OnGuiClick.group_change_button(player, event)

    -- Group Management button
    elseif element_name == constants.jolt.group_management.open_window_button then
        -- If the window is already open close it
        if player.gui.screen[constants.jolt.group_management.window_name] then
            -- clear the selected group 
            PlayerState.clear_group_management_selected_group_id(player)

            -- close the window
            player.gui.screen[constants.jolt.group_management.window_name].destroy()
        else -- otherwise open the group management window
            GroupManagerWindow.open(player)
        end
        

    -- Group Management button 
    elseif element_name == constants.jolt.group_management.add_new_group_icon_button then
        -- Add group with template data and open window
        -- !! Use "virtual-signal" and not "virtual" for sprites
        local group = {name="", icon="virtual-signal/signal-question-mark"}
        local new_group_id = Task_manager.add_group(group)

        -- If new group id is nil then display an error 
        if not new_group_id then
            local max_groups_error_message =  {"jolt_group_management.error_max_groups_reached"}
            Utils.display_error(player, max_groups_error_message)
        else
            -- Make it the currently selected group
            PlayerState.set_group_management_selected_group_id(player, new_group_id)

            -- Refresh windows
           TaskListWindow.refresh_for_all()
           GroupManagerWindow.refresh_for_all()
        end


    -- Delete selected group
    elseif element_name ==  constants.jolt.group_management.delete_group then
        -- Get group id
        local group_id = PlayerState.get_group_management_selected_group_id(player)

        -- If tasks in group show warning
        local task_count = Task_manager.count_tasks_for_group(group_id)

        -- If group has tasks in it, show warning
        if task_count > 0 then
            -- Make the new window and set close button
            -- Setup options for the new window
            local options = {
                width = constants.jolt.warning_window.width,
                height = constants.jolt.warning_window.height,
                player = player,
                window_name = constants.jolt.delete_group.window_name,
                window_title = {"jolt_group_management.confirm_delete_window_title"},
                back_button_name = constants.jolt.delete_group.back_button,
                confirm_button_name = constants.jolt.delete_group.confirm_button,
            }
            -- Open new confirmation dialog window
            local confirm_delete_window = Gui.new_dialog_window(options)

            -- Add event to watch for button click to close the window
            PlayerState.bind_close_button(player, options.back_button_name, options.window_name)

            -- Confirm delete button
            local confirm_delete_frame = confirm_delete_window.add {
                type = "frame",
                direction = "vertical",
                index = 2,
                style = "jolt_content_frame"
            }

            -- Get from en.cfg for translation reasons
            local message = {"jolt_group_management.confirm_delete_group_warning_message", task_count, task_count > 1}

            -- Label to hold warning message
            local confirm_delete_label = Gui.new_label(confirm_delete_frame, message, player)

            -- Force onto multiple lines
            confirm_delete_label.style.single_line = false
        else -- If group has no tasks delete it without a warning
        
            -- Delete group
            local is_deleted = Task_manager.delete_group(group_id)

            -- Display error if it fails and returns false
            if not is_deleted then
                local min_groups_error_message = {"jolt_group_management.error_min_groups_reached"}
                Utils.display_error(player, min_groups_error_message)
            end

            -- Refresh windows
           TaskListWindow.refresh_for_all()
           GroupManagerWindow.refresh_for_all()
           GroupManagerWindow.open(player)
        end

    -- Confirm deleted group button
    elseif element_name ==  constants.jolt.delete_group.confirm_button then
        -- Get group id
        local group_id = PlayerState.get_group_management_selected_group_id(player)

        -- Delete group
        local is_deleted = Task_manager.delete_group(group_id)

        -- Display error if it fails and returns false
        if not is_deleted then
            local min_groups_error_message = {"jolt_group_management.error_min_groups_reached"}
            Utils.display_error(player, min_groups_error_message)
        end

        -- Refresh windows
       TaskListWindow.refresh_for_all()
       GroupManagerWindow.refresh_for_all()

        -- Close confirmation window
        player.gui.screen[constants.jolt.delete_group.window_name].destroy()

    -- If selected an group icon button in the group management window
    elseif event.element.tags.is_group_management_icon_button then
        -- Save new selected group id 
        local selected_group_id = event.element.tags.group_id
        PlayerState.set_group_management_selected_group_id(player, selected_group_id)

        -- Refresh windows
       TaskListWindow.refresh_for_all()
       GroupManagerWindow.refresh_for_all()

    -- Move group left button
    elseif element_name == constants.jolt.group_management.move_group_left then
        -- Get current selected group
        local group_id = PlayerState.get_group_management_selected_group_id(player)

        -- save group changes to prevent them being lost
        Task_manager.save_current_group(player)

        -- Swap with the previous
        Task_manager.move_group_left(group_id)

        -- Refresh windows
       TaskListWindow.refresh_for_all()
       GroupManagerWindow.refresh_for_all()

    -- Move group right button
    elseif element_name == constants.jolt.group_management.move_group_right then
        -- Get current selected group
        local group_id = PlayerState.get_group_management_selected_group_id(player)

        -- save group changes to prevent them being lost
        Task_manager.save_current_group(player)

        -- Swap with the next
        Task_manager.move_group_right(group_id)

        -- Refresh windows
       TaskListWindow.refresh_for_all()
       GroupManagerWindow.refresh_for_all()

    -- Save group button 
    elseif element_name == constants.jolt.group_management.btn_save_group then
        
        -- Go through element tree to get to the form_container
        local player = game.get_player(event.player_index)

        Task_manager.save_current_group(player)

        -- Refresh windows
       TaskListWindow.refresh_for_all()
       GroupManagerWindow.refresh_for_all()

    -- Go to Location button in task list
    elseif element_name == constants.jolt.task_list.location_button then

        -- Get location from task
        local task = Task_manager.get_task(event.element.tags.task_id)
        local position = task.coordinates
        local surface_index = task.surface_index
        local surface

        -- check if task has no surface
        if surface_index then
            surface = game.get_surface(surface_index)
        end

        -- check that surface exists 
        if not surface or not surface.valid then
            -- game.print("surface not found")
        else
            -- Go to location
            player.set_controller({type = defines.controllers.remote, position = position, surface = surface})
        end
        
    elseif element_name == constants.jolt.new_task.set_location_button then

        -- hide the task form before opening map
        local window = player.gui.screen[constants.jolt.new_task.window]
        if window then window.visible = false end

        -- give the player a tool to pick the new location
        player.cursor_stack.set_stack({ name = constants.jolt.tools.location_selector, count = 1 })

        -- Open the map where the player is
        player.set_controller({
            type = defines.controllers.remote,
            position = player.position,
            surface = player.surface})
        
        -- save the task id to the player state since can't pass it to an event
        local element = event.element
        if not element or not element.valid then return end
        local task_id = element.tags.task_id
        PlayerState.save_task_id_for_task_location(player, task_id)
        
        -- Continued in "events.on_player_selected_area"
    end
end)

return OnGuiClick