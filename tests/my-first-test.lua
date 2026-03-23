local constants = require("constants")
local Utils = require("scripts.utils")
local TaskListWindow = require("gui.task_list_window")


--- Opens the just-one-last-task (JOLT) window
local function open_task_list_window()
    local player = game.players[1]
    TaskListWindow.open(player)
end

-- -- my-first-test.lua
-- test("Hello, World!", function()
--     assert(game.surfaces[1].name == "nauvis")
-- end)

-- test.todo("test location")


-- test("clicking add task button creates a task", function()
--     local player = game.players[1]

--     open_task_list_window()

--     -- navigate the GUI tree to find your element
--     local window = player.gui.screen[constants.jolt.task_list.window]
--     local button = Utils.find_element(window, constants.jolt.task_list.add_task_button)

--     assert(button.valid)
-- end)

-- -----------------------------------

