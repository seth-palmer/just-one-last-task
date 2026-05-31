local constants = require "constants"
local TaskListWindow = require("gui.task_list_window")


local Migration = {}
function Migration.for_internal_data_structure()
    if storage.task_data and not storage.jolt then
        log("jolt: migrating old data structure from 0.1.0")
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
                            tasks_show_details_state_list = {},
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
end

Migration.for_internal_data_structure()
return Migration