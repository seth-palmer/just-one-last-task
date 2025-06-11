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
        -- Open menu
        openTasksListMenu(event)
    end

end) -- end on_lua_shortcut

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
        caption = {"ugg.mod_title"}
    }
    main_frame.style.size = {400, 600}
    main_frame.auto_center = true

    local content_frame = main_frame.add {
        type = "frame",
        name = "content_frame",
        direction = "vertical",
        style = "ugg_content_frame"
    }
    local controls_flow = content_frame.add {
        type = "flow",
        name = "controls_flow",
        direction = "horizontal",
        style = "ugg_controls_flow"
    }

    controls_flow.add {
        type = "button",
        name = "ugg_controls_toggle",
        caption = {"ugg.deactivate"}
    }

    -- a slider and textfield
    controls_flow.add {
        type = "slider",
        name = "ugg_controls_slider",
        value = 0,
        minimum_value = 0,
        maximum_value = #item_sprites,
        style = "notched_slider"
    }

    controls_flow.add {
        type = "textfield",
        name = "ugg_controls_textfield",
        text = "0",
        numeric = true,
        allow_decimal = false,
        allow_negative = false,
        style = "ugg_controls_textfield"
    }




end
