--- control.lua

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

-- Window width and height constants
local TASK_LIST_MAX_WINDOW_HEIGHT = 600
local AUTO_SCALE_WINDOW_HEIGHT = 0
local TASK_LIST_WINDOW_WIDTH = 400

local WARNING_WINDOW_WIDTH = 300
local WARNING_WINDOW_HEIGHT = 180
local SUBTITLE_MAX_WIDTH = TASK_LIST_WINDOW_WIDTH - 130


--region =======Debug Functions=======

--- Print table information
---@param player any - player to enter this to the chat
---@param table table - the table to print
local function printTable(player, table)
    for key, value in pairs(table) do
        if type(value) == "table" then
            player.print(key .. ":")
            printTable(player, value)  -- Recursively print nested tables
        else
            player.print(key .. ": " .. tostring(value))
        end
    end
end

--- Function to print provided table
---@param event any
---@param message table - a string or table to display in chat
local function debug_print(event, message)
    local player = game.get_player(event.player_index)
    if type(message) == "table" then
        printTable(player, message)
    else
        player.print(message)
    end
end

--endregion =======Debug Functions=======

--region =======Local Functions=======
--- IMPORTANT put local functions before where they are used!!!


--- Tries to add a new task checking the data in the new task window
---@param event any
local function add_new_task(event)
    local player = game.get_player(event.player_index)
    
    -- Get the task data from the form
    local task_data = TaskFormWindow.get_form_data(player)

    local outcome = Task_manager.save_task(task_data)

    -- If fails display error and do not close window
    if not outcome.success then

        -- Create "flying text" with error message
        player.create_local_flying_text {
            text = outcome.message,
            create_at_cursor=true,
        }

    else -- If valid data add task

        -- Close task form window
        TaskFormWindow.close(player)

        -- Refresh data
       TaskListWindow.refresh(player)
    end
end


--endregion =======Local Functions=======



-- Make sure the intro cinematic of freeplay doesn't play every time we restart
-- This is just for convinience, don't worry if you don't understand how this works
-- See on_init() section in https://wiki.factorio.com/Tutorial:Scripting
-- Only runs when a new game is created https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_init
script.on_init(function()
    -- TODO comment out before release
    -- local freeplay = remote.interfaces["freeplay"]
    -- if freeplay then -- Disable freeplay popup-message
    --     if freeplay["set_skip_intro"] then
    --         remote.call("freeplay", "set_skip_intro", true)
    --     end
    --     if freeplay["set_disable_crashsite"] then
    --         remote.call("freeplay", "set_disable_crashsite", true)
    --     end
    -- end

    -- Setup default group(s) (store data! not objects/functions)
    -- AVOID using space age specific icons as it will crash in the base game
    local nauvis_group = {id="a1", name="Nauvis", icon="space-location/nauvis"}
    local default_group_data = {}
    default_group_data[nauvis_group.id] = nauvis_group
    local default_group_order = {"a1"}


    -- store data for groups, tasks 
    -- IMPORTANT: Can only store data not functions. So no putting an object here
    -- https://lua-api.factorio.com/latest/auxiliary/storage.html
    storage.jolt = storage.jolt or {
        tasks = {},
        groups = default_group_data,
        priorities = {},
        group_order = default_group_order,
        visual_action_log = {
            entries = {},
        }
    }

    -- store players and their info
    storage.players = storage.players or {}

    -- setup the task manager 
    Task_manager = TaskManager.new()

    -- setup visual log 
    VisualActionLog.initialize()
end)




--- Runs when mod configuration changes (adding a mod or updating a mod)
--- https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_configuration_changed
---@param event any
script.on_configuration_changed(function(event)
    -- setup visual log if needed
    VisualActionLog.initialize()

    -- Migrate old data structure to new one
    if storage.task_data and not storage.jolt then
        log("jolt: migrating old data structure")
        storage.jolt = storage.task_data
        storage.task_data = nil
    end

    -- Migrate per-player data
    if storage.players then
        for _, player in pairs(game.players) do
            local p = storage.players[player.index]
            if p then
                -- Migrate old flat structure to new jolt.ui namespace
                if not p.jolt then
                    p.jolt = {
                        ui = {
                            selected_tasks = p.selected_tasks or {},
                            selected_group_tab_id = p.selected_group_tab_id or storage.jolt.group_order[1],
                            saved_window_locations = p.settings and p.settings.saved_window_locations or {},
                            close_button_registry = p.settings and p.settings.close_button_registry or {},
                            is_task_list_pinned_open = p.settings and p.settings.is_task_list_pinned_open or false,
                            selected_group_icon_id = nil,
                            last_interacted_task_id = nil,
                            show_completed_tasks = false,
                        }
                    }
                    -- Clean up old keys
                    p.selected_tasks = nil
                    p.selected_group_tab_id = nil
                    p.settings = nil
                end
            else
                PlayerState.initialize(player.index)
            end
        end
    end

    -- Close windows for all players 
    for _, player in pairs(game.players) do
        TaskListWindow.close(player)
        TaskFormWindow.close(player)
        GroupManagerWindow.close(player)
    end
    
end)

--- Called when a new player is created
--- Initialize all needed data and set defaults
--- https://lua-api.factorio.com/latest/events.html#on_player_created
script.on_event(defines.events.on_player_created, function(event)
    -- Initialize data for the player
    PlayerState.initialize(event.player_index)

end)

-- Runs when a saved game is loaded
-- https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_load
script.on_load(function ()
    -- Since on_init() only runs for new games re-declare it here 
    -- so we can use it for saved games
    Task_manager = TaskManager.new()
    -- Note: TaskManager.new() loads in the save data itself
end)

--- Watch for clicks on the task shortcut icon to open and close
--- the task list window
script.on_event(defines.events.on_lua_shortcut, function(event)
    -- Only react for the jolt shortcut button
    if event.prototype_name == constants.jolt.shortcuts.open_task_list_window then
        local player = game.get_player(event.player_index)

        -- If the window is already open close it
        if player.gui.screen[constants.jolt.task_list.window] then
            TaskListWindow.close(player)
        else -- otherwise open the task list window
            TaskListWindow.open(event)
        end
    end
end) -- end on_lua_shortcut


--- Called when a LuaGuiElement is confirmed, for example by pressing 
--- Enter in a textfield.
--- https://lua-api.factorio.com/latest/events.html#on_gui_confirmed
script.on_event(defines.events.on_gui_confirmed, function(event)
    -- Exit if invalid
    local element = event.element
    if not element or not element.valid then return end
    local element_name = event.element.name

    -- Early exit: ignore elements that don't belong to the jolt mod
    if not element_name or not element_name:find("^jolt") then
        --TIP: uncomment below to debug naming issues
        -- debug_print(event, "elementName = " .. element_name)
        return
    end

    -- Add a new task when pressing [Enter] in the title textbox
    if element_name == constants.jolt.new_task.title_textbox then
        add_new_task(event)
    end
end)

--- Watch for clicks on any of the jolt mod gui elements
script.on_event(defines.events.on_gui_click, function(event)
    -- Exit if invalid
    local element = event.element
    if not element or not element.valid then return end

    local element_name = event.element.name

    --[[
    IMPORTANT: for a gui element to be detected it must either have an 
                element name with the prefix "jolt" 
                
                OR have the tag "is_jolt = true"

        Example: 

        local icon_button = button_table.add{
            type="sprite-button",
            sprite=group.icon,
            style="slot_button",
            -- Add tags since can't use the same name for each
            -- but can check tag for group_mgnmt_btn and then get group_id
            tags = {is_jolt = true, is_group_management_icon_button=true, group_id=group.id}
        }
    ]]--

    -- Early exit: ignore elements that don't belong to me
    if event.element.tags and event.element.tags.is_jolt or element_name:find("^jolt") then
        --TIP: uncomment below to debug naming issues
        -- is our gui element so continue
    else
        -- debug_print(event, "tags is jolt = " )
        -- debug_print(event, event.element.tags.is_jolt)
        return
    end

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
       TaskListWindow.open(event)

    -- Open new task window when Add task button clicked
    elseif element_name == constants.jolt.task_list.add_task_button then
        -- clear selected tasks
        PlayerState.clear_selected_tasks(player)

        -- Refresh list of tasks
        TaskListWindow.refresh(player)

        -- open window to add a new task
        TaskFormWindow.open(event, "New Task", nil, {})

    -- Move selected task(s) up
    elseif element_name == constants.jolt.task_list.move_task_up_button then

        -- Move the selected tasks
        Task_manager.move_selected_tasks(player, Direction.Up)

        -- Refresh list of tasks
       TaskListWindow.open(event)

    -- Move selected task(s) down
    elseif element_name == constants.jolt.task_list.move_task_down_button then
        
        -- Move the selected tasks
        Task_manager.move_selected_tasks(player, Direction.Down)

        -- Refresh list of tasks
       TaskListWindow.open(event)

    -- Move selected task(s) down
    elseif element_name == constants.jolt.task_list.delete_tasks_button then

        -- Delete the selected tasks (also clears the selected tasks)
        Task_manager.delete_selected_tasks(player)

        -- Refresh list of tasks
       TaskListWindow.open(event)

    -- Add a new task confirm button clicked
    elseif element_name == constants.jolt.new_task.confirm_button then
        add_new_task(event)

    -- If confirm button for edit task was clicked edit the task 
    elseif element_name == constants.jolt.edit_task.confirm_button then
        add_new_task(event)

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
            parent_id = task.parent_id,
        }
        TaskFormWindow.open(event, "Edit Task", nil, params)

    -- Task checkbox clicked to select or mark complete / uncomplete 
    elseif element_name == constants.jolt.task_list.task_checkbox then
        -- Get the stored task id from tags 
        local task_id = event.element.tags.task_id

        -- check for ctrl+click 
        if event.control then
            -- Add selected task to list
            -- Note: (non sibling tasks will not be added)
            local outcome = PlayerState.add_selected_task(player, task_id)

            -- Check if it did not succeed
            if not outcome.success then
                -- Display error message
                Utils.display_error(player, outcome.message)
            end

            -- Refresh list of tasks
            TaskListWindow.refresh(player)
        --    TaskListWindow.open(event)
        
        else -- Otherwise mark mark complete / uncomplete 
            -- clear selected tasks 
            PlayerState.clear_selected_tasks(player)

            -- Mark the task complete/incomplete
            Task_manager.toggle_task_completed(task_id)

            -- Refresh window
            TaskListWindow.refresh(player)
        end

    -- Toggle viewing completed/incomplete tasks 
    elseif element_name == constants.jolt.task_list.show_completed_checkbox then
        -- Invert the setting stored in task manager 
        local show_completed = PlayerState.get_setting_show_completed(player)
        PlayerState.set_setting_show_completed(player, not show_completed)

        -- Refresh list of tasks
       TaskListWindow.open(event)

    -- Toggle details for individual task
    elseif element_name == constants.jolt.task_list.toggle_details_button then
        -- Get the task 
        local task_id = event.element.tags.task_id
        local task = Task_manager.get_task(task_id)

        -- invert property to mark that details should be shown/hidden
        task.show_details = not task.show_details
        local data = {task_id = task_id}
        VisualActionLog.add(constants.jolt.actions.updated_show_task_details_status, data)

        -- Refresh list of tasks
       TaskListWindow.refresh(player)
    
    -- On click of the "+ Subtask" button 
    elseif element_name == constants.jolt.task_list.add_subtask_button then
        -- Get the task 
        local task_id = event.element.tags.task_id
        local task = Task_manager.get_task(task_id)

        -- Open the add task window
        local subtitle = {"jolt_task_list_window.label_subtask_of", task.title}
        local subtask = {}
        subtask.parent_id = task.id
        TaskFormWindow.open(event, "New Subtask", subtitle, subtask)

    -- If selected an tab group icon button change the tasks
    elseif event.element.tags.is_group_change_button then
        -- Save selected group id
        local selected_group_id = event.element.tags.group_id
        PlayerState.set_current_group_id(player, selected_group_id)

        -- Clear selected tasks 
        PlayerState.clear_selected_tasks(player)

        -- Refresh window
        TaskListWindow.refresh(player)

    -- Group Management button
    elseif element_name == constants.jolt.group_management.open_window_button then
        -- If the window is already open close it
        if player.gui.screen[constants.jolt.group_management.window_name] then
            -- clear the selected group 
            PlayerState.clear_group_management_selected_group_id(player)

            -- close the window
            player.gui.screen[constants.jolt.group_management.window_name].destroy()
        else -- otherwise open the group management window
            GroupManagerWindow.open(event)
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
           TaskListWindow.open(event)
           GroupManagerWindow.open(event)
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
                width = WARNING_WINDOW_WIDTH,
                height = WARNING_WINDOW_HEIGHT,
                player = player,
                window_name = constants.jolt.delete_group.window_name,
                window_title = {"jolt_group_management.confirm_delete_window_title"},
                back_button_name = constants.jolt.delete_group.back_button,
                confirm_button_name = constants.jolt.delete_group.confirm_button
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
           TaskListWindow.open(event)
           GroupManagerWindow.open(event)
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
       TaskListWindow.open(event)
       GroupManagerWindow.open(event)

        -- Close confirmation window
        player.gui.screen[constants.jolt.delete_group.window_name].destroy()

    -- If selected an group icon button in the group management window
    elseif event.element.tags.is_group_management_icon_button then
        -- Save new selected group id 
        local selected_group_id = event.element.tags.group_id
        PlayerState.set_group_management_selected_group_id(player, selected_group_id)

        -- Refresh windows
       TaskListWindow.open(event)
       GroupManagerWindow.open(event)

    -- Move group left button
    elseif element_name == constants.jolt.group_management.move_group_left then
        -- Get current selected group
        local group_id = PlayerState.get_group_management_selected_group_id(player)

        -- save group changes to prevent them being lost
        Task_manager.save_current_group(player)

        -- Swap with the previous
        Task_manager.move_group_left(group_id)

        -- Refresh windows
       TaskListWindow.open(event)
       GroupManagerWindow.open(event)

    -- Move group right button
    elseif element_name == constants.jolt.group_management.move_group_right then
        -- Get current selected group
        local group_id = PlayerState.get_group_management_selected_group_id(player)

        -- save group changes to prevent them being lost
        Task_manager.save_current_group(player)

        -- Swap with the next
        Task_manager.move_group_right(group_id)

        -- Refresh windows
       TaskListWindow.open(event)
       GroupManagerWindow.open(event)

    -- Save group button 
    elseif element_name == constants.jolt.group_management.btn_save_group then
        
        -- Go through element tree to get to the form_container
        local player = game.get_player(event.player_index)

        Task_manager.save_current_group(player)
        

        -- Refresh windows
       TaskListWindow.open(event)
       GroupManagerWindow.open(event)
    end
end)


--- Called when a window is moved
--- save locations to make window locations persistent
script.on_event(defines.events.on_gui_location_changed, function(event)
    -- Get player
    local player = game.get_player(event.player_index)

    -- Get new location
    local new_location = event.element.location
    
    -- Save new location to storage
    -- storage.players[event.player_index].saved_window_locations[event.element.name] = new_location
    PlayerState.save_window_location(player, event.element.name, new_location)
end)

--- Called when the player closes the GUI they have open.
--- can set player.opened = window_name_open 
--- this will then close the window when 'e' is pressed
--- https://lua-api.factorio.com/latest/events.html#on_gui_closed
---@param event any
script.on_event(defines.events.on_gui_closed, function(event)
    if not event.element then return end
    local player = game.get_player(event.player_index)
    local window_name = event.element.name

    -- Do not continue if it is not a window from JOLT
    if not Task_manager.is_jolt_window(window_name) then return end

    -- Don't close if task_list window and it is pinned open 
    if window_name == constants.jolt.task_list.window and PlayerState.is_task_list_pinned_open(player) then
        return
    end

    -- Close the window
    if event.element.valid then event.element.destroy() end
    
    -- Can run run cleanup specific to that window (see also section in on_gui_click)
    if window_name == constants.jolt.group_management.window_name then
    end
    if window_name == constants.jolt.task_list.window_name then
        PlayerState.clear_selected_tasks(player)
    end
end)
