
local constants = require("constants")
local Outcome = require("scripts.outcome")

PlayerState = {}


--- Initialize data for the player
---@param player_index any - player index to initialize
function PlayerState.initialize(player_index)
    local player = game.get_player(player_index)

    -- Initialize the player's data table
    if not storage.players[player.index] then
        storage.players[player.index] = {}
    end

    -- Initialize jolt specific data under a jolt key
    storage.players[player.index].jolt = {
        ui = {
            selected_tasks = {},
            selected_group_tab_id = nil, -- check if causes crash
            saved_window_locations = {},
            close_button_registry = {},
            is_task_list_pinned_open = false,
            selected_group_icon_id = nil,
            last_interacted_task_id = nil,
            show_completed_tasks = false,
        },
    }
end


--region SelectingTasks

--- Add the task to selected tasks
---@param player any
---@param task_id any
function PlayerState.add_selected_task(player, task_id)
    -- If task was already selected deselect it 
    if PlayerState.is_task_selected(player, task_id) then
        local selected_tasks = PlayerState.get_selected_tasks(player)
        selected_tasks[task_id] = nil
        return Outcome.success()
    end

    -- Only allow selecting tasks on the same level
    local selected_tasks = PlayerState.get_selected_tasks(player)
    local first_selected_id = next(selected_tasks)
    if first_selected_id and not Task_manager.are_tasks_siblings(task_id, first_selected_id) then
        -- Return error
        local error_message = {"jolt_task_list_window.error_cannot_select_non_sibling_tasks"}
        return Outcome.fail(error_message)
    end

    -- Set the task_id to true
    storage.players[player.index].jolt.ui.selected_tasks[task_id] = true
    return Outcome.success()
end

--- Returns the selected tasks for the player
---@param player any player associated
---@return table selected_tasks tasks for the player 
function PlayerState.get_selected_tasks(player)
    return storage.players[player.index].jolt.ui.selected_tasks
end

--- Returns true if there are any tasks selected 
---@param player any
---@return boolean is_any_task_selected
function PlayerState.is_any_task_selected(player)
    -- Returns nil if the table is empty
    return next(PlayerState.get_selected_tasks(player)) ~= nil
end


--- Clears all selected tasks for the player
---@param player any player associated
function PlayerState.clear_selected_tasks(player)
    storage.players[player.index].jolt.ui.selected_tasks = {}
end

--- Returns if the task is selected by the player
---@param player any player associated
---@param task_id any id of the task 
---@return boolean is_selected true if selected, false otherwise
function PlayerState.is_task_selected(player, task_id)
    local selected_tasks = PlayerState.get_selected_tasks(player)
    if not selected_tasks then
        return false
    end
    -- Return if the task is currently selected
    return selected_tasks[task_id] == true
end



--endregion SelectingTasks


--- Set the show completed setting to the new boolean
---@param new_value boolean
function PlayerState.set_setting_show_completed(player, new_value)
    storage.players[player.index].jolt.ui.show_completed_tasks = new_value
end

--- Returns the show completed setting 
--- @return boolean show_completed the value
function PlayerState.get_setting_show_completed(player)
    return storage.players[player.index].jolt.ui.show_completed_tasks
end

--- Returns the saved location of the window for the player
---@param player any with the window
---@param window_name string name of the window
function PlayerState.get_saved_window_position(player, window_name)
    -- Retrieve saved location
    local saved_location = storage.players 
        and storage.players[player.index] 
        and storage.players[player.index].jolt.ui.saved_window_locations 
        and storage.players[player.index].jolt.ui.saved_window_locations[window_name]
    
    if saved_location then
        return saved_location
    else 
        return nil
    end
end

--- Save the window location for the player
---@param player any to save location for 
---@param window_name any name of window to save
---@param new_location any coordinates to save
function PlayerState.save_window_location(player, window_name, new_location)
    -- Save
    storage.players[player.index].jolt.ui.saved_window_locations[window_name] = new_location
end

--- Save the task element last interacted with
---@param player any player associated
---@param id any task_id to save
function PlayerState.save_last_interacted_task_id(player, id)
    -- initialize if needed 
    storage.players[player.index].jolt.ui.last_interacted_task_id = storage.players[player.index].jolt.ui.last_interacted_task or {}

    -- save
    storage.players[player.index].jolt.ui.last_interacted_task_id = id
end

--- Returns the last interacted with element for the player
---@param player any player associated 
---@return string|nil last_interacted_task_id or nil if an error 
function PlayerState.get_last_interacted_task_id(player)
    local last_interacted_task_id = storage.players
        and storage.players[player.index]
        and storage.players[player.index].jolt.ui.last_interacted_task_id
    if last_interacted_task_id then
        return last_interacted_task_id
    else
        return nil
    end
end

--- Bind a button to close the provided window
---@param player any player associated 
---@param button_name any when clicked closes the window
---@param window_name any window to close
function PlayerState.bind_close_button(player, button_name, window_name)
    -- bind close button to window 
    storage.players[player.index].jolt.ui.close_button_registry[button_name] = window_name
end

--- Returns and removes the window name mapping for the button, or nil if not found
---@param player any player associated
---@param button_name string button to remove the mapping from
---@return string|nil window_name The name of the window to close
function PlayerState.pop_close_button(player, button_name)
    local registry = storage.players[player.index].jolt.ui.close_button_registry
    local window_name = registry[button_name]
    registry[button_name] = nil  -- Remove the mapping
    return window_name
end


--- Returns the current group id
---@param player any player associated
---@return string|nil current_group_id id of the current group for the player
function PlayerState.get_current_group_id(player)
    local current_group_id = storage.players[player.index].jolt.ui.selected_group_tab_id

    return current_group_id
end

--- Sets the current group id
---@param player any player associated
---@param new_id string new group_id to save
function PlayerState.set_current_group_id(player, new_id)
    storage.players[player.index].jolt.ui.selected_group_tab_id = new_id
end


--- Returns if the task list window is pinned open for the player
---@param player any - associated player
function PlayerState.is_task_list_pinned_open(player)
    local is_task_list_pinned_open = storage.players[player.index].jolt.ui.is_task_list_pinned_open
    return is_task_list_pinned_open
end

--- Toggle the pinned state of the task list window
---@param player any - associated player
function PlayerState.toggle_task_list_pinned_open(player)
    -- Invert the boolean
    storage.players[player.index].jolt.ui.is_task_list_pinned_open = 
    not storage.players[player.index].jolt.ui.is_task_list_pinned_open
end

--- Returns the selected group in the group management window
---@param player any - player associated
function PlayerState.get_group_management_selected_group_id(player)
    local group_id = storage.players[player.index].jolt.ui.selected_group_icon_id
    return group_id
end

--- Sets the selected group in the group management window
---@param player any - player associated
---@param new_id string - new group_id to save
function PlayerState.set_group_management_selected_group_id(player, new_id)
    storage.players[player.index].jolt.ui.selected_group_icon_id = new_id
end

--- Clears the selected group in the group management window
---@param player any - player associated
function PlayerState.clear_group_management_selected_group_id(player)
    storage.players[player.index].jolt.ui.selected_group_icon_id = nil
end

return PlayerState