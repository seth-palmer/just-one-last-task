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

--- Test if window opens/closes and buttons exist
describe("window basic tests", function ()
    local player
    before_all(function ()
        Task_manager = TaskManager.new()

        -- open the task list window
        player = game.players[1]
        TaskListWindow.open(player)
    end)
    test("task list window opens", function ()
        TaskListWindow.open(player)

        -- check the window opens
        local window = player.gui.screen[constants.jolt.task_list.window]
        assert(window.valid)
    end)

    test("task list window closes", function ()
        TaskListWindow.open(player)
        TaskListWindow.close(player)
        
        -- check the window closes
        local window = player.gui.screen[constants.jolt.task_list.window]
        assert.is_nil(window)
    end)

    test("add task button exists", function ()
        TaskListWindow.open(player)

        local window = player.gui.screen[constants.jolt.task_list.window]
        local add_task_button = Utils.find_element(window, constants.jolt.task_list.add_task_button)

        assert.equals(add_task_button.valid, true)
    end)
end)

describe("adding tasks", function ()
    local player
    before_all(function ()
        Task_manager = TaskManager.new()

        -- open the task list window
        player = game.players[1]
        TaskListWindow.open(player)
    end)

    test("new task window opens", function ()
        local window = player.gui.screen[constants.jolt.task_list.window]
        -- TaskFormWindow.open()
    end)


    test.todo("new task window closes when back button is pressed", function ()
        
    end)

    test.todo("new task not created when no title provided", function ()
        
    end)

    test.todo("new task with title created and is in group list", function ()
        
    end)

    test.todo("when task is created new task window closes", function ()
        
    end)

    test.todo("new task window defaults to currently selected group", function ()
        
    end)

end)

-- template group
describe("", function ()
    local player
    before_all(function ()
        Task_manager = TaskManager.new()

        -- open the task list window
        player = game.players[1]
        TaskListWindow.open(player)
    end)

    test.todo("", function ()
        
    end)
end)


describe("marking tasks complete or incomplete", function ()
    local player
    before_all(function ()
        Task_manager = TaskManager.new()

        -- open the task list window
        player = game.players[1]
        TaskListWindow.open(player)
    end)

    describe("show completed checkbox is false", function ()
        test.todo("task marked complete hides the task", function ()
        
        end)
    end)

    describe("show completed checkbox is true", function ()
        test.todo("task marked complete leaves the task visible", function ()
        
        end)
    end)
end)


describe("expanding and collapsing task details", function ()
    local player
    before_all(function ()
        Task_manager = TaskManager.new()

        -- open the task list window
        player = game.players[1]
        TaskListWindow.open(player)
    end)

    test.todo("clicking expand button shows description", function ()
        
    end)

    test.todo("clicking collapse button hides description", function ()
        
    end)

    test.todo("clicking expand button shows subtasks", function ()
        
    end)

    test.todo("clicking collapse button hides subtasks", function ()
        
    end)
end)
