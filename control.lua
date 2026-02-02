--- control.lua

--- Imports
local TaskManager = require("scripts.task_manager")
local constants = require("constants")
require("gui")


--region =======Local Functions=======
--- IMPORTANT put local functions before where they are used!!!

--- Opens the group management window
---@param event any
local function open_group_management_window(event)
    local player = game.get_player(event.player_index)
    local title = {"jolt_group_management.window_title"}
    local window_name = constants.jolt.group_management.window_name
    local close_name = constants.jolt.group_management.close_button
    local window = new_window(player, title, window_name, close_name, 320, 500)

    -- Add event to watch for button click to close the window
    task_manager.bind_close_button(player, close_name, window_name)

    
    -- The selected group
    local selected_group = {title = "", icon="virtual/signal-question-mark"}


    local main_frame = window.add {
        type = "frame",
        direction="vertical",
        name=constants.jolt.group_management.main_frame,
        style = "slot_button_deep_frame",
    }
    main_frame.style.padding = 0
    main_frame.style.margin = 4
    main_frame.style.horizontal_align = "center"


    -- Controls frame
    local controls_frame = main_frame.add {
        type="frame",
        direction="horizontal",
        style = "subheader_frame"
    }
    controls_frame.style.minimal_height = 40
    controls_frame.style.margin = 4

    -- Empty space
    local empty_space = controls_frame.add {
        type = "empty-widget",
    }
    -- Make it expand to fill the space
    empty_space.style.minimal_width = 50
    empty_space.style.horizontally_stretchable = true

    -- Label for new group button 
    local add_new_group_text = {"jolt_group_management.add_new_group_text"}
    local add_group_label = new_label(controls_frame, add_new_group_text)

    -- Add new group button
    local add_group_button = controls_frame.add{
        type="sprite-button",
        style = "confirm_button",
        sprite=constants.jolt.sprites.add,
        name=constants.jolt.group_management.add_new_group_icon_button,
        tooltip = {"jolt_group_management.tooltip_add_group"}
    }
    add_group_button.style.width = 50
    add_group_button.style.height = 30

    -- Display icon for each group
    local button_frame = main_frame.add{
        type="frame",
        direction="horizontal",
        style="ugg_deep_frame"
    }
    button_frame.style.margin = 0

    local max_col_count = 7
    local button_table = button_frame.add{
        type="table",
        name="button_table",
        column_count=max_col_count,
        style="filter_slot_table"
    }
    
    -- local button_table = player.gui.screen.ugg_main_frame.content_frame.button_frame.button_table
    -- button_table.clear()

    -- Get group order
    local group_order = task_manager.get_group_order()

    -- Add each group
    for index, value in ipairs(group_order) do
        -- Get the group from its id
        -- Example: local nauvis_group = {id=1, name="Nauvis", icon="space-location/nauvis"}
        group = task_manager.get_group(value)

        local icon_button = button_table.add{
            type="sprite-button",
            sprite=group.icon,
            style="slot_button",
            -- Add tags since can't use the same name for each
            -- but can check tag for group_mgnmt_btn and then get group_id
            tags={is_group_management_icon_button=true, group_id=group.id}
        }
        -- If this button is selected change its style to 
        -- be yellow button background
        if group.id == storage.players[event.player_index].selected_group_icon_id then
            icon_button.style = constants.styles.buttons.yellow
            selected_group = group
        else
        end
    end


    -- Disable all buttons 
    local default_btn_state = selected_group.id ~= nil

    local form_bg_frame = main_frame.add {
        type = "frame",
        style = "inside_shallow_frame",
        name=constants.jolt.group_management.form_frame,
    }

    -- Edit form in the bottom half of the window
    local form_table = form_bg_frame.add{
        type="table",
        column_count=2,
        name=constants.jolt.group_management.form_container,
        style="table"
    }
    form_table.style.padding = 10
    
    -- Label "Title" and textbox input
    local label = form_table.add {type = "label", caption = "Title:"}
    local task_title_textbox = form_table.add {
        type = "textfield",
        name = constants.jolt.group_management.task_title_textbox,
        text = selected_group.name,
        style = constants.styles.form.textfield,
        enabled = default_btn_state,
    }
    -- Focus the textbox for faster edits
    task_title_textbox.focus()

    -- Icon label for group
    local label = form_table.add {type = "label", caption = "Icon:"}

    -- Show icon from group selected
    local icon_button = form_table.add{
        type = "choose-elem-button", -- let user choose group
        name = constants.jolt.group_management.change_group_icon_button,
        elem_type = "signal",  -- or "fluid", "recipe", "technology", "entity", etc.
        enabled = default_btn_state,
    }
    -- Split up path e.g. "space-location/nauvis" for elem_value
    local slash_pos = string.find(selected_group.icon, "/")
    local icon_type = string.sub(selected_group.icon, 0, slash_pos -1)
    local icon_name = string.sub(selected_group.icon, slash_pos+1, -1)

    -- Translate back for edge case where it uses 'virtual'
    -- in a choose elem btn, but 'virtual-signal' in a sprite
    if icon_type == "virtual-signal" then icon_type = "virtual" end

    -- MUST set elem_value after icon button
    -- (can't set property inside of it)
    icon_button.elem_value = {type = icon_type, name = icon_name}

    -- Position buttons - to change selected group position
    form_table.add {type = "label", caption = "Position:"}
    form_table.add {type = "label", caption = ""} -- skip this row

    -- Move group left button
    form_table.add {
        type = "sprite-button",
        sprite = constants.jolt.sprites.collapse,
        name = constants.jolt.group_management.move_group_left,
        tooltip = {"jolt_group_management.tooltip_move_group_left"},
        enabled = default_btn_state,
    }

    -- Move group right button
    form_table.add {
        type = "sprite-button",
        sprite = constants.jolt.sprites.expand,
        name = constants.jolt.group_management.move_group_right,
        tooltip = {"jolt_group_management.tooltip_move_group_right"},
        enabled = default_btn_state,
    }

    -- A line to separate the controlls
    local separator = window.add{
        type = "line",
        direction = "horizontal"
    }

    -- Add row for controls 
    local controls_container = window.add {
        type = "flow",
        direction = "horizontal",
    }
    controls_container.style.top_padding = 4
    controls_container.style.left_padding = 3
    controls_container.style.right_padding = 3

    -- -- Empty space
    -- local empty_space = controls_container.add {
    --     type = "empty-widget",
    -- }
    -- -- Make it expand to fill the space
    -- empty_space.style.minimal_width = 50
    -- empty_space.style.height = 24
    -- empty_space.style.horizontally_stretchable = true

    -- Delete group button
    local btn_delete_group = controls_container.add {
        type = "sprite-button",
        name = constants.jolt.group_management.delete_group,
        style = constants.styles.buttons.red,
        sprite = constants.jolt.sprites.delete,
        tooltip = {"jolt_group_management.tooltip_delete_group"},
        enabled = default_btn_state,
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
        enabled = default_btn_state,
        name = constants.jolt.group_management.btn_save_group
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
    -- TODO this check seed data
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
    local nauvis_group = {id="a1", name="Nauvis", icon="space-location/nauvis"}
    local space_group = {id="b1", name="Space", icon="item/thruster"}

    local default_group_data = {}
    default_group_data[nauvis_group.id] = nauvis_group
    default_group_data[space_group.id] = space_group

    local default_group_order = {"a1", "b1"}

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
        group_order = default_group_order,
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
    local player = game.get_player(event.player_index)
    --TODO: uncomment below to debug naming issues
    -- debug_print(event, "elementName = " .. element_name)


    -- If task interacted with save it to last interacted task
    -- to be able to scroll to it later
    -- separated so it doesn't block other interactions
    if event.element.tags.task_id then 
        -- save task id
        task_manager.save_last_interacted_task_id(player, event.element.tags.task_id)
    end


    -- Close my windows looking in dictionary to check if
    -- it is one of my windows
    local window_name = task_manager.pop_close_button(player, element_name)
    if window_name ~= nil then


        -- Check if the frame still exists before destroying
        if player.gui.screen[window_name] and player.gui.screen[window_name].valid then
            player.gui.screen[window_name].destroy()
        end

        -- If closing group management remove the selected icon info 
        -- (so the window opens with nothing selected)
        if window_name == constants.jolt.group_management.window_name then
            storage.players[event.player_index].selected_group_icon_id = nil
        end

    -- Open new task window when Add task button clicked
    elseif element_name == constants.jolt.task_list.add_task_button then
        open_task_form_window(event, "New Task", nil, {})

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
        local task = task_manager.get_task(task_id)

        -- Open the new task window with pre-filled data 
        -- IMPORTANT: need to use params or their is bug that a new task will be 
        -- created when editing a task.
        local params = {
            title = task.title,
            group_id = task.group_id,
            description = task.description,
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

    

    -- If selected an tab group icon button change the tasks
    elseif event.element.tags.is_group_change_button then
        -- Save selected group id
        local selected_group_id = event.element.tags.group_id
        storage.players[event.player_index].selected_group_tab_id = selected_group_id

        -- Refresh list of tasks
        open_task_list_menu(event)


    -- Group Management button
    elseif element_name == constants.jolt.group_management.open_window_button then
        open_group_management_window(event)

    -- Group Management button 
    elseif element_name == constants.jolt.group_management.add_new_group_icon_button then
        -- Add group with template data and open window
        -- !! Use "virtual-signal" and not "virtual" for sprites
        group = {name="", icon="virtual-signal/signal-question-mark"}
        local new_group_id = task_manager.add_group(group)

        -- Make it the currently selected group
        storage.players[event.player_index].selected_group_icon_id = new_group_id

        -- Refresh windows
        open_task_list_menu(event)
        open_group_management_window(event)



    -- Delete selected group
    elseif element_name ==  constants.jolt.group_management.delete_group then
        -- Get group id
        local group_id = storage.players[event.player_index].selected_group_icon_id

        -- If tasks in group show warning
        local task_count = task_manager.count_tasks_for_group(group_id)

        if task_count > 0 then
            -- Make the new window and set close button
            -- Setup options for the new window
            local options = {
                width = 300,
                height = 180,
                player = player,
                window_name = constants.jolt.delete_group.window_name,
                window_title = {"jolt_group_management.confirm_delete_window_title"},
                back_button_name = constants.jolt.delete_group.back_button,
                confirm_button_name = constants.jolt.delete_group.confirm_button
            }
            -- Open new confirmation dialog window
            local confirm_delete_window = new_dialog_window(options)

            -- Add event to watch for button click to close the window
            task_manager.bind_close_button(player, options.back_button_name, options.window_name)

            local confirm_delete_frame = confirm_delete_window.add {
                type = "frame",
                direction = "vertical",
                index = 2,
                style = "ugg_content_frame"
            }

            -- Get from en.cfg for translation reasons
            local message = {"jolt_group_management.confirm_delete_group_warning_message", task_count, task_count > 1}

            -- Label to hold warning message
            local confirm_delete_label = new_label(confirm_delete_frame, message)

            -- Force onto multiple lines
            confirm_delete_label.style.single_line = false
        else
            -- Delete group
            task_manager.delete_group(group_id)

            -- Refresh windows
            open_task_list_menu(event)
            open_group_management_window(event)
        end

    -- If the button is
    elseif element_name ==  constants.jolt.delete_group.confirm_button then
        -- Get group id
        local group_id = storage.players[event.player_index].selected_group_icon_id

        -- Delete group
        task_manager.delete_group(group_id)

        -- Refresh windows
        open_task_list_menu(event)
        open_group_management_window(event)

        -- Close confirmation window
        player.gui.screen[constants.jolt.delete_group.window_name].destroy()

    -- If selected an group icon button in the group management window
    elseif event.element.tags.is_group_management_icon_button then
        -- Save selected group id 
        local selected_group_id = event.element.tags.group_id
        storage.players[event.player_index].selected_group_icon_id = selected_group_id

        -- Refresh windows
        open_task_list_menu(event)
        open_group_management_window(event)

    -- Move group left button
    elseif element_name == constants.jolt.group_management.move_group_left then
        -- Get current selected group
        local group_id = storage.players[event.player_index].selected_group_icon_id

        -- Swap with the previous
        task_manager.move_group_left(group_id)

        -- Refresh windows
        open_task_list_menu(event)
        open_group_management_window(event)

    -- Move group right button
    elseif element_name == constants.jolt.group_management.move_group_right then
        -- Get current selected group
        local group_id = storage.players[event.player_index].selected_group_icon_id

        -- Swap with the next
        task_manager.move_group_right(group_id)

        -- Refresh windows
        open_task_list_menu(event)
        open_group_management_window(event)

    -- Save group button 
    elseif element_name == constants.jolt.group_management.btn_save_group then
        -- Get new name values
        
        -- Go through element tree to get to the form_container
        local player = game.get_player(event.player_index)
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
        -- in a choose elem button, but 'virtual-signal' in a sprite
        elseif elem.type == "virtual" then
            type = "virtual-signal"
        else
            type = elem.type
        end
        -- Combine to make the path
        local new_icon = type .. "/" .. elem.name

        -- Get selected group id
        local group_id = storage.players[event.player_index].selected_group_icon_id
        
        -- Params to send to update group function
        local params = {name=new_name, icon=new_icon}

        -- Update group with new values 
        task_manager.update_group(params, group_id)

        -- Refresh windows
        open_task_list_menu(event)
        open_group_management_window(event)
    end
    

end)


--- Called when a gui tab is changed
---@param event any
-- script.on_event(defines.events.on_gui_selected_tab_changed, function (event)
--     -- Check if it is the group tabs
--     if event.element.name == constants.jolt.task_list.group_tabs_pane then
--         -- get the index of the selected tab
--         local selected_tab_index = event.element.selected_tab_index

--         -- initialize if needed
--         storage.players[event.player_index] = storage.players[event.player_index] or {}

--         -- save selected tab to player data
--         storage.players[event.player_index].selected_group_tab_index = selected_tab_index
--     end
-- end)

--- Called when a window is moved
script.on_event(defines.events.on_gui_location_changed, function(event)
    local player = game.get_player(event.player_index)
    local new_location = event.element.location
    
    -- Save new location to storage
    -- storage.players[event.player_index].saved_window_locations[event.element.name] = new_location
    task_manager.save_window_location(player, event.element.name, new_location)
end)


--- Open the task list menu
function open_task_list_menu(event)
    -- Initialize data if needed
    -- !! Note: index 1 is the start not 0 in lua !!
    storage.players[event.player_index] = storage.players[event.player_index] or {}
    if not storage.players[event.player_index].selected_group_tab_index then
        storage.players[event.player_index].selected_group_tab_index = storage.players[event.player_index].selected_group_tab_index or 1
    end

    if not storage.players[event.player_index].selected_group_tab_id then
        storage.players[event.player_index].selected_group_tab_id =
        storage.players[event.player_index].selected_group_tab_id or
        storage.task_data.group_order[1]
    end

    --region =======Task List=======

    -- get player by index
    local player = game.get_player(event.player_index)

    -- Make new window for tasks list
    local close_button_name = constants.jolt.task_list.close_window_button
    local window_name = constants.jolt.task_list.window
    local window = new_window(player, {"jolt.tasks_list_window_title"}, window_name, close_button_name, 400, 600)

    

    -- Add event to watch for button click to close the window
    task_manager.bind_close_button(player, close_button_name, window_name)

    local main_frame = window.add {
        type = "frame",
        direction = "vertical",
        style = "slot_button_deep_frame",
    }

    main_frame.style.padding = 0
    main_frame.style.margin = 4
    main_frame.style.horizontal_align = "center"

    --endregion


    --region =======Controls=======

    -- Add row for controls 
    local controls_container = main_frame.add {
        type = "frame",
        name = "jolt_controls_container",
        direction = "horizontal",
        style = "subheader_frame"
    }
    controls_container.style.minimal_height = 40
    controls_container.style.margin = 4

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

    local group_controls_frame = main_frame.add {
        type = "frame",
        direction = "vertical",
    }
    group_controls_frame.style.margin = 0
    group_controls_frame.style.padding = 4

    -- Make place to put content in
    local content_frame = main_frame.add {
        type = "frame",
        name = "content_frame",
        direction = "vertical",
        style = "ugg_content_frame"
    }
    content_frame.style.margin = 0
    content_frame.style.padding = 0

    
    -- Add label for current group name
    local lbl_current_group_name = group_controls_frame.add {
            type = "label",
            caption = "",
            horizontally_stretchable = "on"
    }
    lbl_current_group_name.style.bottom_margin = -15
    lbl_current_group_name.style.font = "default-large-bold"
    
    -- Frame for groups and group edit button
    local group_content = group_controls_frame.add {
        type = "flow",
        direction = "horizontal",
        horizontally_stretchable = "on"
    }
    group_content.style.top_padding = 12
    group_content.style.bottom_padding = 12
    group_content.style.left_margin = 0
    group_content.style.minimal_width = 500 -- make it take up the full width

    -- Add section for tab icons
    local max_col_count = 7
    local button_table = group_content.add{
        type="table",
        name="button_table",
        column_count=max_col_count,
        style="filter_slot_table"
    }

    -- Edit groups button
    local btn_edit_groups = group_content.add {
        type = "sprite-button",
        name = constants.jolt.group_management.open_window_button,
        style = constants.styles.frame.button,
        sprite = constants.jolt.sprites.edit,
        tooltip = {"jolt.tooltip_edit_groups_button"},
    }
    btn_edit_groups.style.top_margin = 12
    btn_edit_groups.style.left_margin = 24

    -- Save current group id
    local current_group_id = storage.players[event.player_index].selected_group_tab_id
    local current_group = task_manager.get_group(current_group_id)

    -- Get group order
    local group_order = task_manager.get_group_order()
    local groups = task_manager.get_groups()

    -- Add a tab for each group
    for index, value in ipairs(group_order) do
        -- Get the group from its id
        group = task_manager.get_group(value)

        local icon_button = button_table.add{
            type="sprite-button",
            sprite=group.icon,
            style="slot_button",
            -- Add tags since can't use the same name for each
            -- but can check tag for group_management_btn and then get group_id
            tags={is_group_change_button=true, group_id=group.id}
        }
        -- If this button is selected change its style to
        -- be yellow button background to show it is the active group
        if group.id == current_group_id then
            icon_button.style = constants.styles.buttons.yellow
            selected_group = group

            -- Update current group name
            lbl_current_group_name.caption = current_group.name
        else
        end
    end

    -- Display tasks for the currently selected group
    local tab_content = content_frame.add{
        type="scroll-pane", 
        direction="vertical",
        vertical_scroll_policy = "auto",  -- Only show scrollbar when needed
        horizontal_scroll_policy = "never",
    }
    tab_content.style.padding = 10
    tab_content.style.minimal_height = 300
    tab_content.style.minimal_width = 350

    -- Get the last interacted with task (may be nil)
    local last_interacted_task_id = task_manager.get_last_interacted_task_id(player)
    local last_interacted_task_element

    -- Get tasks, checking if the control button "Show Completed".
    -- Get's only the tasks that match the state of that checkbox (complete/incomplete)
    local group_tasks = task_manager.get_tasks(current_group_id, task_manager.get_setting_show_completed())
    for _, task in pairs(group_tasks) do
        -- Display the task
        local gui_task = new_gui_task(tab_content, task)
        
        -- TODO: in future if element does not exist (like when
        -- marking as done, go to next or prev element)
        if last_interacted_task_id and task.id == last_interacted_task_id then
            last_interacted_task_element = gui_task
        end
    end

    -- Add placeholder text if no tasks
    if #group_tasks == 0 then
        local placeholder = tab_content.add{
            type = "label",
            caption = {"jolt_task_list_window.no_tasks_info_text"}
        }
        placeholder.style.font_color = {r=0.6, g=0.6, b=0.6}
    end

    -- Scroll to the last interacted with element element 
    if last_interacted_task_element and last_interacted_task_element.valid then
        tab_content.scroll_to_element(last_interacted_task_element, "in-view")
    end

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
    local description = task.description or ""
    local task_id = task.task_id or ""
    local checkbox_state_add_to_top = task.checkbox_add_to_top or checkbox_default_state_add_to_top
    
    -- Get last selected tab index if this is a new task
--     local last_group_selected_index = storage.players[event.player_index].selected_group_tab_index
    -- Get id
    local current_group_id = storage.players[event.player_index].selected_group_tab_id

    -- Set group id to the param if provided or the last group selected if new task
    local group_id = task.group_id or current_group_id

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
    task_manager.bind_close_button(player, options.back_button_name, options.window_name)

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
            index = 2, -- Must set to 2 to place above the bottom row
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
        type = "flow",
        name = constants.jolt.new_task.form_container,
        direction = "vertical",
        index = form_pos, -- Must set to 2 to place above the bottom row
        tags = { task_id = task_id, parent_id = task.parent_id } -- Store task id if this is an edit task 
    }
    -- Space out the elements (must use flow not frame)
    new_task_form.style.vertical_spacing = 4
    
    -- Label "Title" and textbox input
    local task_title_label = new_label(new_task_form, "Title")
    -- TODO: in future add button to add icon to task title
    -- local task_title_flow = new_task_form.add {
    --     type = "flow",
    --     direction = "horizontal",
    -- }
    -- task_title_flow.style.vertical_align = "center"
    -- task_title_flow.style.horizontal_spacing = 0
    -- local task_title_choose_icon_button = new_task_form.add {
    --     type = "choose-elem-button",
    --     name = "",
    --     elem_type = "signal",
    -- }


    local task_title_textbox = new_task_form.add {
        type = "textfield",
        name = constants.jolt.new_task.title_textbox,
        text = title,
        style = constants.styles.form.textfield
    }
    task_title_textbox.style.horizontally_stretchable = true
    task_title_textbox.style.maximal_width = 300

    -- Focus the textfield so the player can type immediately
    task_title_textbox.focus()

    


    -- Checkbox for "Add to top"
    local checkbox_add_to_top = new_task_form.add {
        type = "checkbox",
        name = constants.jolt.new_task.add_to_top_checkbox,
        caption = {"jolt_new_task_window.add_to_top_checkbox_desc"},
        state = checkbox_state_add_to_top,
    }

    -- Get position
    local position = task_manager.get_group_position(group_id)
    
    -- Dropdown to select which group the task is added to
    local dropdown_select_group = new_task_form.add {
        type = "drop-down",
        name = constants.jolt.new_task.group_dropdown,
        caption = "Group",
        items = task_manager.get_group_names(),
        style = "dropdown",
        selected_index = position
    }

    -- https://lua-api.factorio.com/latest/concepts/GuiElementType.html
    -- Task description
    local task_description_label = new_label(new_task_form, "Description")
    local task_description_textbox = new_task_form.add {
        type = "text-box", -- A multiline textfield
        name = constants.jolt.new_task.description_textbox,
        text = description,
        style = constants.styles.form.textfield,
        
    }
    task_description_textbox.style.horizontally_stretchable = true
    task_description_textbox.style.vertically_stretchable = true
    task_description_textbox.word_wrap = true
    task_description_textbox.style.maximal_width = 340

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
    local textbox_description = form_container[constants.jolt.new_task.description_textbox]
    local checkbox_add_to_top = form_container[constants.jolt.new_task.add_to_top_checkbox]
    local dropdown_group = form_container[constants.jolt.new_task.group_dropdown]

    -- Get Values
    local task_id = form_container.tags.task_id
    local title = textbox_title.text
    local description = textbox_description.text
    local add_to_top = checkbox_add_to_top.state
    local group_index = dropdown_group.selected_index
    -- Get the actual group id
    local group_id = task_manager.get_group_order()[group_index]

    -- check if empty string not nil since task_id is string type
    -- check type with debug_print(event, "type is: " .. type(task_id))
    local is_edit_task = task_id ~= ""
    
    -- Make task parameters
    local task_params = {
        title = title,
        description = description,
        group_id = group_id,
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











--- Print table information
---@param player any
---@param t any
local function printTable(player, t)
    
    for key, value in pairs(t) do
        if type(value) == "table" then
            player.print(key .. ":")
            printTable(player, value)  -- Recursively print nested tables
        else
            player.print(key .. ": " .. tostring(value))
        end
    end
end

--- function to print
function debug_print(event, message)
    local player = game.get_player(event.player_index)
    if type(message) == "table" then
        printTable(player, message)
    else
        player.print(message)
    end
end
