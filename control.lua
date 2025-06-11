--- control.lua
local flib_gui = require("__flib__.gui")

-- Make sure the intro cinematic of freeplay doesn't play every time we restart
-- This is just for convenience, don't worry if you don't understand how this works
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

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == "tasks-menu" then
        local player = game.get_player(event.player_index)
        if player.gui.screen.ugg_main_frame then
            closeTasksListMenu(event)
        else
            openTasksListMenu(event)
        end
    end

end) -- end on_lua_shortcut

function closeTasksListMenu(event)
    local player = game.get_player(event.player_index)
    player.gui.screen.ugg_main_frame.destroy()
end

script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "tasks_menu_close_button" then
        closeTasksListMenu(event)
    end
end)

function openTasksListMenu(event)
    -- get player by index
    local player = game.get_player(event.player_index)

    -- initialize our data for the player
    storage.players[player.index] = {
        controls_active = true,
        button_count = 0,
        next_task_id = 0,
        tasks = {}
    }

    local screen_element = player.gui.screen
    local main_frame = screen_element.add {
        type = "frame",
        name = "ugg_main_frame",
        direction = "vertical"
    }

    main_frame.style.size = {400, 600}
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

    -- This will add a tabbed-pane and 2 tabs with contents.
    local tabbed_pane = main_frame.add{type="tabbed-pane"}
    local tab1 = tabbed_pane.add{type="tab", caption="[img=space-location/nauvis]"}
    local tab2 = tabbed_pane.add{type="tab", caption="[img=item/thruster]"}
    local label1 = tabbed_pane.add{type="label", caption="Label 1"}
    local label2 = tabbed_pane.add{type="label", caption="Label 2"}
    tabbed_pane.add_tab(tab1, label1)
    tabbed_pane.add_tab(tab2, label2)


    -- local controls_flow = content_frame.add {
    --     type = "flow",
    --     name = "controls_flow",
    --     direction = "horizontal",
    --     style = "ugg_controls_flow"
    -- }

    -- controls_flow.add {
    --     type = "button",
    --     name = "ugg_controls_toggle",
    --     caption = {"ugg.deactivate"}
    -- }

    -- -- a slider and textfield
    -- controls_flow.add {
    --     type = "slider",
    --     name = "ugg_controls_slider",
    --     value = 0,
    --     minimum_value = 0,
    --     maximum_value = 10,
    --     style = "notched_slider"
    -- }

    -- controls_flow.add {
    --     type = "textfield",
    --     name = "ugg_controls_textfield",
    --     text = "0",
    --     numeric = true,
    --     allow_decimal = false,
    --     allow_negative = false,
    --     style = "ugg_controls_textfield"
    -- }

end
