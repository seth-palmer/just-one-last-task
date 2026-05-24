local constants = require "constants"
local TaskListWindow = require("gui.task_list_window")


local Migration = {}
function Migration.for_task_status()

    for task_id, task in pairs(storage.jolt.tasks) do
        -- Add the "Not Started" status to all tasks 
        task.status = constants.jolt.task_status_index.not_started

        -- remove the "is_complete" from every task 
        task.is_complete = nil

        -- remove the "show_details" from every the 0.5.0 release
        -- since it was switched to be saved per player not per task
        task.show_details = nil

        -- To debug:
        -- log("key: " .. task_id)
        -- log("data: " .. serpent.block(task))
    end
    -- log("storage data after: " .. serpent.block(storage))
    
end

Migration.for_task_status()
return Migration