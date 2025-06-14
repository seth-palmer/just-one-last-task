--- control.lua

local checkbox_default_state_add_to_top = false

--- Imports
local TaskManager = require("scripts.task_manager")
task_manager = TaskManager.new()
local constants = require("constants")
require("gui")

-- Make sure the intro cinematic of freeplay doesn't play egroupery time we restart
-- This is just for convinience, don't worry if you don't understand how this works
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

    -- store players and their info
    storage.players = storage.players or {}
end)

--- Watch for clicks on the task shortcut icon to open and close
--- the task list window
script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == "tasks-menu" then
        local player = game.get_player(event.player_index)
        if player.gui.screen.jolt_tasks_list_window then
            close_task_list_menu(event)
        else
            open_task_list_menu(event)
        end
    end

end) -- end on_lua_shortcut

--- Close the task list menu
function close_task_list_menu(event)
    local player = game.get_player(event.player_index)
    player.gui.screen.jolt_tasks_list_window.destroy()
end

local windows_to_close = {}

--- Watch for clicks on gui elements for my mod (prefix "jolt_tasks") icon
script.on_event(defines.events.on_gui_click, function(event)
    local element_name = event.element.name

    -- Close my windows looking in dictionary to check if
    -- it is one of my windows
    local frame_name = windows_to_close[element_name]
    if frame_name ~= nil then
        local player = game.get_player(event.player_index)

        -- Check if the frame still exists before destroying
        if player.gui.screen[frame_name] and player.gui.screen[frame_name].valid then
            player.gui.screen[frame_name].destroy()
        end

        -- Clean up the mapping
        windows_to_close[element_name] = nil

    -- Open new task window when Add task button clicked
    elseif element_name == "jolt_tasks_add_task_button" then
        open_new_task_window(event)
    end
end)


--- Called when a gui tab is changed
---@param event any
script.on_event(defines.events.on_gui_selected_tab_changed, function (event)

    -- Check if it is the group tabs
    if event.element.name == "jolt_group_tabs_pane" then
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
    local close_button_name = "jolt_tasks_list_close_button"
    local window_name = "jolt_tasks_list_window"
    local main_frame = new_window(player, "Tasks", window_name, close_button_name, 400, 600)

    -- Add event to watch for button click to close the window
    windows_to_close[close_button_name] = window_name

    -- Make place to put content in
    local content_frame = main_frame.add {
        type = "frame",
        name = "content_frame",
        direction = "vertical",
        style = "ugg_content_frame"
    }
    --endregion


    --region =======Controls=======

    -- Add task button
    local add_task_button = main_frame.add {
        type = "sprite-button",
        style = "confirm_button",
        sprite = "utility/add",
        name = "jolt_tasks_add_task_button",
        tooltip = "Add Task",
    }



    --endregion 


    --region =======Seed Data=======

    -- TODO remove seed data
    -- Add temporary seed data (will add more on each launch of the menu)

    local t1Params = {title="Red Science", groupId=1, description="Automate 5/sec"}
    local t2Params = {title="Green Science", groupId=1, description="Automate 5/sec"}
    local t3Params = {title="Millitary Science", groupId=1, description="Automate 5/sec"}
    local t4Params = {title="Build Hubble Space Platform", groupId=2}

    
    task_manager.add_task(t1Params, 1, true)
    task_manager.add_task(t2Params, 1, true)
    task_manager.add_task(t3Params, 1, true)
    task_manager.add_task(t4Params, 2, true)
    --endregion

    --region =======Tabs=======

    -- Add a tabbed-pane for all groups
    local tabbed_pane = content_frame.add{
        type="tabbed-pane",
        name="jolt_group_tabs_pane",
    }

    -- Get the groups, add tabs for each one and their tasks
    for _, group in ipairs(task_manager.get_groups()) do
        -- Add the tab and set the title
        local tab_title = group.get_icon_path() .. " " .. group.get_name()
        local new_tab = tabbed_pane.add{type="tab", caption=tab_title}

        -- Add tasks for each group inside its tab
        local tab_content = tabbed_pane.add{type="scroll-pane", direction="vertical"}
        for _, task in pairs(group.get_tasks()) do
            local label = tab_content.add{type="label", caption=task.get_title()}
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

--- Opens a window with the form to create a new task
---@param event any
function open_new_task_window(event)
    local player = game.get_player(event.player_index)

    -- Make the new window and set close button
    local close_button_name = "jolt_new_task_close_button"
    local window_name = "jolt_new_task_window"
    local new_task_window = new_window(player, "New Task", window_name, close_button_name, 250, 400)
    -- Add event to watch for button click to close the window
    windows_to_close[close_button_name] = window_name

    -- Container to hold form inputs
    local new_task_form = new_task_window.add {
        type = "frame",
        name = "jolt_new_task_form",
        direction = "vertical",
        style = "ugg_content_frame"
    }
    
    -- Label "Title" and textbox input
    local task_title_label = new_label(new_task_form, "Title")
    local task_title_textbox = new_task_form.add {
        type = "textfield",
        name = "jolt_new_task_title",
        text = "",
        style = constants.styles.form.textfield
    }
    task_title_textbox.style.horizontally_stretchable = true


    -- Checkbox for "Add to top"
    local checkbox_add_to_top = new_task_form.add {
        type = "checkbox",
        name = "jolt_checkbox_add_to_top",
        caption = "Add to top",
        state = checkbox_default_state_add_to_top,
    }

    -- Get last selected tab index
    local last_group_selected_index = storage.players[event.player_index].selected_group_tab_index

    -- Dropdown to select which group the task is added to
    local dropdown_select_group = new_task_form.add {
        type = "drop-down",
        name = "jolt_dropdown_select_group",
        caption = "Group",
        items = task_manager.get_group_names(),
        style = "dropdown",
        selected_index = last_group_selected_index,
    }




    --task_title.style.rich_text_setting = defines.rich_text_setting.enabled
end
