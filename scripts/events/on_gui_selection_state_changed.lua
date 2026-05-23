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


local OnGuiSelectionStateChanged = {}

--- Called when the dropdown for task status in the main task list window is changed
function OnGuiSelectionStateChanged.dropdown_task_status_changed(player, event)
    -- Update the task with the new status 
    local new_status = event.element.selected_index
    local task_id = event.element.tags.task_id

    if new_status and task_id then
        -- get the task 
        local task = Task_manager.get_task(task_id)
        task.status = new_status


        local outcome = Task_manager.update_task(task, task_id)

        -- log task updated if succeeded
        if outcome.success then
            local group_id = task.group_id or Task_manager.get_parent_group(task.id)
            local data = {task_id = task_id, group_id = group_id}
            VisualActionLog.add(constants.jolt.actions.edited_task, data)

            TaskListWindow.refresh_for_all()
        end

        
    end
end

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    -- Exit if invalid
    if not Utils.is_element_from_jolt_mod(event) then
        return
    end

    -- Get the player that is interacting with our gui
    local player = game.get_player(event.player_index)

    if event.element and event.element.tags and event.element.tags.name then
        local name = event.element.tags.name

        -- Dropdown for each task's status in main list
        if name == constants.jolt.task_list.dropdown_status_tag then
            OnGuiSelectionStateChanged.dropdown_task_status_changed(player, event)
        end
    end

end)

return OnGuiSelectionStateChanged