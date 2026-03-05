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
local PlayerState = require("scripts.player_state")
local VisualActionLog = require("scripts.visual_action_log")


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
        name = constants.jolt.task_list.tasks_row_prefix .. task.id,
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
        controls_container.style = constants.jolt.styles.backgrounds.selected
        
    end
    controls_container.style.padding = 0
    controls_container.style.margin = 2



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
            local show_completed = PlayerState.get_setting_show_completed(player)
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
    local current_group_id = PlayerState.get_current_group_id(player)
    if not Task_manager.does_group_exist(current_group_id) then
        local first_group_id = storage.jolt.group_order[1]
        PlayerState.set_current_group_id(player, first_group_id)
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
    PlayerState.bind_close_button(player, close_button_name, window_name)

    local main_frame = window.add {
        type = "frame",
        direction = "vertical",
        name = "main_frame",
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
        name = "group_controls_frame",
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
        name = "group_content",
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
    local current_group_id = PlayerState.get_current_group_id(player)
    local current_group = Task_manager.get_group(current_group_id)

    -- Get group order
    local group_order = Task_manager.get_group_order()
    local groups = Task_manager.get_groups()

    -- Add controls for window
    TaskListWindow.add_controls(player, content_frame)

    -- Add a tab for each group
    for index, group_id in ipairs(group_order) do
        -- Get the group from its id
        local group = Task_manager.get_group(group_id)

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

            -- Update current group name
            lbl_current_group_name.caption = current_group.name
        end

        -- Add tasks for group

        -- Display tasks for the currently selected group
        local tab_content = content_frame.add{
            type="scroll-pane", 
            direction="vertical",
            vertical_scroll_policy = "auto",  -- Only show scrollbar when needed
            horizontal_scroll_policy = "never",
            name = constants.jolt.task_list.tasks_scroll_pane_prefix .. group.id,
            -- only make scroll-pane visible for current group
            visible = (group.id == current_group_id),
        }
        tab_content.style.padding = 10
        tab_content.style.minimal_width = 350

        -- Add tasks and do full refresh for group tasks
        TaskListWindow.refresh_group(player, group.id)
    end

    --endregion
end


--- Adds the controls to top of the the provided parent
---@param player any - player associated
---@param parent any - parent to add it to
function TaskListWindow.add_controls(player, parent)
    -- Remove it it already exists
    if parent.jolt_controls_container then
        parent.jolt_controls_container.destroy()
    end

    -- Add row for controls 
    local controls_container = parent.add {
        index = 1, -- Add to top so when readded to refresh is put above the task list
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
        state = PlayerState.get_setting_show_completed(player),
        horizontally_stretchable = "on"
    }
    cb_show_completed.style.right_margin = 20

    -- Only enable controls if tasks are selected
    local enable_move_controls = PlayerState.is_any_task_selected(player)

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
end

--- Closes the task list menu
function TaskListWindow.close(player)
    if player.gui.screen[constants.jolt.task_list.window] then
        player.gui.screen[constants.jolt.task_list.window].destroy()
    end
end



--region Local_Refresh_Functions

--- Refreshes the groups list
---@param player any
local function refresh_current_group(player)
    local selected_group_id = PlayerState.get_current_group_id(player)
    
    local window = player.gui.screen[constants.jolt.task_list.window]
    if not window or not window.valid then return end

    local content_frame = window.main_frame.content_frame
    local group_order = Task_manager.get_group_order()

    -- hide all scroll panes except the current one
    for _, group_id in ipairs(group_order) do
        local pane = content_frame[constants.jolt.task_list.tasks_scroll_pane_prefix .. group_id]
        if pane and pane.valid then
            pane.visible = (group_id == selected_group_id)
        end
    end


    -- update to highlight the current group
    local button_table = window.main_frame.group_controls_frame.group_content.button_table

    for _, child in ipairs(button_table.children) do
        if child.tags.group_id == selected_group_id then
            child.style = constants.styles.buttons.yellow
        else 
            child.style = "slot_button"
        end
    end
end



--- Gets the scroll pane for a group
---@param player LuaPlayer
---@param group_id string
---@return LuaGuiElement|nil
local function get_group_pane(player, group_id)
    local window = player.gui.screen[constants.jolt.task_list.window]
    if not window or not window.valid then return nil end
    return window.main_frame.content_frame[
        constants.jolt.task_list.tasks_scroll_pane_prefix .. group_id
    ]
end

--- Gets a task row element by task_id
---@param player LuaPlayer
---@param group_id string
---@param task_id string
---@return LuaGuiElement|nil
local function get_task_row(player, group_id, task_id)
    local task = Task_manager.get_task(task_id)

    -- If subtask 
    if task.parent_id  ~= nil then
        return get_task_row(player, group_id, task.parent_id)[constants.jolt.task_list.tasks_row_prefix .. task_id]
    else
        local pane = get_group_pane(player, group_id)
        if not pane or not pane.valid then return nil end

        return pane[constants.jolt.task_list.tasks_row_prefix .. task_id]
    end
end

--- Returns the root task
---@param player any
---@param task_id any
---@param group_id any
local function get_root_task(player, task_id, group_id)
    local task = Task_manager.get_task(task_id)

    if task.parent_id then
        return get_root_task(player, task.parent_id, group_id)
    else
        local pane = get_group_pane(player, group_id)

        return pane[constants.jolt.task_list.tasks_row_prefix .. task_id], task_id
    end
end

--- Refreshes the data for the provided task_id and all parent tasks
---@param player any - associated player
---@param task_id string - task to update
local function refresh_task_data(player, task_id)
    -- find the task
    local task = Task_manager.get_task(task_id)
    -- subtasks don't have group_id so fetch that 
    local group_id = task.group_id or Task_manager.get_parent_group(task.id)

    -- get the path to it in the gui 
    local task_row = get_task_row(player, group_id, task.id)
    local root_task_id = Task_manager.get_root_task_id(task.id)

    -- If subtask destroy and recreate the root task instead
    if task.parent_id then
        -- Get the root task of this subtask
        task_row = get_root_task(player, task.id, group_id)
    end

    if task_row ~= nil then
        -- Get the scroll bar parent
        local parent = task_row.parent

        -- Save its position to swap with later
        local position = task_row.get_index_in_parent()

        -- change the old name to prevent a name confict
        task_row.name = "temp"
        
        local selected_tasks = PlayerState.get_selected_tasks(player)

        -- Add the update root task so all subtasks data is refreshed
        local root_task_data = Task_manager.get_task(root_task_id)
        TaskListWindow.new_gui_task(parent, root_task_data, 0, selected_tasks, player)
        
        -- Swap new element into the old position
        parent.swap_children(position, #parent.children)
        
        -- Destroy the old one (now at the bottom after swap)
        parent.children[#parent.children].destroy()
    end

    -- Re-fetch the newly created row
    local root_task_row = get_task_row(player, group_id, root_task_id)

    -- If completed tasks are not shown remove it 
    -- and it it is not a subtask remove the root task
    if (not task.parent_id and not PlayerState.get_setting_show_completed(player)) and task.is_complete then
        if root_task_row ~= nil then
            -- If we are removing the last task, refresh the group 
            -- to get the empty task message
            if #root_task_row.parent.children == 1 then
                TaskListWindow.refresh_group(player, group_id)
            else -- otherwise just remove the task
                root_task_row.destroy()
            end
            
        end
    end
end

--- Refresh the data fully for the group
---@param player any
---@param group_id any
function TaskListWindow.refresh_group(player, group_id)

    local tab_content = get_group_pane(player, group_id)
    if tab_content then
        -- remove all children
        tab_content.clear()
    end

    -- Get tasks, checking if the control button "Show Completed".
    -- Get's only the tasks that match the state of that checkbox (complete/incomplete)
    local group_tasks = Task_manager.get_tasks(group_id, PlayerState.get_setting_show_completed(player))
    for _, task in pairs(group_tasks) do
        -- Check if task is selected 
        local selected_tasks = PlayerState.get_selected_tasks(player)
        local is_selected = PlayerState.is_task_selected(player, task.id)

        -- Display the task (see new_gui_task() for getting subtasks)
        local tab_in_ammount = 0
        local gui_task = TaskListWindow.new_gui_task(tab_content, task, tab_in_ammount, selected_tasks, player)
    end

    -- Add placeholder text if no tasks
    if #group_tasks == 0 then
        local placeholder = tab_content.add {
            type = "label",
            caption = {"jolt_task_list_window.no_tasks_info_text"}
        }
        placeholder.style.font_color = {r=0.6, g=0.6, b=0.6}
    end
end

--- Refresh when adding new tasks or subtasks
---@param player any
---@param task_id any
local function refresh_for_new_task(player, task_id)
    local task = Task_manager.get_task(task_id)

    -- For subtasks just refresh the root parents task data
    if task.parent_id then
        refresh_task_data(player, task_id)
    else
        -- Refresh the whole group pane
        TaskListWindow.refresh_group(player, task.group_id)
        
        -- Scroll to the new task
        local task_row = get_task_row(player, task.group_id, task_id)
        if task_row and task_row.parent then
            task_row.parent.scroll_to_element(task_row, "top-third")
        end
    end
end

--- Refreshes the controls for the window
---@param player any
local function refresh_window_controls(player)
    local window = player.gui.screen[constants.jolt.task_list.window]
    if not window or not window.valid then return end

    local content_frame = window.main_frame.content_frame

    TaskListWindow.add_controls(player, content_frame)
end

--- Refreshes data from the visual_action_log
---@param player any
local function refresh_from_visual_log(player)
    local current_index = PlayerState.get_last_visual_log_index(player)
    if VisualActionLog.is_new_action_since_index(current_index) then
        -- Get list of new updates to visually apply 
        local log_entries = VisualActionLog.get_entries_since_index(current_index)

        -- get actions enum 
        local actions = constants.jolt.actions
        for index, entry in ipairs(log_entries) do
            
            if entry.type == actions.updated_task_completed_status then
                refresh_task_data(player, entry.data.task_id)

            elseif entry.type == actions.updated_show_task_details_status then
                refresh_task_data(player, entry.data.task_id)

            elseif entry.type == actions.edited_task then
                refresh_task_data(player, entry.data.task_id)

            elseif entry.type == actions.added_task then
                refresh_for_new_task(player, entry.data.task_id)

            elseif entry.type == actions.selected_task then
                refresh_task_data(player, entry.data.task_id)
                

            end
        end
    end

    -- Update the tast visual log index for this player
    PlayerState.set_last_visual_log_index(player, VisualActionLog.get_latest_log_index())
end





--endregion Local_Refresh_Functions


--- Refreshes the window for the player
---@param player any - player associated
function TaskListWindow.refresh(player)
    -- Refresh the groups list and the current scroll pane
    refresh_current_group(player)

    -- Refresh controls (move down/up delete etc.)
    refresh_window_controls(player)

    -- Special refreshes depending on the action
    refresh_from_visual_log(player)
end

return TaskListWindow