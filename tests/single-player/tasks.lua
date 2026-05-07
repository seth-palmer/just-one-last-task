---@diagnostic disable: undefined-global, undefined-field
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
local DEFAULT_START_GROUP_ID = "a1"

local function delete_all_tasks()
    storage.jolt.tasks = {}
    storage.jolt.priorities = {}
end

local function reset_groups_to_default()
    local nauvis_group = {id=DEFAULT_START_GROUP_ID, name="Nauvis", icon="space-location/nauvis"}
    local default_group_data = {}
    default_group_data[nauvis_group.id] = nauvis_group
    local default_group_order = {DEFAULT_START_GROUP_ID}
    storage.jolt.groups = default_group_data
    storage.jolt.group_order = default_group_order
end

local function add_task(player, title)
    local window = player.gui.screen[constants.jolt.task_list.window]
    local event = {player_index = player.index}
    
    TaskFormWindow.open(player, {})

    local task_form_window = player.gui.screen[constants.jolt.new_task.window]
    local title_textbox = Utils.find_element(task_form_window, constants.jolt.new_task.title_textbox)
    
    title_textbox.text = title

    local add_task_button = Utils.find_element(task_form_window, constants.jolt.new_task.confirm_button)
    local event = {player_index = player.index, control = false}
    local new_task_id = Click.add_new_task(event)

    return new_task_id
end

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
    local group_id
    before_all(function ()
        Task_manager = TaskManager.new()

        -- open the task list window
        player = game.players[1]
        TaskListWindow.open(player)

        -- get the first group
        group_id = next(Task_manager.get_groups())
    end)

    before_each(function ()
        delete_all_tasks()
        reset_groups_to_default()
    end)

    after_each(function ()
        TaskFormWindow.close(player)
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


    test("new task window closes", function ()
        
        TaskFormWindow.close(player)

        local task_form_window = player.gui.screen[constants.jolt.new_task.window]
        assert.equals(nil, task_form_window)
    end)

    test("new task not created when no title provided", function ()
        local window = player.gui.screen[constants.jolt.task_list.window]
        
        TaskFormWindow.open(player, {})

        local task_form_window = player.gui.screen[constants.jolt.new_task.window]
        local add_task_button = Utils.find_element(task_form_window, constants.jolt.new_task.confirm_button)

        assert.equals(true, add_task_button.valid)


        local event = {player_index = player.index, control = false}
        local new_task_id = Click.add_new_task(event)
        assert.equals(nil, new_task_id)


        -- form should remain open 
        assert.equals(true, task_form_window.valid)

        local group_id = DEFAULT_START_GROUP_ID
        -- no task should be created (count children)
        local group_scroll_pane = Utils.find_element(window, constants.jolt.task_list.tasks_scroll_pane_prefix .. group_id)
        -- should have only one child (the "No tasks" message)
        assert.equals(1, #group_scroll_pane.children)
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



    test("new task window defaults to currently selected group", function ()
        
        -- add group 
        local new_group = {name = "2", icon="space-location/nauvis"}
        local new_group_id = Task_manager.add_group(new_group)
        assert.equals(true, new_group_id ~= nil)

        -- select that group
        PlayerState.set_current_group_id(player, new_group_id)

        TaskFormWindow.open(player, {})
        local task_form_window = player.gui.screen[constants.jolt.new_task.window]


        local group_dropdown = Utils.find_element(task_form_window, constants.jolt.new_task.group_dropdown)
        -- should be two groups in the dropdow and the second one selected
        assert.equals(true, group_dropdown.valid)
        assert.equals(2, #group_dropdown.items)
        assert.equals(2, group_dropdown.selected_index)
    end)

end)


describe("adding subtask", function ()
    local player
    before_all(function ()
        reset_groups_to_default()
        delete_all_tasks()
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
        reset_groups_to_default()
        delete_all_tasks()
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
        reset_groups_to_default()
        delete_all_tasks()
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
        reset_groups_to_default()
        delete_all_tasks()
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

    test("pinned window closes when groups window is opened", function ()
        local is_pinned = PlayerState.is_task_list_pinned_open(player)

        if is_pinned then
            PlayerState.toggle_task_list_pinned_open(player)
        end

        GroupManagerWindow.open(player)
        local task_list_window = player.gui.screen[constants.jolt.task_list.window]
        local group_manager_window = player.gui.screen[constants.jolt.group_management.window_name]
        
        assert.equals(nil, task_list_window)
        assert.equals(true, group_manager_window.valid)
    end)
end)

describe.only("selecting tasks", function ()
    local player
    local group_2_id
    local task_1_id
    before_all(function ()
        reset_groups_to_default()
        delete_all_tasks()

        Task_manager = TaskManager.new()

        -- open the task list window
        player = game.players[1]
        TaskListWindow.open(player)

        local group_2 = {name = "2", icon="space-location/nauvis"}
        group_2_id = Task_manager.add_group(group_2)

        
        -- Add 3 tasks to group 1
        PlayerState.set_current_group_id(player, DEFAULT_START_GROUP_ID)
        task_1_id = add_task(player, "task 1")
        local task_2_id = add_task(player, "task 2")
        local task_3_id = add_task(player, "task 3")

        -- Add 1 task to group 2
        PlayerState.set_current_group_id(player, group_2_id)
        local task_1_id = add_task(player, "task 1b")

        PlayerState.set_current_group_id(player, DEFAULT_START_GROUP_ID)
    end)


    before_each(function ()
        PlayerState.set_setting_show_completed(player, false)
        PlayerState.clear_selected_tasks(player)
        TaskListWindow.open(player)
    end)
    

    test("test selecting a task changes it visually", function ()
        local window = player.gui.screen[constants.jolt.task_list.window]

        -- select a task 
        PlayerState.add_selected_task(player, task_1_id)
        local data = {task_id = task_1_id}
        VisualActionLog.add(constants.jolt.actions.selected_task, data)

        TaskListWindow.refresh_for_all()

        -- task selected
        local selected_tasks = PlayerState.get_selected_tasks(player)
        -- use assert.same for table comparisons
        assert.equals(true, selected_tasks[task_1_id])

        -- task should be highlighted
        local task_row = Utils.find_element(window, constants.jolt.task_list.tasks_row_prefix .. task_1_id)
        local controls_container = task_row.children[1]
        assert.equals(constants.jolt.styles.backgrounds.selected, controls_container.style.name)
    end)
    test("test deselecting a task changes it visually", function ()
        local window = player.gui.screen[constants.jolt.task_list.window]

        -- select a task 
        PlayerState.add_selected_task(player, task_1_id)
        local data = {task_id = task_1_id}
        VisualActionLog.add(constants.jolt.actions.selected_task, data)
        TaskListWindow.refresh_for_all()

        -- select the same task to deselect it 
        PlayerState.add_selected_task(player, task_1_id)
        local data = {task_id = task_1_id}
        VisualActionLog.add(constants.jolt.actions.selected_task, data)
        TaskListWindow.refresh_for_all()

        -- no tasks selected
        local selected_tasks = PlayerState.get_selected_tasks(player)
        -- use assert.same for table comparisons
        assert.equals(nil, selected_tasks[task_1_id])

        -- task should not be highlighted
        local task_row = Utils.find_element(window, constants.jolt.task_list.tasks_row_prefix .. task_1_id)
        local controls_container = task_row.children[1]
        assert.not_equals(constants.jolt.styles.backgrounds.selected, controls_container.style.name)
        
    end)
    test("test changing groups deselects tasks", function ()
        local window = player.gui.screen[constants.jolt.task_list.window]

        -- steps taken from "event.element.tags.is_group_change_button then" in on_gui_click.lua
        -- then moved those steps to the fn "OnGuiClick.group_change_button"
        -- to test for easily

        -- select a task 
        PlayerState.add_selected_task(player, task_1_id)
        local data = {task_id = task_1_id}
        VisualActionLog.add(constants.jolt.actions.selected_task, data)

        TaskListWindow.refresh_for_all()

        local event = {element = {tags = {}}}
        event.element.tags.group_id = group_2_id
        Click.group_change_button(player, event)

        -- change back to original group 
        local event = {element = {tags = {}}}
        event.element.tags.group_id = DEFAULT_START_GROUP_ID
        Click.group_change_button(player, event)

        -- no tasks selected
        local selected_tasks = PlayerState.get_selected_tasks(player)
        -- use assert.same for table comparisons
        assert.same({}, selected_tasks)

        -- task should be not highlighted
        local task_row = Utils.find_element(window, constants.jolt.task_list.tasks_row_prefix .. task_1_id)
        local controls_container = task_row.children[1]
        assert.equals(false, constants.jolt.styles.backgrounds.selected == controls_container.style.name)
    end)
    test("test toggling on show completed does not clear selected tasks", function ()

        -- select a task 
        PlayerState.add_selected_task(player, task_1_id)
        local data = {task_id = task_1_id}
        VisualActionLog.add(constants.jolt.actions.selected_task, data)

        TaskListWindow.refresh_for_all()

        -- task selected
        local selected_tasks = PlayerState.get_selected_tasks(player)
        assert.equals(true, selected_tasks[task_1_id])

        PlayerState.set_setting_show_completed(player, false)
        Click.toggle_show_completed_checkbox(player)

        -- task should still be highlighted

        -- need to refetch the window AFTER refreshes
        local window = player.gui.screen[constants.jolt.task_list.window]
        local task_row = Utils.find_element(window, constants.jolt.task_list.tasks_row_prefix .. task_1_id)
        local controls_container = task_row.children[1]
        assert.equals(true, constants.jolt.styles.backgrounds.selected == controls_container.style.name)
    end)
    test("test toggling off show completed clears selected tasks", function ()
        local window = player.gui.screen[constants.jolt.task_list.window]

        -- select a task 
        PlayerState.add_selected_task(player, task_1_id)
        local data = {task_id = task_1_id}
        VisualActionLog.add(constants.jolt.actions.selected_task, data)

        TaskListWindow.refresh_for_all()

        -- task selected
        local selected_tasks = PlayerState.get_selected_tasks(player)
        -- use assert.same for table comparisons
        assert.equals(true, selected_tasks[task_1_id])

        Click.toggle_show_completed_checkbox(player)
        Click.toggle_show_completed_checkbox(player)

        -- need to refetch the window AFTER refreshes
        local window = player.gui.screen[constants.jolt.task_list.window]

        -- task should be not be highlighted
        local task_row = Utils.find_element(window, constants.jolt.task_list.tasks_row_prefix .. task_1_id)
        local controls_container = task_row.children[1]
        assert.equals(false, constants.jolt.styles.backgrounds.selected == controls_container.style.name)
    end)
end)


describe("moving tasks", function ()
    local player
    before_all(function ()
        reset_groups_to_default()
        delete_all_tasks()
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
        reset_groups_to_default()
        delete_all_tasks()
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
        reset_groups_to_default()
        delete_all_tasks()
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
