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

local Click = require("scripts.events.on_gui_click")

--- Test if window opens/closes and buttons exist
describe("task list window opens and closes", function ()
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

end)


describe("adding task", function ()
    local player
    before_all(function ()
        Task_manager = TaskManager.new()

        -- open the task list window
        player = game.players[1]
        TaskListWindow.open(player)
    end)

    test("add task button exists", function ()
        TaskListWindow.open(player)

        local window = player.gui.screen[constants.jolt.task_list.window]
        local add_task_button = Utils.find_element(window, constants.jolt.task_list.add_task_button)

        assert.equals(add_task_button.valid, true)
    end)

    test("new task window opens", function ()
        local window = player.gui.screen[constants.jolt.task_list.window]
        
        local event = {player_index = player.index}
        
        TaskFormWindow.open(player, {})

        local task_form_window = player.gui.screen[constants.jolt.new_task.window]

        assert.equals(true, task_form_window.valid)
    end)


    test.todo("new task window closes when back button is pressed", function ()
        
    end)

    test.todo("new task not created when no title provided", function ()
        local window = player.gui.screen[constants.jolt.task_list.window]
        local event = {player_index = player.index}
        
        TaskFormWindow.open(player, {})

        local task_form_window = player.gui.screen[constants.jolt.new_task.window]
        local add_task_button = Utils.find_element(task_form_window, constants.jolt.new_task.confirm_button)

        assert.equals(true, add_task_button.valid)


        local event = {player_index = player.index, control = false}
        Click.add_new_task(event)

        -- form should remain open 
        assert.equals(true, task_form_window.valid)

        -- no task should be created
    end)

    test("new task with title created and is in group list", function ()
        local window = player.gui.screen[constants.jolt.task_list.window]
        local event = {player_index = player.index}
        
        TaskFormWindow.open(player, {})

        local task_form_window = player.gui.screen[constants.jolt.new_task.window]


        local title_textbox = Utils.find_element(task_form_window, constants.jolt.new_task.title_textbox)
        assert.equals(true, title_textbox.valid)
        
        title_textbox.text = "new task with title"

        local add_task_button = Utils.find_element(task_form_window, constants.jolt.new_task.confirm_button)
        local event = {player_index = player.index, control = false}
        local new_task_id = Click.add_new_task(event)

        -- form should close 
        assert.equals(false, task_form_window.valid)
        assert.equals(true, new_task_id ~= nil)

        -- task should be created
        local task_row = Utils.find_element(window, constants.jolt.task_list.tasks_row_prefix .. new_task_id)
        assert.equals(true, task_row.valid)
    end)

    test("new task with title created and is in group list", function ()
        local window = player.gui.screen[constants.jolt.task_list.window]
        local event = {player_index = player.index}
        
        TaskFormWindow.open(player, {})

        local task_form_window = player.gui.screen[constants.jolt.new_task.window]


        local title_textbox = Utils.find_element(task_form_window, constants.jolt.new_task.title_textbox)
        assert.equals(true, title_textbox.valid)
        
        title_textbox.text = "task where form stays open"

        local add_task_button = Utils.find_element(task_form_window, constants.jolt.new_task.confirm_button)
        local event = {player_index = player.index, control = true}
        local new_task_id = Click.add_new_task(event)

        -- form should stay open 
        assert.equals(true, task_form_window.valid)
        assert.equals(true, new_task_id ~= nil)

        -- task should be created
        local task_row = Utils.find_element(window, constants.jolt.task_list.tasks_row_prefix .. new_task_id)
        assert.equals(true, task_row.valid)
    end)



    test.todo("new task window defaults to currently selected group", function ()
        
    end)

end)


describe("adding subtask", function ()
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

describe("editing task", function ()
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


describe("marking task complete or incomplete", function ()
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


describe("pinning task list window open", function ()
    local player
    before_all(function ()
        Task_manager = TaskManager.new()

        -- open the task list window
        player = game.players[1]
        TaskListWindow.open(player)
    end)

    before_each(function ()
        TaskListWindow.open(player)
    end)

    after_each(function ()
        TaskListWindow.close(player)
        GroupManagerWindow.close(player)
    end)

    after_all(function ()
        TaskListWindow.close(player)
        GroupManagerWindow.close(player)

        local is_pinned = PlayerState.is_task_list_pinned_open(player)

        -- un pin window 
        if is_pinned then
            PlayerState.toggle_task_list_pinned_open(player)
        end
    end)

    test("pinned window stays open when new task window is opened", function ()
        local is_pinned = PlayerState.is_task_list_pinned_open(player)

        if not is_pinned then
            PlayerState.toggle_task_list_pinned_open(player)
        end

        GroupManagerWindow.open(player)
        local task_list_window = player.gui.screen[constants.jolt.task_list.window]
        local group_manager_window = player.gui.screen[constants.jolt.group_management.window_name]
        assert.equals(true, task_list_window.valid)
    end)

    test("pinned window closes when new task window is opened", function ()
        local is_pinned = PlayerState.is_task_list_pinned_open(player)

        if is_pinned then
            PlayerState.toggle_task_list_pinned_open(player)
        end

        GroupManagerWindow.open(player)
        local task_list_window = player.gui.screen[constants.jolt.task_list.window]
        local group_manager_window = player.gui.screen[constants.jolt.group_management.window_name]
        
        assert.equals(false, task_list_window.valid)
        assert.equals(true, group_manager_window.valid)
    end)
end)


describe("selecting tasks", function ()
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


describe("moving tasks", function ()
    local player
    before_all(function ()
        Task_manager = TaskManager.new()

        -- open the task list window
        player = game.players[1]
        TaskListWindow.open(player)
    end)

    

    describe("moving task up", function ()
        test("moving task up button disabled if no tasks selected", function ()
            local window =  player.gui.screen[constants.jolt.task_list.window]
            
            local move_tasks_up_button = Utils.find_element(window, constants.jolt.task_list.move_task_up_button)
            
            assert.equals(true, move_tasks_up_button.valid)
            assert.equals(false, move_tasks_up_button.enabled)
        end)
    end)

    describe("moving task down", function ()
        test("moving task down button disabled if no tasks selected", function ()
            local window =  player.gui.screen[constants.jolt.task_list.window]
            
            local move_tasks_down_button = Utils.find_element(window, constants.jolt.task_list.move_task_down_button)
            
            assert.equals(true, move_tasks_down_button.valid)
            assert.equals(false, move_tasks_down_button.enabled)
        end)
    end)
end)



describe("deleting tasks", function ()
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



describe("task location", function ()
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
