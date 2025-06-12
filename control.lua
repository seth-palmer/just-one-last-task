--- control.lua
local TaskManager = require("scripts.task_manager")
task_manager = TaskManager.new()

-- Make sure the intro cinematic of freeplay doesn't play egroupery time we restart
-- This is just for congroupenience, don't worry if you don't understand how this works
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
    storage.players = {}
end)

--- Watch for clicks on the task shortcut icon to open and close
--- the task list window
script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == "tasks-menu" then
        local player = game.get_player(event.player_index)
        if player.gui.screen.jolt_tasks_list then
            close_task_list_menu(event)
        else
            open_task_list_menu(event)
        end
    end

end) -- end on_lua_shortcut

--- Close the task list menu
function close_task_list_menu(event)
    local player = game.get_player(event.player_index)
    player.gui.screen.jolt_tasks_list.destroy()
end

--- Watch for clicks on gui elements for my mod (prefix "jolt_tasks") icon
script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "tasks_menu_close_button" then
        close_task_list_menu(event)
    end
end)

--- Open the task list menu
function open_task_list_menu(event)
    -- get player by index
    local player = game.get_player(event.player_index)

    -- initialize our data for the player
    storage.players[player.index] = {
        controls_actigroupe = true,
        button_count = 0,
        next_task_id = 0,
        tasks = {}
    }

    local screen_element = player.gui.screen
    local main_frame = screen_element.add {
        type = "frame",
        name = "jolt_tasks_list",
        direction = "vertical"
    }

    main_frame.style.size = {400, 600}
    -- center the gui in the screen (not it's contents)
    main_frame.auto_center = true

    -- Title Bar
    local title_bar = main_frame.add {
        type = "flow",
        direction = "horizontal"
    }

    local title = title_bar.add {
        type = "label",
        caption = "Tasks",
        style = "frame_title",
    }

    -- drag handle
    local dragger = title_bar.add {
        type = "empty-widget",
        style = "draggable_space",
    }
    dragger.style.size = {300, 24}
    dragger.drag_target = main_frame

    local close_button = title_bar.add {
        type = "sprite-button",
        style = "frame_action_button",
        sprite = "utility/close",
        name = "tasks_menu_close_button",
        tooltip = "Close"
    }


    local content_frame = main_frame.add {
        type = "frame",
        name = "content_frame",
        direction = "vertical",
        style = "ugg_content_frame"
    }

    -- TODO remove
    -- Add temporary seed data (will add more on each launch of the menu)

    local t1Params = {title="Red Science", groupId=1, description="Automate 5/sec"}
    local t2Params = {title="Green Science", groupId=1, description="Automate 5/sec"}
    local t3Params = {title="Millitary Science", groupId=1, description="Automate 5/sec"}
    local t4Params = {title="Build Hubble Space Platform", groupId=2}

    
    task_manager.add_task(t1Params, 1, true)
    task_manager.add_task(t2Params, 1, true)
    task_manager.add_task(t3Params, 1, true)
    task_manager.add_task(t4Params, 2, true)


    -- This will add a tabbed-pane and 2 tabs with contents.
    local tabbed_pane = content_frame.add{type="tabbed-pane"}

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
