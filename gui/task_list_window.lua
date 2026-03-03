--[[
task_list_window.lua contains gui elements for the main window 
with tasks.

]]--

local TASK_LIST_MAX_WINDOW_HEIGHT = 600
local AUTO_SCALE_WINDOW_HEIGHT = 0
local TASK_LIST_WINDOW_WIDTH = 400

-- Imports
local constants = require("constants")
local Gui = require("gui")
local TaskManager = require("scripts.task_manager")

local TaskListWindow = {}

--- Adds a row to the parent, for a individual task displaying title  
---@param parent LuaGuiElement The gui object that the task will be added to
---@param task Task The task object with title, desc, etc
function TaskListWindow.new_gui_task(parent, task, tab_in_ammount, selected_tasks, player)

    tab_in_ammount = tab_in_ammount or 0
    local tab_increment = 20

    -- A container to hold all tasks, controls, and subtasks 
    local task_container = parent.add {
        type="flow",
        direction="vertical",
    }

    
    -- A container to put task controls
    local controls_container = task_container.add{
        type="frame",
        style="invisible_frame",
        direction="horizontal",
    }

    -- check if the task is selected 
    local is_selected = selected_tasks[task.id] == true
    if is_selected then
        -- Style it with the selected style
        -- IMPORTANT! this is how to style background colors have to use sprites
        controls_container.style = "jolt_task_selected"
        
    end
    controls_container.style.padding = 0
    controls_container.style.margin = 0


    -- A container to put subtasks so they are tabbed in 
    local subtask_container = task_container.add{type="flow", direction="vertical"}

    -- add a name and task id so this can be identified in 
    -- an on click event
    -- A checkbox to toggle completed status 
    local checkbox_completed = controls_container.add{
        name = constants.jolt.task_list.task_checkbox,
        type="checkbox",
        state=task.is_complete,
        caption=task.title,
        tags = {is_jolt = true, task_id = task.id}
    }
    local margin = 4
    checkbox_completed.style.margin = margin

    

    -- check if the task is selected 
    local is_selected = selected_tasks[task.id] == true

    local selected_task_font_color = "#134ded"
    local unselected_task_font_color = "blue"

    -- Change the font color so it is more readable when the background color changes
    local font_color 
    if is_selected then
        font_color = selected_task_font_color
    else
        font_color = unselected_task_font_color
    end

    -- If it has a description add blue "..." indicator 
    if task.description ~= '' then
        local new_caption
        local title = checkbox_completed.caption

        -- Append to the task title
        new_caption = string.format("%s [font=default-bold][color=%s]...[/color][/font]", title, font_color)

        -- Set the new caption
        checkbox_completed.caption = new_caption
    end

    -- If it has subtasks add icon and display number of incompleted subtasks
    if #task.subtasks > 0 then
        local title = checkbox_completed.caption
        local new_caption

        -- Get number of imcompleted subtasks
        local incomplete_subtasks = #Task_manager.get_subtasks(task.id)

        -- Prepend to the task title
        new_caption = string.format("[img=%s][color=%s]%s:[/color] %s", constants.jolt.sprites.subtasks, font_color, incomplete_subtasks, title)

        -- Set the new caption
        checkbox_completed.caption = new_caption
    end

    

    -- Change the style for selected tasks
    if is_selected then
        checkbox_completed.style.font = "default-bold"
        checkbox_completed.style.font_color = {r=0, g=0, b=0}
    end
    
    if not (task.parent_id == nil) then
        tab_in_ammount = tab_in_ammount + tab_increment
        checkbox_completed.style.left_margin = tab_in_ammount
    end

    -- Push other controls to the right by making the checkbox expand
    checkbox_completed.style.maximal_width = 300
    checkbox_completed.style.minimal_width = 50
    checkbox_completed.style.horizontally_stretchable = true
    
    -- A button to edit the task
    local sbtn_edit = controls_container.add {
        type="sprite-button",
        name = constants.jolt.task_list.edit_task_button,
        sprite = constants.jolt.sprites.edit,
        tooltip={"jolt.tooltip_edit_task"},
        tags = {is_jolt = true, task_id = task.id, group_id=task.group_id}
    }
    sbtn_edit.style.size = {26,26}
    sbtn_edit.style.right_margin = 4


    -- A sprite button with cheverons to mark if the details are expanded or not
    local sbtn_details = controls_container.add {
        type="sprite-button",
        name = constants.jolt.task_list.toggle_details_button,
        sprite = constants.jolt.sprites.right,
        tooltip={"jolt.tooltip_toggle_details"},
        tags = {is_jolt = true, task_id = task.id, group_id=task.group_id}
    }
    sbtn_details.style.size = {26,26}


    -- TODO: store the show_details in the player table instead of the task
    -- If details are expanded add extra controls and subtasks
    if task.show_details then
        -- Change icon to indicate details can be collapsed
        sbtn_details.sprite = constants.jolt.sprites.down

        -- Display description 
        local description_label = Gui.new_label(task_container, task.description)
        description_label.style.maximal_width = 260
        -- Tab in the content (can't seem to do it at the container level)
        description_label.style.left_margin = tab_in_ammount + tab_increment
        -- Force onto multiple lines
        description_label.style.single_line = false

        -- add subtasks 
        if task.subtasks == nil then
            task.subtasks = {}  -- Initialize as an empty table if nil
        end

        -- need the "_" so it doens't use the index instead of the value
        for _, subtask_id in pairs(task.subtasks) do
            local subtask = Task_manager.get_task(subtask_id)

            -- If "show_complete" setting is checked then show all subtasks,
            -- Otherwise show only tasks that are not completed
            local show_completed = Task_manager.get_setting_show_completed(player)
            if show_completed or subtask.is_complete == false then
                TaskListWindow.new_gui_task(task_container, subtask, tab_in_ammount, selected_tasks, player)
            end
        end

        -- [Add subtask] button 
        local lbl_add_subtask = task_container.add {
            type="label",
            name=constants.jolt.task_list.add_subtask_button,
            caption = {"jolt_task_list_window.label_add_subtask"},
            tooltip={"jolt_task_list_window.tooltip_add_subtask"},
            style = constants.styles.text.link,
            tags = {is_jolt = true, task_id = task.id, group_id=task.group_id}
        }
        
        -- Tab in the content (can't seem to do it at the container level)
        lbl_add_subtask.style.left_margin = tab_in_ammount + tab_increment
    end

    return task_container
end

--- Open the task list menu
function TaskListWindow.open(event)
    -- Initialize data if needed
    -- !! Note: index 1 is the start not 0 in lua !!

    -- get player by index
    local player = game.get_player(event.player_index)

    -- In case a group is deleted have a fallback to the first group 
    -- to avoid a crash
    local current_group_id = Task_manager.get_current_group_id(player)
    if not Task_manager.does_group_exist(current_group_id) then
        local first_group_id = storage.jolt.group_order[1]
        Task_manager.set_current_group_id(player, first_group_id)
    end

    --region =======Task List=======

    -- Setup variables for tasks list window
    local close_button_name = constants.jolt.task_list.close_window_button
    local window_name = constants.jolt.task_list.window

    local window_width = TASK_LIST_WINDOW_WIDTH
    -- set the window height to 0 to make it auto adjust size based on the 
    -- content, (limit by setting main_frame.style.maximal_height = MAX_WINDOW_HEIGHT)
    -- see below
    local window_height = AUTO_SCALE_WINDOW_HEIGHT
    -- Make new window for tasks list
    local window = Gui.new_window(player, {"jolt.tasks_list_window_title"}, window_name, close_button_name, window_width, window_height)

    -- Add event to watch for button click to close the window
    Task_manager.bind_close_button(player, close_button_name, window_name)

    local main_frame = window.add {
        type = "frame",
        direction = "vertical",
        style = "slot_button_deep_frame",
    }
    -- Limit max height
    main_frame.style.maximal_height = TASK_LIST_MAX_WINDOW_HEIGHT
    main_frame.style.padding = 0
    main_frame.style.margin = 4
    main_frame.style.horizontal_align = "center"

    --endregion


    --region =======Tabs=======

    -- Make outer frame for style reasons
    local group_controls_frame = main_frame.add {
        type = "frame",
        direction = "vertical",
    }
    group_controls_frame.style.margin = 0
    group_controls_frame.style.padding = 4

    -- Make place to put content in
    local content_frame = main_frame.add {
        type = "frame",
        name = "content_frame",
        direction = "vertical",
        style = "jolt_content_frame"
    }
    content_frame.style.margin = 0
    content_frame.style.padding = 0

    
    -- Add label for current group name
    local lbl_current_group_name = group_controls_frame.add {
            type = "label",
            caption = "",
            horizontally_stretchable = "on"
    }
    lbl_current_group_name.style.bottom_margin = -15
    lbl_current_group_name.style.font = "default-large-bold"
    
    -- Frame for groups and group edit button
    local group_content = group_controls_frame.add {
        type = "flow",
        direction = "horizontal",
        horizontally_stretchable = "on"
    }
    group_content.style.top_padding = 12
    group_content.style.bottom_padding = 2
    group_content.style.left_margin = 0
    group_content.style.bottom_margin = 0
    group_content.style.minimal_width = 500 -- make it take up the full width

    -- Add section for tab icons
    local max_col_count = 7
    local button_table = group_content.add{
        type="table",
        name="button_table",
        column_count=max_col_count,
        style="filter_slot_table"
    }

    -- Edit groups button
    local btn_edit_groups = group_content.add {
        type = "sprite-button",
        name = constants.jolt.group_management.open_window_button,
        style = constants.styles.frame.button,
        sprite = constants.jolt.sprites.edit_group,
        tooltip = {"jolt.tooltip_edit_groups_button"},
    }
    btn_edit_groups.style.size = {32, 32}
    btn_edit_groups.style.top_margin = 6
    btn_edit_groups.style.left_margin = 24

    -- Save current group id
    local current_group_id = Task_manager.get_current_group_id(player)
    local current_group = Task_manager.get_group(current_group_id)

    -- Get group order
    local group_order = Task_manager.get_group_order()
    local groups = Task_manager.get_groups()

    --region =======Controls=======

    -- Add row for controls 
    local controls_container = content_frame.add {
        type = "frame",
        name = "jolt_controls_container",
        direction = "horizontal",
        style = "subheader_frame"
    }
    controls_container.style.minimal_height = 40
    controls_container.style.margin = 2
    controls_container.style.top_margin = 0

    -- A checkbox to toggle seeing completed/incomplete tasks
    local cb_show_completed = controls_container.add {
        type = "checkbox",
        name = constants.jolt.task_list.show_completed_checkbox,
        caption = {"jolt_task_list_window.show_completed_tasks"},
        state = Task_manager.get_setting_show_completed(player),
        horizontally_stretchable = "on"
    }
    cb_show_completed.style.right_margin = 20

    -- Only enable controls if tasks are selected
    local enable_move_controls = Task_manager.is_any_task_selected(player)

    -- Move tasks up button 
    local move_task_up_button = controls_container.add {
        type = "sprite-button",
        sprite = constants.jolt.sprites.up,
        name = constants.jolt.task_list.move_task_up_button,
        tooltip = {"jolt_task_list_window.tooltip_move_tasks_up"},
        enabled = enable_move_controls,
        tags = {is_jolt=true} -- seems to need a tag to be detected
    }
    move_task_up_button.style.size = {32, 32}

    -- Move tasks down button 
    local move_task_down_button = controls_container.add {
        type = "sprite-button",
        sprite = constants.jolt.sprites.down,
        name = constants.jolt.task_list.move_task_down_button,
        tooltip = {"jolt_task_list_window.tooltip_move_tasks_down"},
        enabled = enable_move_controls,
        tags = {is_jolt=true} -- seems to need a tag to be detected
    }
    move_task_down_button.style.size = {32, 32}
    move_task_down_button.style.right_margin = 10

    -- Delete tasks down button 
    local delete_tasks_button = controls_container.add {
        type = "sprite-button",
        sprite = constants.jolt.sprites.trash,
        name = constants.jolt.task_list.delete_tasks_button,
        tooltip = {"jolt_task_list_window.tooltip_delete_tasks"},
        enabled = enable_move_controls,
        style = constants.styles.buttons.red,
        tags = {is_jolt=true} -- seems to need a tag to be detected
    }
    delete_tasks_button.style.size = {32, 32}


    -- Empty space
    local empty_space = controls_container.add {
        type = "empty-widget",
    }
    -- Make it expand to fill the space
    empty_space.style.minimal_width = 10
    empty_space.style.height = 24
    empty_space.style.horizontally_stretchable = true

    -- Add task button
    local add_task_button = controls_container.add {
        type = "sprite-button",
        style = "confirm_button",
        sprite = constants.jolt.sprites.add,
        name = constants.jolt.task_list.add_task_button,
        tooltip = {"jolt.tootlip_add_task"}
    }
    add_task_button.style.width = 50
    add_task_button.style.height = 30


    --endregion 


    -- Add a tab for each group
    for index, value in ipairs(group_order) do
        -- Get the group from its id
        local group = Task_manager.get_group(value)

        -- Icon button is the "tab", clicking it changes to that group
        -- displaying only tasks in it
        local icon_button = button_table.add{
            type="sprite-button",
            sprite=group.icon,
            style="slot_button",
            -- Add tags since can't use the same name for each
            -- but can check tag for group_management_btn and then get group_id
            tags = {is_jolt = true, is_group_change_button=true, group_id=group.id}
        }
        -- If this button is selected change its style to
        -- be yellow button background to show it is the active group
        if group.id == current_group_id then
            icon_button.style = constants.styles.buttons.yellow
            local selected_group = group

            -- Update current group name
            lbl_current_group_name.caption = current_group.name
        end
    end

    -- Display tasks for the currently selected group
    local tab_content = content_frame.add{
        type="scroll-pane", 
        direction="vertical",
        vertical_scroll_policy = "auto",  -- Only show scrollbar when needed
        horizontal_scroll_policy = "never",
    }
    tab_content.style.padding = 10
    tab_content.style.minimal_width = 350

    -- Get the last interacted with task (may be nil)
    local last_interacted_task_id = Task_manager.get_last_interacted_task_id(player)
    local last_interacted_task_element

    local task_count = 0

    -- Get tasks, checking if the control button "Show Completed".
    -- Get's only the tasks that match the state of that checkbox (complete/incomplete)
    local group_tasks = Task_manager.get_tasks(current_group_id, Task_manager.get_setting_show_completed(player))
    for _, task in pairs(group_tasks) do

        -- Increment task counter
        task_count = task_count + 1

        -- Add a divider every 5 tasks
        local DIVIDER_COUNT = 5
        -- Add divider every 5 tasks
        if task_count > 1 and (task_count - 1) % DIVIDER_COUNT == 0 then
            tab_content.add{type="line", direction="horizontal"}
        end

        -- Check if task is selected 
        local selected_tasks = Task_manager.get_selected_tasks(player)
        local is_selected = Task_manager.is_task_selected(player, task.id)

        -- Display the task (see new_gui_task() for getting subtasks)
        local tab_in_ammount = 0
        local gui_task = TaskListWindow.new_gui_task(tab_content, task, tab_in_ammount, selected_tasks, player)
        
        -- TODO: in future if element does not exist (like when
        -- marking as done, go to next or prev element)

        -- Mark the last interacted with task (for when the scroll bar is very long)
        if last_interacted_task_id and task.id == last_interacted_task_id then
            last_interacted_task_element = gui_task
        end
    end

    -- Add placeholder text if no tasks
    if #group_tasks == 0 then
        local placeholder = tab_content.add{
            type = "label",
            caption = {"jolt_task_list_window.no_tasks_info_text"}
        }
        placeholder.style.font_color = {r=0.6, g=0.6, b=0.6}
    end

    -- Scroll to the last interacted with element 
    if last_interacted_task_element and last_interacted_task_element.valid then
        tab_content.scroll_to_element(last_interacted_task_element, "in-view")
    end

    --endregion
end

--- Closes the task list menu
function TaskListWindow.close(event)
    local player = game.get_player(event.player_index)
    player.gui.screen[constants.jolt.task_list.window].destroy()

end

return TaskListWindow