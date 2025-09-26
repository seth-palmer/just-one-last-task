--- control.lua

--- Imports
local TaskManager = require("scripts.task_manager")
local constants = require("constants")
require("gui")

local windows_to_close = {}

--region =======Local Functions=======
--- IMPORTANT put local functions before where they are used!!!

--- Opens the group management window
---@param event any
local function open_group_management_window(event)
    local player = game.get_player(event.player_index)
    local title = {"jolt_group_management.window_title"}
    local window_name = constants.jolt.group_management.window_name
    local close_name = constants.jolt.group_management.close_button
    local window = new_window(player, title, window_name, close_name, 400, 500)

    -- Add event to watch for button click to close the window
    windows_to_close[close_name] = window_name

    
    -- Display icon for each group
    local button_frame = window.add{
        type="frame",
        name="button_frame",
        direction="horizontal",
        style="ugg_deep_frame"
    }

    local max_col_count = 5
    local button_table = button_frame.add{
        type="table",
        name="button_table",
        column_count=max_col_count,
        style="filter_slot_table"
    }
    
    -- local button_table = player.gui.screen.ugg_main_frame.content_frame.button_frame.button_table
    -- button_table.clear()

    -- Add each group
    local groups = task_manager.get_groups()
    -- Example: local nauvis_group = {id=1, name="Nauvis", icon="space-location/nauvis"}

    for index, value in ipairs(groups) do
        button_table.add{type="sprite-button", sprite=value.icon, style="slot_button"}
    end

    button_table.add{type="sprite-button", sprite=constants.jolt.sprites.add, style="slot_button"}

    -- Edit form in the bottom half of the window
    local form_table = window.add{
        type="table",
        column_count=2,
    }
    
    -- Label "Title" and textbox input
    local label = form_table.add {type = "label", caption = "Title:"}
    local task_title_textbox = form_table.add {
        type = "textfield",
        -- name = constants.jolt.new_task.title_textbox,
        text = "",
        style = constants.styles.form.textfield
    }

    -- Icon for group
    local label = form_table.add {type = "label", caption = "Icon:"}
    form_table.add{type="sprite-button", sprite=constants.jolt.sprites.edit, style="slot_button"}

    -- Position buttons - to change selected group position
    form_table.add {type = "label", caption = "Position:"}
    form_table.add {type = "label", caption = ""} -- skip this row
    form_table.add {
        type = "sprite-button",
        sprite = constants.jolt.sprites.expand,
        name = constants.jolt.group_management.move_group_up,
        tooltip = {"jolt_group_management.tooltip_move_group_up"},
    }
    form_table.add {
        type = "sprite-button",
        sprite = constants.jolt.sprites.collapse,
        name = constants.jolt.group_management.move_group_right,
        tooltip = {"jolt_group_management.tooltip_move_group_right"},
    }
    form_table.add {
        type = "sprite-button",
        sprite = constants.jolt.sprites.expand,
        name = constants.jolt.group_management.move_group_down,
        tooltip = {"jolt_group_management.tooltip_move_group_down"},
    }
    form_table.add {
        type = "sprite-button",
        sprite = constants.jolt.sprites.collapse,
        name = constants.jolt.group_management.move_group_left,
        tooltip = {"jolt_group_management.tooltip_move_group_left"},
    }





    -- Add row for controls 
    local controls_container = window.add {
        type = "frame",
        name = "jolt_controls_container",
        direction = "horizontal",
        style = "subheader_frame"
    }

    -- Cancel button
    local btn_cancel = controls_container.add {
        type = "button",
        caption = "Cancel",
        tooltip = {"jolt_group_management.tooltip_cancel"},
    }

    -- Empty space
    local empty_space = controls_container.add {
        type = "empty-widget",
    }
    -- Make it expand to fill the space
    empty_space.style.minimal_width = 50
    empty_space.style.height = 24
    empty_space.style.horizontally_stretchable = true

    -- Delete group button
    local btn_delete_group = controls_container.add {
        type = "sprite-button",
        name = constants.jolt.group_management.delete_group,
        style = constants.styles.buttons.red,
        sprite = constants.jolt.sprites.delete,
        tooltip = {"jolt_group_management.tooltip_delete_group"},
    }

    -- Empty space
    local empty_space = controls_container.add {
        type = "empty-widget",
    }
    -- Make it expand to fill the space
    empty_space.style.minimal_width = 50
    empty_space.style.height = 24
    empty_space.style.horizontally_stretchable = true

    -- Save button
    local btn_save_group = controls_container.add {
        type = "button",
        caption = "Save",
        tooltip = {"jolt_group_management.tooltip_save"},
    }

    

    


end

--endregion

local checkbox_default_state_add_to_top = false

--region =======Seed Data=======

    -- TODO remove seed data
    -- Add temporary seed data (will add more on each launch of the menu)

    -- local t1Params = {title="Red Science", groupId=1, description="Automate 5/sec"}
    -- local t2Params = {title="Green Science", groupId=1, description="Automate 5/sec"}
    -- local t3Params = {title="Millitary Science", groupId=1, description="Automate 5/sec"}
    -- local t4Params = {title="Build Hubble Space Platform", groupId=2}

    
    -- task_manager.add_task(t1Params, 1, true)
    -- task_manager.add_task(t2Params, 1, true)
    -- task_manager.add_task(t3Params, 1, true)
    -- task_manager.add_task(t4Params, 2, true)
    --endregion


-- Make sure the intro cinematic of freeplay doesn't play every time we restart
-- This is just for convinience, don't worry if you don't understand how this works
-- See on_init() section in https://wiki.factorio.com/Tutorial:Scripting
-- Only runs when a new game is created https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_init
script.on_init(function()
    local freeplay = remote.interfaces["freeplay"]
    if freeplay then -- Disable freeplay popup-message
        if freeplay["set_skip_intro"] then
            remote.call("freeplay", "set_skip_intro", true)
        end
        if freeplay["set_disable_crashsite"] then
            remote.call("freeplay", "set_disable_crashsite", true)
        end
    end

    --Default groups (store data! not objects/functions)
    local nauvis_group = {id=1, name="Nauvis", icon="space-location/nauvis"}
    local space_group = {id=2, name="Space", icon="item/thruster"}

    local default_group_data = {}
    default_group_data[1] = nauvis_group
    default_group_data[2] = space_group

    -- store players and their info
    storage.players = storage.players or {}

    -- TODO 
    -- store data for groups, tasks 
    -- IMPORTANT: Can only store data not functions. So no putting an object here
    -- https://lua-api.factorio.com/latest/auxiliary/storage.html
    storage.task_data = storage.task_data or {
        tasks = {},
        groups = default_group_data,
        priorities = {},
    }
    task_manager = TaskManager.new()
end)

-- Runs when a saved game is loaded
-- https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_load
script.on_load(function ()
    -- Since on_init() only runs for new games re-declare it here 
    -- so we can use it for saved games
    task_manager = TaskManager.new()
end)

--- Watch for clicks on the task shortcut icon to open and close
--- the task list window
script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == constants.jolt.shortcuts.open_task_list_window then
        local player = game.get_player(event.player_index)
        if player.gui.screen[constants.jolt.task_list.window] then
            close_task_list_menu(event)
        else
            open_task_list_menu(event)
        end
    end

end) -- end on_lua_shortcut

--- Close the task list menu
function close_task_list_menu(event)
    local player = game.get_player(event.player_index)
    player.gui.screen[constants.jolt.task_list.window].destroy()
end



--- Watch for clicks on gui elements for my mod (prefix "jolt_tasks") icon
script.on_event(defines.events.on_gui_click, function(event)
    local element_name = event.element.name
    
    --TODO useful to debug naming issues
    -- debug_print(event, "elementName = " .. element_name)

    -- Close my windows looking in dictionary to check if
    -- it is one of my windows
    local window_name = windows_to_close[element_name]
    if window_name ~= nil then
        local player = game.get_player(event.player_index)

        -- Check if the frame still exists before destroying
        if player.gui.screen[window_name] and player.gui.screen[window_name].valid then
            player.gui.screen[window_name].destroy()
        end

        -- Clean up the mapping
        windows_to_close[element_name] = nil

    -- Open new task window when Add task button clicked
    elseif element_name == constants.jolt.task_list.add_task_button then
        open_task_form_window(event, "New Task", nil, {})

    -- Add a new task confirm button clicked
    elseif element_name == constants.jolt.new_task.confirm_button then
        add_new_task(event)

    -- If confirm button for edit task was clicked edit the task 
    elseif element_name == constants.jolt.edit_task.confirm_button then
        add_new_task(event, true)

    -- Edit task when edit button clicked 
    elseif element_name == constants.jolt.task_list.edit_task_button then
        -- Get the stored task id from tags 
        local task_id = event.element.tags.task_id

        -- Get the task 
        local task = task_manager.get_task(task_id)

        -- Open the new task window with pre-filled data 
        local params = {
            title = task.title,
            group_id = task.group_id,
            task_id = task_id,
        }
        open_task_form_window(event, "Edit Task", nil, params)

    -- Task checkbox clicked mark complete / uncomplete 
    elseif element_name == constants.jolt.task_list.task_checkbox then
         -- Get the stored task id from tags 
        local task_id = event.element.tags.task_id

        -- Get the task 
        local task = task_manager.get_task(task_id)

        -- Invert completed status 
        task.is_complete = not task.is_complete

        -- Refresh list of tasks (Is this inefficient?)
        open_task_list_menu(event)

    -- Toggle viewing completed/incomplete tasks 
    elseif element_name == constants.jolt.task_list.show_completed_checkbox then
        -- Invert the setting stored in task manager 
        local show_completed = task_manager.get_setting_show_completed()
        task_manager.set_setting_show_completed(not show_completed)

        -- Refresh list of tasks
        open_task_list_menu(event)

    -- Toggle details for individual task
    elseif element_name == constants.jolt.task_list.toggle_details_button then
        -- Get the task 
        local task_id = event.element.tags.task_id
        local task = task_manager.get_task(task_id)

        -- invert property to mark that details should be shown/hidden
        task.show_details = not task.show_details

        -- Refresh list of tasks
        open_task_list_menu(event)
    
    -- On click of the "+ Subtask" button 
    elseif element_name == constants.jolt.task_list.add_subtask_button then
        -- Get the task 
        local task_id = event.element.tags.task_id
        local task = task_manager.get_task(task_id)

        -- Open the add task window
        local subtitle = "Subtask of " .. task.title
        local subtask = {}
        subtask.parent_id = task.id
        open_task_form_window(event, "New Subtask", subtitle, subtask)

    -- Group Management button 
    elseif element_name == constants.jolt.group_management.open_window_button then
        open_group_management_window(event)
    end
    

end)


--- Called when a gui tab is changed
---@param event any
script.on_event(defines.events.on_gui_selected_tab_changed, function (event)
    -- Check if it is the group tabs
    if event.element.name == constants.jolt.task_list.group_tabs_pane then
        -- get the index of the selected tab
        local selected_tab_index = event.element.selected_tab_index

        -- initialize if needed
        storage.players[event.player_index] = storage.players[event.player_index] or {}

        -- save selected tab to player data
        storage.players[event.player_index].selected_group_tab_index = selected_tab_index
    end

end)


--- Open the task list menu
function open_task_list_menu(event)

    --region =======Task List=======

    -- get player by index
    local player = game.get_player(event.player_index)

    -- Make new window for tasks list
    local close_button_name = constants.jolt.task_list.close_window_button
    local window_name = constants.jolt.task_list.window
    local main_frame = new_window(player, {"jolt.tasks_list_window_title"}, window_name, close_button_name, 400, 600)

    -- Add event to watch for button click to close the window
    windows_to_close[close_button_name] = window_name

    

    --endregion


    --region =======Controls=======

    -- Add row for controls 
    local controls_container = main_frame.add {
        type = "frame",
        name = "jolt_controls_container",
        direction = "horizontal",
        style = "subheader_frame"
    }

    -- A checkbox to toggle seeing completed/incomplete tasks
    local cb_show_completed = controls_container.add {
        type = "checkbox",
        name = constants.jolt.task_list.show_completed_checkbox,
        caption = {"jolt_task_list_window.show_completed_tasks"},
        state = task_manager.get_setting_show_completed(),
        horizontally_stretchable = "on"
    }

    -- Empty space
    local empty_space = controls_container.add {
        type = "empty-widget",
    }
    -- Make it expand to fill the space
    empty_space.style.minimal_width = 50
    empty_space.style.height = 24
    empty_space.style.horizontally_stretchable = true

    

    -- Add task button
    local add_task_button = controls_container.add {
        type = "sprite-button",
        style = "confirm_button",
        sprite = constants.jolt.sprites.add,
        name = constants.jolt.task_list.add_task_button,
        tooltip = {"jolt.tootlip_add_task"}
    }
    add_task_button.style.width = 50
    add_task_button.style.height = 30



    --endregion 


    

    --region =======Tabs=======

    -- Make place to put content in
    local content_frame = main_frame.add {
        type = "frame",
        name = "content_frame",
        direction = "vertical",
        style = "ugg_content_frame"
    }

    local tab_controls = content_frame.add {
        type = "frame",
        direction = "horizontal",
    }

    -- Add a tabbed-pane for all groups
    local tabbed_pane = tab_controls.add {
        type="tabbed-pane",
        name=constants.jolt.task_list.group_tabs_pane,
    }

    -- Edit groups button
    local btn_edit_groups = tab_controls.add {
        type = "sprite-button",
        name = constants.jolt.group_management.open_window_button,
        style = constants.styles.frame.button,
        sprite = constants.jolt.sprites.edit,
        tooltip = {"jolt.tooltip_edit_groups_button"},
    }
    btn_edit_groups.style.top_margin = 12

    -- Get the groups, add tabs for each one and their tasks
    for _, group in ipairs(task_manager.get_groups()) do
        -- Add the tab and set the title
        -- Display icon from group icon path
        local tab_title = "[img=" .. group.icon .. "] " .. group.name
        local new_tab = tabbed_pane.add{type="tab", caption=tab_title}

        -- Add tasks for each group inside its tab
        local tab_content = tabbed_pane.add{type="scroll-pane", direction="vertical"}
        -- Get tasks, checking if the control button "Show Completed".
        -- Get's only the tasks that match the state of that checkbox (complete/incomplete)
        for _, task in pairs(task_manager.get_tasks(group.id, task_manager.get_setting_show_completed())) do
            -- Display the task
            new_gui_task(tab_content, task)
        end


        -- Add the content to the tab 
        -- (Can only connect one thing so which is why I use another pane to group tasks)
        tabbed_pane.add_tab(new_tab, tab_content)
    end

    -- Initialize data if needed
    storage.players[event.player_index] = storage.players[event.player_index] or {}
    if not storage.players[event.player_index].selected_group_tab_index then
        storage.players[event.player_index].selected_group_tab_index = storage.players[event.player_index].selected_group_tab_index or 1
    end
    
    -- TODO maybe move the stored data into the task manager?
    -- Load the last selected tab from when the window was open before
    tabbed_pane.selected_tab_index = storage.players[event.player_index].selected_group_tab_index

    --endregion



    -- local controls_flow = content_frame.add {
    --     type = "flow",
    --     name = "controls_flow",
    --     direction = "horizontal",
    --     style = "ugg_controls_flow"
    -- }

    -- controls_flow.add {
    --     type = "button",
    --     name = "ugg_controls_toggle",
    --     caption = {"ugg.deactigroupate"}
    -- }

    -- -- a slider and textfield
    -- controls_flow.add {
    --     type = "slider",
    --     name = "ugg_controls_slider",
    --     groupalue = 0,
    --     minimum_groupalue = 0,
    --     maximum_groupalue = 10,
    --     style = "notched_slider"
    -- }

    -- controls_flow.add {
    --     type = "textfield",
    --     name = "ugg_controls_textfield",
    --     text = "0",
    --     numeric = true,
    --     allow_decimal = false,
    --     allow_negatigroupe = false,
    --     style = "ugg_controls_textfield"
    -- }

end

--- Opens a new window with a form to create a new task/subtask 
--- or edit an existing one
function open_task_form_window(event, window_title, window_subtitle, task)
    -- If data in task is there, then this must be an edit
    local is_edit = not task == nil

    -- Setup the data if editing an existing task
    task = task or {}
    local title = task.title or ""
    local task_id = task.task_id or ""
    local checkbox_state_add_to_top = task.checkbox_add_to_top or checkbox_default_state_add_to_top
    
    -- Get last selected tab index if this is a new task
    local last_group_selected_index = storage.players[event.player_index].selected_group_tab_index

    -- Set group id to the param if provided or the last group selected if new task
    local group_id = task.group_id or last_group_selected_index

    local player = game.get_player(event.player_index)

    -- Setup options for the new window
    local options = {
        player = player,
        window_title = window_title,
        window_name = constants.jolt.new_task.window,
        back_button_name = constants.jolt.new_task.back_button,
        confirm_button_name = constants.jolt.new_task.confirm_button
    }

    -- Make the new window and set close button
    local new_task_window = new_dialog_window(options)
    
    -- Add event to watch for button click to close the window
    windows_to_close[options.back_button_name] = options.window_name

    -- Only add the label line if needed
    -- need brackets because 'not' operator is applied first 
    local need_label = not (window_subtitle == nil)

    if need_label then
        -- Add subtitle line 
        local controls_container = new_task_window.add {
            type = "frame",
            name = "jolt_controls_container",
            direction = "horizontal",
            style = "subheader_frame",
            index = 2, -- Must set to ?? to place above the bottom row
        }

        -- subtitle 
        local lbl_subtitle = controls_container.add {
            type = "label",
            caption = window_subtitle,
            horizontally_stretchable = "on"
        }

        -- Empty space
        local empty_space = controls_container.add {
            type = "empty-widget",
        }
        -- Make it expand to fill the space
        empty_space.style.minimal_width = 50
        empty_space.style.height = 24
        empty_space.style.horizontally_stretchable = true
    end
    
    -- Calculate the position of the form if the subtitle was added or not
    local form_pos = 2
    if need_label then form_pos = form_pos + 1 end

    -- Container to hold form inputs
    local new_task_form = new_task_window.add {
        type = "frame",
        name = constants.jolt.new_task.form_container,
        direction = "vertical",
        style = "ugg_content_frame",
        index = form_pos, -- Must set to 2 to place above the bottom row
        tags = { task_id = task_id, parent_id = task.parent_id } -- Store task id if this is an edit task 
    }
    
    -- Label "Title" and textbox input
    local task_title_label = new_label(new_task_form, "Title")
    local task_title_textbox = new_task_form.add {
        type = "textfield",
        name = constants.jolt.new_task.title_textbox,
        text = title,
        style = constants.styles.form.textfield
    }
    task_title_textbox.style.horizontally_stretchable = true


    -- Checkbox for "Add to top"
    local checkbox_add_to_top = new_task_form.add {
        type = "checkbox",
        name = constants.jolt.new_task.add_to_top_checkbox,
        caption = {"jolt_new_task_window.add_to_top_checkbox_desc"},
        state = checkbox_state_add_to_top,
    }

    
    -- Dropdown to select which group the task is added to
    local dropdown_select_group = new_task_form.add {
        type = "drop-down",
        name = constants.jolt.new_task.group_dropdown,
        caption = "Group",
        items = task_manager.get_group_names(),
        style = "dropdown",
        selected_index = group_id
    }
end



--- Tries to add a new task checking the data in the new task window
---@param event any
function add_new_task(event)
    -- Go through element tree to get to the form_container
    local player = game.get_player(event.player_index)
    local screen = player.gui.screen
    local window = screen[constants.jolt.new_task.window]
    local form_container = window[constants.jolt.new_task.form_container]

    -- Get form elements
    local textbox_title = form_container[constants.jolt.new_task.title_textbox]
    local checkbox_add_to_top = form_container[constants.jolt.new_task.add_to_top_checkbox]
    local dropdown_group = form_container[constants.jolt.new_task.group_dropdown]

    -- Get Values
    local task_id = form_container.tags.task_id
    local title = textbox_title.text
    local add_to_top = checkbox_add_to_top.state
    local group_index = dropdown_group.selected_index

    -- check if empty string not nil since task_id is string type
    -- check type with debug_print(event, "type is: " .. type(task_id))
    local is_edit_task = task_id ~= ""
    
    -- Make task parameters
    local task_params = {
        title = title,
        group_id = group_index,
        parent_id = form_container.tags.parent_id or nil
    }

    -- If no title display error and do not close window
    if title == "" then
        -- Create "flying text" with error message
        player.create_local_flying_text {
            text = {"jolt_new_task_window.no_title_error_message"},
            create_at_cursor=true,
        }

    else -- If valid data add task
        if is_edit_task then
            task_manager.update_task(task_params, task_id)
        else
            task_manager.add_task(task_params, add_to_top)
        end

        -- Close task form window
        player.gui.screen[constants.jolt.new_task.window].destroy()

        -- Refresh data
        open_task_list_menu(event)
    end
end














--- function to print
function debug_print(event, message)
    local player = game.get_player(event.player_index)
    player.print(message)
end