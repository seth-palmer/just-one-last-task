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

-- Event Imports 
local OnGuiClick = require("scripts.events.on_gui_click")

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
    
    -- setup visual log if needed
    VisualActionLog.initialize()
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

--- Toggles the main task list window
---@param event any
local function toggle_task_list_window(event)
    local player = game.get_player(event.player_index)
        -- debug_print(event, event)

        local is_shortcut_toggled = player.is_shortcut_toggled(constants.jolt.shortcuts.open_task_list_window)
        -- debug_print(event, "is shortcut enabled: " .. tostring(is_shortcut_toggled))

        local pinned = PlayerState.is_task_list_pinned_open(player)
        -- debug_print(event, pinned)

        -- If the window is already open close it
        if player.gui.screen[constants.jolt.task_list.window] then
            TaskListWindow.close(player)

            -- update the style of the shortcut button
            player.set_shortcut_toggled(constants.jolt.shortcuts.open_task_list_window, false)

        else -- otherwise open the task list window
            TaskListWindow.open(player)

            -- update the style of the shortcut button
            player.set_shortcut_toggled(constants.jolt.shortcuts.open_task_list_window, true)
        end
end

--- Watch for clicks on the task shortcut icon to open and close
--- the task list window
script.on_event(defines.events.on_lua_shortcut, function(event)
    -- Only react for the jolt shortcut button
    if event.prototype_name == constants.jolt.shortcuts.open_task_list_window then
        toggle_task_list_window(event)
    end
end) -- end on_lua_shortcut


-- Keyboard shortcut default (Ctrl+T)
script.on_event(constants.jolt.shortcuts.open_task_list_window, function(event)
    toggle_task_list_window(event)
end)

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
        OnGuiClick.add_new_task(event)
    end
end)



--- Called after a player selects an area with a selection-tool item.
--- JOLT uses a selection tool to set the location of tasks
---@param event any
script.on_event(defines.events.on_player_selected_area, function (event)

    -- Tool to select the location for tasks
    if event.item == constants.jolt.tools.location_selector then
        local player = game.get_player(event.player_index)

        -- Get the center of the area selected
        local area = event.area
        local location = {
            coordinates = {
                x = math.floor((area.left_top.x + area.right_bottom.x) / 2),
                y = math.floor((area.left_top.y + area.right_bottom.y) / 2),
            },
            surface_index = event.surface.index,
        }


        -- save the location 
        PlayerState.save_temp_location_for_task(player, location)

        -- update the camera in the task form window
        TaskFormWindow.refresh_task_location_camera(player, location.coordinates, location.surface_index)

        -- clear the cursor
        player.cursor_stack.clear()

        -- show form window
        local window = player.gui.screen[constants.jolt.new_task.window]
        if window then window.visible = true end

    end
end)

--- Called after a player's cursor stack changed in some way.
-- This is fired in the same tick that the change happens, but not instantly.
--- Used after the player cancels selecting a location by pressing "q"
script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
  local player = game.get_player(event.player_index)
  if not player or not player.valid then return end

  local cursor = player.cursor_stack
  if not (cursor and cursor.valid_for_read and cursor.name == constants.jolt.tools.location_selector) then
    -- Player canceled selection, clear item and state
    player.remove_item { name = constants.jolt.tools.location_selector, count = 1 }
    
    -- show form window
    local window = player.gui.screen[constants.jolt.new_task.window]
    if window then window.visible = true end
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
    if not event.element.valid then return end

    -- Do not continue if it is not a window from JOLT
    if not Task_manager.is_jolt_window(event.element.name) then return end

    -- game.print(event.element.name)


    local player = game.get_player(event.player_index)
    -- game.print("opened:...")
    -- game.print(player.opened)
    local window_name = event.element.name

    local is_window_pinned_open = PlayerState.is_task_list_pinned_open(player)
    -- game.print("is_task_list_pinned_open: " .. tostring(is_window_pinned_open))
    -- Don't close if task_list window and it is pinned open 
    if (window_name == constants.jolt.task_list.window and is_window_pinned_open) then
        return
    end

    if window_name == constants.jolt.task_list.window then
        TaskListWindow.close(player)
    end

    -- Make sure window is closed
    if event.element.valid then
        TaskFormWindow.close(player)

    end
    
    -- Can run run cleanup specific to that window (see also section in on_gui_click)
    if window_name == constants.jolt.group_management.window_name then
        GroupManagerWindow.close(player)
    end
    if window_name == constants.jolt.task_list.window then
        PlayerState.clear_selected_tasks(player)
    end
end)

-- For automated testing
if script.active_mods["factorio-test"] then
    local modules_to_load = { load_luassert = true }
    local tests_to_run = {
        "tests/single-player/tasks",
    }
    require("__factorio-test__/init")(tests_to_run, modules_to_load)
end
