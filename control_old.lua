-- variables (read only)
local item_sprites = {"inserter", "transport-belt", "stone-furnace", "assembling-machine-3", "storage-chest", "sulfur", "utility-science-pack", "laser-turret"}


-- Make sure the intro cinematic of freeplay doesn't play every time we restart
-- This is just for convenience, don't worry if you don't understand how this works
script.on_init(function()
    local freeplay = remote.interfaces["freeplay"]
    if freeplay then  -- Disable freeplay popup-message
        if freeplay["set_skip_intro"] then remote.call("freeplay", "set_skip_intro", true) end
        if freeplay["set_disable_crashsite"] then remote.call("freeplay", "set_disable_crashsite", true) end
    end

    -- store players and their info
    storage.players = {}
end)


script.on_event(defines.events.on_player_created, function(event)
    -- get player by index
    local player = game.get_player(event.player_index)
    -- initialize our data for the player
    storage.players[player.index] = { controls_active = true, button_count = 0, next_task_id = 0, tasks = {} }

    local screen_element = player.gui.screen
    local main_frame = screen_element.add{type="frame", name="ugg_main_frame", caption={"ugg.mod_title"}}
    main_frame.style.size = {400, 600}
    main_frame.auto_center = true




    local content_frame = main_frame.add{type="frame", name="content_frame", direction="vertical", style="ugg_content_frame"}
    local controls_flow = content_frame.add{type="flow", name="controls_flow", direction="horizontal", style="ugg_controls_flow"}

    controls_flow.add{type="button", name="ugg_controls_toggle", caption={"ugg.deactivate"}}

    -- a slider and textfield
    controls_flow.add{type="slider", name="ugg_controls_slider", value=0, minimum_value=0, maximum_value=#item_sprites, style="notched_slider"}


    controls_flow.add{type="textfield", name="ugg_controls_textfield", text="0", numeric=true, allow_decimal=false, allow_negative=false, style="ugg_controls_textfield"}


    --second row
    local task_list = content_frame.add{type="frame", name="task_list", direction="vertical", style="task_list"}

--     task_list.add{type="label", name="task_demo", caption="A Task"}

    --3rd row
    local task_controls = content_frame.add{type="frame", name="task_controls", direction="horizontal", style="task_controls"}

    task_controls.add{type="textfield", name="task_add_textfield", text="Add Task Here!", style="jolt_add_task_textfield"}

    local color_green = {0, 1, 0, 1}
    -- add button
    task_controls.add{type="button", color=color_green, name="jolt_add", caption={"jolt.add"}}
end)


script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "ugg_controls_toggle" then
        local player_storage = storage.players[event.player_index]
        player_storage.controls_active = not player_storage.controls_active

        local control_toggle = event.element
        control_toggle.caption = (player_storage.controls_active) and {"ugg.deactivate"} or {"ugg.activate"}

        local player = game.get_player(event.player_index)
        local controls_flow = player.gui.screen.ugg_main_frame.content_frame.controls_flow
        controls_flow.ugg_controls_slider.enabled = player_storage.controls_active
        controls_flow.ugg_controls_textfield.enabled = player_storage.controls_active
    end

    -- if add button pressed
    if event.element.name == "jolt_add" then
        local player_storage = storage.players[event.player_index]
        local player = game.get_player(event.player_index)

        -- get text in textfield
        local task_controls = player.gui.screen.ugg_main_frame.content_frame.task_controls
        local new_task_text = task_controls.task_add_textfield.text

        local task_id = "task_" .. player_storage.next_task_id
        player_storage.next_task_id = player_storage.next_task_id + 1
        local task = {type="label", name=task_id, caption=new_task_text}
--         player_storage.tasks.add(task)

        -- make new task object
        --newTask = newTask(1, new_task_text)

        -- add to list


        add_task(player, task)
        update_tasks(player)
--         local task_list = player.gui.screen.ugg_main_frame.content_frame.task_list
--         task_list.add{type="label", name=task_id, caption=new_task_text}
    end

end)

-- Add task for player
--- @param player - player to add to
--- @param task -   task details
function add_task (player, task)
    task.is_done = true
    local player_storage = storage.players[player.index]
    table.insert(player_storage.tasks, task)
end


function display_task (player, task)

end

-- Make a new Task object (sets as InComplete)
-- @initialPriority - priority to add it with (1 = highest)
-- @initialTitle -   task title
function newTask (initialPriority, initialTitle)
    -- default values
    local defaultIsComplete = false

    local self = {priority = initialPriority, title = initialTitle, isComplete = defaultIsComplete}

    -- TODO functions (edit title, edit desc)

    -- Set priority to provided value
    -- TODO - use larger class to swap priorities
    local setPriority = function (v)
                            self.priority = v
                        end
    local markComplete = function ()
                            self.isComplete = true
                          end
    local markIncomplete = function ()
                            self.isComplete = false
                          end

    -- Getters
    local getPriority = function () return self.priority end
    local getTitle = function () return self.title end
    local isComplete = function () return self.isComplete end

    return {
        setPriority = setPriority,
        markComplete = markComplete,
        markIncomplete = markIncomplete,
        getPriority,
        getTitle,
        isComplete
    }
end



-- Mark task as done
-- @player - player to delete from
-- @task -   task details
function mark_task_done (player, task)
    local player_storage = storage.players[player.index]
    task.is_done = true
    table.insert(player_storage.tasks, task)
end

-- Updates all tasks for player
-- @player player to update task list
function update_tasks (player)
    -- get the task list
    local task_list = player.gui.screen.ugg_main_frame.content_frame.task_list
    local player_storage = storage.players[player.index]

    -- clear the current list
    task_list.clear()

    -- Use ipairs to iterate through a numerical array - https://www.lua.org/pil/7.3.html
    -- adding each task
    for _, task in ipairs(player_storage.tasks) do
        if not task.is_done then
            task_list.add(task) -- add to gui
        else
            task.caption = "[done] " .. task.caption
            red1 = {r = 0.5, g = 0, b = 0, a = 0.5}
            local label = task_list.add(task)

            -- must set the style to the element after it is created
            label.style.font_color = red1

        end
    end
end




script.on_event(defines.events.on_gui_value_changed, function(event)
  if event.element.name == "ugg_controls_slider" then
    local player = game.get_player(event.player_index)
    local player_storage = storage.players[player.index]

    local new_button_count = event.element.slider_value
    player_storage.button_count = new_button_count

    local controls_flow = player.gui.screen.ugg_main_frame.content_frame.controls_flow
    controls_flow.ugg_controls_textfield.text = tostring(new_button_count)
  end

end)


script.on_event(defines.events.on_gui_text_changed, function(event)
    if event.element.name == "ugg_controls_textfield" then
        local player = game.get_player(event.player_index)
        local player_storage = storage.players[player.index]

        -- button count
        local new_button_count = tonumber(event.element.text) or 0
        local capped_button_count = math.min(new_button_count, #item_sprites)
        player_storage.button_count = capped_button_count

        local controls_flow = player.gui.screen.ugg_main_frame.content_frame.controls_flow
        controls_flow.ugg_controls_slider.slider_value = capped_button_count
    end

end)





