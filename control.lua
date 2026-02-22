--- control.lua

--- Imports
local TaskManager = require("scripts.task_manager")
local constants = require("constants")
local Gui = require("gui")
local Utils = require("scripts.utils")
local Outcome = require("scripts.outcome")

-- Window width and height constants
local TASK_LIST_MAX_WINDOW_HEIGHT = 600
local AUTO_SCALE_WINDOW_HEIGHT = 0
local TASK_LIST_WINDOW_WIDTH = 400
local GROUP_MANAGEMENT_WINDOW_WIDTH = 320
local GROUP_MANAGEMENT_WINDOW_HEIGHT = 480
local WARNING_WINDOW_WIDTH = 300
local WARNING_WINDOW_HEIGHT = 180

-- If the "add to top" is selected in the new task window
local ADD_TO_TOP_CHECKBOX_DEFAULT_STATE = false

--region =======Debug Functions=======

--- Print table information
---@param player any - player to enter this to the chat
---@param table table - the table to print
local function printTable(player, table)
    for key, value in pairs(table) do
        if type(value) == "table" then
            player.print(key .. ":")
            printTable(player, value)  -- Recursively print nested tables
        else
            player.print(key .. ": " .. tostring(value))
        end
    end
end

--- Function to print provided table
---@param event any
---@param message table - a string or table to display in chat
local function debug_print(event, message)
    local player = game.get_player(event.player_index)
    if type(message) == "table" then
        printTable(player, message)
    else
        player.print(message)
    end
end

--endregion =======Debug Functions=======

--region =======Local Functions=======
--- IMPORTANT put local functions before where they are used!!!

--- Closes the task list menu
local function close_task_list_menu(event)
    local player = game.get_player(event.player_index)
    player.gui.screen[constants.jolt.task_list.window].destroy()
end

--- Opens the group management window
---@param event any
local function open_group_management_window(event)
    local player = game.get_player(event.player_index)
    local title = {"jolt_group_management.window_title"}
    local window_name = constants.jolt.group_management.window_name
    local close_name = constants.jolt.group_management.close_button
    local window_width = GROUP_MANAGEMENT_WINDOW_WIDTH
    local window_height = GROUP_MANAGEMENT_WINDOW_HEIGHT
    local window = Gui.new_window(player, title, window_name, close_name, window_width, window_height)

    -- Add event to watch for button click to close the window
    Task_manager.bind_close_button(player, close_name, window_name)

    -- The selected group
    local selected_group = {title = "", icon="virtual/signal-question-mark"}

    local main_frame = window.add {
        type = "frame",
        direction="vertical",
        name=constants.jolt.group_management.main_frame,
        style = "slot_button_deep_frame",
    }
    main_frame.style.padding = 0
    main_frame.style.margin = 4
    main_frame.style.horizontal_align = "center"


    -- Controls frame
    local controls_frame = main_frame.add {
        type="frame",
        direction="horizontal",
        style = "subheader_frame"
    }
    controls_frame.style.minimal_height = 40
    controls_frame.style.margin = 4

    -- Empty space
    local empty_space = controls_frame.add {
        type = "empty-widget",
    }
    -- Make it expand to fill the space
    empty_space.style.minimal_width = 50
    empty_space.style.horizontally_stretchable = true

    -- Label for new group button 
    local add_new_group_text = {"jolt_group_management.add_new_group_text"}
    local add_group_label = Gui.new_label(controls_frame, add_new_group_text, player)

    -- Add new group button
    local add_group_button = controls_frame.add{
        type="sprite-button",
        style = "confirm_button",
        sprite=constants.jolt.sprites.plus_folder,
        name=constants.jolt.group_management.add_new_group_icon_button,
        tooltip = {"jolt_group_management.tooltip_add_group"}
    }
    add_group_button.style.width = 75
    add_group_button.style.height = 30

    -- Display icon for each group
    local button_frame = main_frame.add{
        type="frame",
        direction="horizontal",
        style="jolt_deep_frame"
    }
    button_frame.style.margin = 0

    local max_col_count = 7
    local button_table = button_frame.add{
        type="table",
        name="button_table",
        column_count=max_col_count,
        style="filter_slot_table"
    }
    
    -- Get group order
    local group_order = Task_manager.get_group_order()

    -- Add each group
    for index, value in ipairs(group_order) do
        -- Get the group from its id
        -- Example: local nauvis_group = {id=1, name="Nauvis", icon="space-location/nauvis"}
        local group = Task_manager.get_group(value)

        local icon_button = button_table.add{
            type="sprite-button",
            sprite=group.icon,
            style="slot_button",
            -- Add tags since can't use the same name for each
            -- but can check tag for group_mgnmt_btn and then get group_id
            tags = {is_jolt = true, is_group_management_icon_button=true, group_id=group.id}
        }
        -- If this button is selected change its style to 
        -- be yellow button background
        local selected_group_id = Task_manager.get_group_management_selected_group_id(player)
        if group.id == selected_group_id then
            icon_button.style = constants.styles.buttons.yellow
            selected_group = group
        end
    end


    -- Disable all buttons 
    local default_btn_state = selected_group.id ~= nil

    local form_bg_frame = main_frame.add {
        type = "frame",
        style = "inside_shallow_frame",
        name=constants.jolt.group_management.form_frame,
    }

    -- Edit form in the bottom half of the window
    local form_table = form_bg_frame.add{
        type="table",
        column_count=2,
        name=constants.jolt.group_management.form_container,
        style="table"
    }
    form_table.style.padding = 10
    
    -- Label "Title" and textbox input
    local label = form_table.add {type = "label", caption = "Title:"}
    local task_title_textbox = form_table.add {
        type = "textfield",
        name = constants.jolt.group_management.task_title_textbox,
        text = selected_group.name,
        style = constants.styles.form.textfield,
        enabled = default_btn_state,
    }
    -- Focus the textbox for faster edits
    task_title_textbox.focus()

    -- Icon label for group
    local label = form_table.add {type = "label", caption = "Icon:"}

    -- Show icon from group selected
    local icon_button = form_table.add{
        type = "choose-elem-button", -- let user choose group
        name = constants.jolt.group_management.change_group_icon_button,
        elem_type = "signal",  -- or "fluid", "recipe", "technology", "entity", etc.
        enabled = default_btn_state,
    }
    -- Split up path e.g. "space-location/nauvis" for elem_value
    local slash_pos = string.find(selected_group.icon, "/")
    local icon_type = string.sub(selected_group.icon, 0, slash_pos -1)
    local icon_name = string.sub(selected_group.icon, slash_pos+1, -1)

    -- Translate back for edge case where it uses 'virtual'
    -- in a choose elem btn, but 'virtual-signal' in a sprite
    if icon_type == "virtual-signal" then icon_type = "virtual" end

    -- MUST set elem_value after icon button
    -- (can't set property inside of it)
    icon_button.elem_value = {type = icon_type, name = icon_name}

    -- Position buttons - to change selected group position
    form_table.add {type = "label", caption = "Position:"}
    form_table.add {type = "label", caption = ""} -- skip this row

    -- Move group left button
    form_table.add {
        type = "sprite-button",
        sprite = constants.jolt.sprites.left,
        name = constants.jolt.group_management.move_group_left,
        tooltip = {"jolt_group_management.tooltip_move_group_left"},
        enabled = default_btn_state,
    }

    -- Move group right button
    form_table.add {
        type = "sprite-button",
        sprite = constants.jolt.sprites.right,
        name = constants.jolt.group_management.move_group_right,
        tooltip = {"jolt_group_management.tooltip_move_group_right"},
        enabled = default_btn_state,
    }

    -- A line to separate the controls
    local separator = window.add{
        type = "line",
        direction = "horizontal"
    }

    -- Add row for controls 
    local controls_container = window.add {
        type = "flow",
        direction = "horizontal",
    }
    controls_container.style.top_padding = 4
    controls_container.style.left_padding = 3
    controls_container.style.right_padding = 3

    -- Delete group button
    local btn_delete_group = controls_container.add {
        type = "sprite-button",
        name = constants.jolt.group_management.delete_group,
        style = constants.styles.buttons.red,
        sprite = constants.jolt.sprites.delete,
        tooltip = {"jolt_group_management.tooltip_delete_group"},
        enabled = default_btn_state,
    }

    -- Empty space
    local empty_space = controls_container.add {
        type = "empty-widget",
    }
    -- Make it expand to fill the space
    empty_space.style.minimal_width = 50
    empty_space.style.height = 24
    empty_space.style.horizontally_stretchable = true

    -- Save button
    local btn_save_group = controls_container.add {
        type = "button",
        caption = "Save",
        tooltip = {"jolt_group_management.tooltip_save"},
        enabled = default_btn_state,
        name = constants.jolt.group_management.btn_save_group
    }
end



--- Opens a new window with a form to create a new task/subtask 
--- or edit an existing one
local function open_task_form_window(event, window_title, window_subtitle, task)

    -- If data in task is there, then this must be an edit
    local is_edit = not task == nil
    local is_subtask = task.parent_id ~= nil

    -- get player by index
    local player = game.get_player(event.player_index)

    -- Setup the data if editing an existing task
    task = task or {}
    local title = task.title or ""
    local description = task.description or ""
    local task_id = task.task_id or ""
    local checkbox_state_add_to_top = task.checkbox_add_to_top or ADD_TO_TOP_CHECKBOX_DEFAULT_STATE
    
    -- Get the current groups' id
    local current_group_id = Task_manager.get_current_group_id(player)
    
    -- Set group id to the param if provided or the last group selected if new task
    local group_id = task.group_id or current_group_id

    -- Setup options for the new window
    local options = {
        player = player,
        window_title = window_title,
        window_name = constants.jolt.new_task.window,
        back_button_name = constants.jolt.new_task.back_button,
        confirm_button_name = constants.jolt.new_task.confirm_button
    }

    -- Make the new window and set close button
    local new_task_window = Gui.new_dialog_window(options)
    
    -- Add event to watch for button click to close the window
    Task_manager.bind_close_button(player, options.back_button_name, options.window_name)

    -- Only add the label line if needed
    -- need brackets because 'not' operator is applied first 
    local need_label = not (window_subtitle == nil)

    -- only add a subtitle if it is needed (like for subtasks)
    if need_label then
        -- Add subtitle line 
        local controls_container = new_task_window.add {
            type = "frame",
            name = "jolt_controls_container",
            direction = "horizontal",
            style = "subheader_frame",
            index = 2, -- Must set to 2 to place above the bottom row
        }

        -- subtitle 
        local lbl_subtitle = controls_container.add {
            type = "label",
            caption = window_subtitle,
            horizontally_stretchable = "on"
        }

        -- Empty space
        local empty_space = controls_container.add {
            type = "empty-widget",
        }
        -- Make it expand to fill the space
        empty_space.style.minimal_width = 50
        empty_space.style.height = 24
        empty_space.style.horizontally_stretchable = true
    end
    
    -- Calculate the position of the form if the subtitle was added or not
    local form_pos = 2
    if need_label then form_pos = form_pos + 1 end

    -- Container to hold form inputs
    local new_task_form = new_task_window.add {
        type = "flow",
        name = constants.jolt.new_task.form_container,
        direction = "vertical",
        index = form_pos, -- Must set to 2 to place above the bottom row
        tags = {is_jolt = true, task_id = task_id, parent_id = task.parent_id } -- Store task id if this is an edit task 
    }
    -- Space out the elements (must use flow not frame)
    new_task_form.style.vertical_spacing = 4
    
    -- Label "Title" and textbox input
    local task_title_label = Gui.new_label(new_task_form, "Title", player)
    -- TODO: in future add button to add icon to task title
    -- local task_title_flow = new_task_form.add {
    --     type = "flow",
    --     direction = "horizontal",
    -- }
    -- task_title_flow.style.vertical_align = "center"
    -- task_title_flow.style.horizontal_spacing = 0
    -- local task_title_choose_icon_button = new_task_form.add {
    --     type = "choose-elem-button",
    --     name = "",
    --     elem_type = "signal",
    -- }

    -- textbox for the task title
    local task_title_textbox = new_task_form.add {
        type = "textfield",
        name = constants.jolt.new_task.title_textbox,
        text = title,
        style = constants.styles.form.textfield
    }
    task_title_textbox.style.horizontally_stretchable = true
    task_title_textbox.style.maximal_width = 300

    -- Focus the textfield so the player can type immediately
    task_title_textbox.focus()

    -- Checkbox for "Add to top"
    local checkbox_add_to_top = new_task_form.add {
        type = "checkbox",
        name = constants.jolt.new_task.add_to_top_checkbox,
        caption = {"jolt_new_task_window.add_to_top_checkbox_desc"},
        state = checkbox_state_add_to_top,
    }

    -- Get position
    local position = Task_manager.get_group_position(group_id)
    

    -- Dropdown to select which group the task is added to
    local dropdown_select_group = new_task_form.add {
        type = "drop-down",
        name = constants.jolt.new_task.group_dropdown,
        caption = "Group",
        items = Task_manager.get_group_names(),
        style = "dropdown",
        selected_index = position,
        enabled = not is_subtask,
    }

    -- Task description
    -- https://lua-api.factorio.com/latest/concepts/GuiElementType.html
    local task_description_label = Gui.new_label(new_task_form, "Description", player)
    local task_description_textbox = new_task_form.add {
        type = "text-box", -- A multiline textfield
        name = constants.jolt.new_task.description_textbox,
        text = description,
        style = constants.styles.form.textfield,
        
    }
    task_description_textbox.style.horizontally_stretchable = true
    task_description_textbox.style.vertically_stretchable = true
    task_description_textbox.word_wrap = true
    task_description_textbox.style.maximal_width = 340

end



--- Open the task list menu
local function open_task_list_menu(event)
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

    -- Get tasks, checking if the control button "Show Completed".
    -- Get's only the tasks that match the state of that checkbox (complete/incomplete)
    local group_tasks = Task_manager.get_tasks(current_group_id, Task_manager.get_setting_show_completed(player))
    for _, task in pairs(group_tasks) do
        -- Check if task is selected 
        local selected_tasks = Task_manager.get_selected_tasks(player)
        local is_selected = Task_manager.is_task_selected(player, task.id)

        -- Display the task (see new_gui_task() for getting subtasks)
        local tab_in_ammount = 0
        local gui_task = Gui.new_gui_task(tab_content, task, tab_in_ammount, selected_tasks, player)
        
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


--- Tries to add a new task checking the data in the new task window
---@param event any
local function add_new_task(event)
    -- Go through element tree to get to the form_container
    local player = game.get_player(event.player_index)
    local screen = player.gui.screen
    local window = screen[constants.jolt.new_task.window]
    local form_container = window[constants.jolt.new_task.form_container]

    -- Get form elements
    local textbox_title = form_container[constants.jolt.new_task.title_textbox]
    local textbox_description = form_container[constants.jolt.new_task.description_textbox]
    local checkbox_add_to_top = form_container[constants.jolt.new_task.add_to_top_checkbox]
    local dropdown_group = form_container[constants.jolt.new_task.group_dropdown]

    -- Get Values
    local task_id = form_container.tags.task_id
    local title = textbox_title.text
    local description = textbox_description.text
    local add_to_top = checkbox_add_to_top.state

    -- If it has a parent_id then it is a subtask
    local is_subtask = form_container.tags.parent_id
    local group_id

    -- If a regular task get the group id
    if not is_subtask then
        -- Get the selected index in the dropdown
        local group_index = dropdown_group.selected_index
        -- Get the actual group id
        group_id = Task_manager.get_group_order()[group_index]
    
    else -- otherwise set the group_id to nil
        group_id = nil
    end

    
    -- check if empty string not nil since task_id is string type
    -- check type with debug_print(event, "type is: " .. type(task_id))
    local is_edit_task = task_id ~= ""
    
    -- Make task parameters
    local task_params = {
        title = title,
        description = description,
        group_id = group_id,
        parent_id = form_container.tags.parent_id or nil
    }

    -- If no title display error and do not close window
    if title == "" then
        -- Create "flying text" with error message
        player.create_local_flying_text {
            text = {"jolt_new_task_window.no_title_error_message"},
            create_at_cursor=true,
        }

    else -- If valid data add task
        if is_edit_task then -- if it has id, update task
            Task_manager.update_task(task_params, task_id)
        else -- otherwise add new task
            Task_manager.add_task(task_params, add_to_top)
        end

        -- Close task form window
        player.gui.screen[constants.jolt.new_task.window].destroy()

        -- Refresh data
        open_task_list_menu(event)
    end
end

--- Initialize data for the player
---@param player_index any - player index to initialize
local function initialize_player(player_index)
    local player = game.get_player(player_index)

    -- Initialize the player's data table
    if not storage.players[player.index] then
        storage.players[player.index] = {}
    end

    -- Initialize jolt specific data under a jolt key
    storage.players[player.index].jolt = {
        ui = {
            selected_tasks = {},
            selected_group_tab_id = Task_manager.get_group_order()[1],
            saved_window_locations = {},
            close_button_registry = {},
            is_task_list_pinned_open = false,
            selected_group_icon_id = nil,
            last_interacted_task_id = nil,
            show_completed_tasks = false,
        },
        
    }
end
--endregion =======Local Functions=======


local function initialize_storage()
    
end

-- Make sure the intro cinematic of freeplay doesn't play every time we restart
-- This is just for convinience, don't worry if you don't understand how this works
-- See on_init() section in https://wiki.factorio.com/Tutorial:Scripting
-- Only runs when a new game is created https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_init
script.on_init(function()
    -- TODO comment out before release
    -- local freeplay = remote.interfaces["freeplay"]
    -- if freeplay then -- Disable freeplay popup-message
    --     if freeplay["set_skip_intro"] then
    --         remote.call("freeplay", "set_skip_intro", true)
    --     end
    --     if freeplay["set_disable_crashsite"] then
    --         remote.call("freeplay", "set_disable_crashsite", true)
    --     end
    -- end

    -- Setup default group(s) (store data! not objects/functions)
    -- AVOID using space age specific icons as it will crash in the base game
    local nauvis_group = {id="a1", name="Nauvis", icon="space-location/nauvis"}
    local default_group_data = {}
    default_group_data[nauvis_group.id] = nauvis_group
    local default_group_order = {"a1"}


    -- store data for groups, tasks 
    -- IMPORTANT: Can only store data not functions. So no putting an object here
    -- https://lua-api.factorio.com/latest/auxiliary/storage.html
    storage.jolt = storage.jolt or {
        tasks = {},
        groups = default_group_data,
        priorities = {},
        group_order = default_group_order,
    }

    -- store players and their info
    storage.players = storage.players or {}

    -- setup the task manager 
    Task_manager = TaskManager.new()
end)




--- Runs when mod configuration changes (adding a mod or updating a mod)
--- https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_configuration_changed
---@param event any
script.on_configuration_changed(function(event)
    -- Migrate old data structure to new one
    if storage.task_data and not storage.jolt then
        log("jolt: migrating old data structure")
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
                        }
                    }
                    -- Clean up old keys
                    p.selected_tasks = nil
                    p.selected_group_tab_id = nil
                    p.settings = nil
                end
            else
                initialize_player(player.index)
            end
        end
    end
end)

--- Called when a new player is created
--- Initialize all needed data and set defaults
--- https://lua-api.factorio.com/latest/events.html#on_player_created
script.on_event(defines.events.on_player_created, function(event)
    -- Initialize data for the player
    initialize_player(event.player_index)

end)

-- Runs when a saved game is loaded
-- https://lua-api.factorio.com/latest/classes/LuaBootstrap.html#on_load
script.on_load(function ()
    -- Since on_init() only runs for new games re-declare it here 
    -- so we can use it for saved games
    Task_manager = TaskManager.new()
    -- Note: TaskManager.new() loads in the save data itself
end)

--- Watch for clicks on the task shortcut icon to open and close
--- the task list window
script.on_event(defines.events.on_lua_shortcut, function(event)
    -- Only react for the jolt shortcut button
    if event.prototype_name == constants.jolt.shortcuts.open_task_list_window then
        local player = game.get_player(event.player_index)

        -- If the window is already open close it
        if player.gui.screen[constants.jolt.task_list.window] then
            close_task_list_menu(event)
        else -- otherwise open the task list window
            open_task_list_menu(event)
        end
    end
end) -- end on_lua_shortcut


--- Called when a LuaGuiElement is confirmed, for example by pressing 
--- Enter in a textfield.
--- https://lua-api.factorio.com/latest/events.html#on_gui_confirmed
script.on_event(defines.events.on_gui_confirmed, function(event)
    -- Exit if invalid
    local element = event.element
    if not element or not element.valid then return end
    local element_name = event.element.name

    -- Early exit: ignore elements that don't belong to the jolt mod
    if not element_name or not element_name:find("^jolt") then
        --TIP: uncomment below to debug naming issues
        -- debug_print(event, "elementName = " .. element_name)
        return
    end

    -- Add a new task when pressing [Enter] in the title textbox
    if element_name == constants.jolt.new_task.title_textbox then
        add_new_task(event)
    end
end)

--- Watch for clicks on any of the jolt mod gui elements
script.on_event(defines.events.on_gui_click, function(event)
    -- Exit if invalid
    local element = event.element
    if not element or not element.valid then return end

    local element_name = event.element.name

    --[[
    IMPORTANT: for a gui element to be detected it must either have an 
                element name with the prefix "jolt" 
                
                OR have the tag "is_jolt = true"

        Example: 

        local icon_button = button_table.add{
            type="sprite-button",
            sprite=group.icon,
            style="slot_button",
            -- Add tags since can't use the same name for each
            -- but can check tag for group_mgnmt_btn and then get group_id
            tags = {is_jolt = true, is_group_management_icon_button=true, group_id=group.id}
        }
    ]]--

    -- Early exit: ignore elements that don't belong to me
    if event.element.tags and event.element.tags.is_jolt or element_name:find("^jolt") then
        --TIP: uncomment below to debug naming issues
        -- is our gui element so continue
    else
        -- debug_print(event, "tags is jolt = " )
        -- debug_print(event, event.element.tags.is_jolt)
        return
    end

    -- Get the player that is interacting with our gui
    local player = game.get_player(event.player_index)

    -- Save last interacted with task (to be able to scroll to it later)
    -- in separate "if" statement so it doesn't block other interactions
    if event.element.tags.task_id then
        -- save task id
        Task_manager.save_last_interacted_task_id(player, event.element.tags.task_id)
    end

    -- Check if element is a close button for one of jolt's windows
    local window_name = Task_manager.pop_close_button(player, element_name)

    -- If it is then attempt to close the window
    if window_name ~= nil then
        -- Check if the frame still exists before destroying
        if player.gui.screen[window_name] and player.gui.screen[window_name].valid then
            player.gui.screen[window_name].destroy()
        end

        -- When closing group management, clear the selected group 
        -- (so the window opens with nothing selected)
        if window_name == constants.jolt.group_management.window_name then
            Task_manager.clear_group_management_selected_group_id(player)
        end

        -- clear selected tasks
        Task_manager.clear_selected_tasks(player)

    -- Keep open button is pressed
    elseif element_name == constants.jolt.task_list.keep_window_open_button then

        -- toggle the keep open state
        Task_manager.toggle_task_list_pinned_open(player)

        -- Refresh window 
        open_task_list_menu(event)

    -- Open new task window when Add task button clicked
    elseif element_name == constants.jolt.task_list.add_task_button then
        -- clear selected tasks
        Task_manager.clear_selected_tasks(player)

        -- Refresh list of tasks
        open_task_list_menu(event)

        -- open window to add a new task
        open_task_form_window(event, "New Task", nil, {})

    -- Move selected task(s) up
    elseif element_name == constants.jolt.task_list.move_task_up_button then

        -- Move the selected tasks
        Task_manager.move_selected_tasks(player, Direction.Up)

        -- Refresh list of tasks
        open_task_list_menu(event)

    -- Move selected task(s) down
    elseif element_name == constants.jolt.task_list.move_task_down_button then
        
        -- Move the selected tasks
        Task_manager.move_selected_tasks(player, Direction.Down)

        -- Refresh list of tasks
        open_task_list_menu(event)

    -- Move selected task(s) down
    elseif element_name == constants.jolt.task_list.delete_tasks_button then

        -- Delete the selected tasks (also clears the selected tasks)
        Task_manager.delete_selected_tasks(player)

        -- Refresh list of tasks
        open_task_list_menu(event)

    -- Add a new task confirm button clicked
    elseif element_name == constants.jolt.new_task.confirm_button then
        add_new_task(event)

    -- If confirm button for edit task was clicked edit the task 
    elseif element_name == constants.jolt.edit_task.confirm_button then
        add_new_task(event)

    -- Edit task when edit button clicked 
    elseif element_name == constants.jolt.task_list.edit_task_button then
        -- Get the stored task id from tags 
        local task_id = event.element.tags.task_id

        -- Get the task 
        local task = Task_manager.get_task(task_id)

        -- Open the new task window with pre-filled data 
        -- IMPORTANT: need to use params or their is bug that a new task will be 
        -- created when editing a task.
        local params = {
            title = task.title,
            group_id = task.group_id,
            description = task.description,
            task_id = task_id,
            parent_id = task.parent_id,
        }
        open_task_form_window(event, "Edit Task", nil, params)

    -- Task checkbox clicked to select or mark complete / uncomplete 
    elseif element_name == constants.jolt.task_list.task_checkbox then
        -- Get the stored task id from tags 
        local task_id = event.element.tags.task_id

        -- check for ctrl+click 
        if event.control then
            -- Add selected task to list
            -- Note: (non sibling tasks will not be added)
            local outcome = Task_manager.add_selected_task(player, task_id)

            -- Check if it did not succeed
            if not outcome.success then
                -- Display error message
                Utils.display_error(player, outcome.message)
            end

            -- Refresh list of tasks
            open_task_list_menu(event)
        
        else -- Otherwise mark mark complete / uncomplete 
            -- clear selected tasks 
            Task_manager.clear_selected_tasks(player)

            -- Get the task 
            local task = Task_manager.get_task(task_id)

            -- Invert completed status 
            task.is_complete = not task.is_complete

            -- Refresh list of tasks (Is this inefficient?)
            open_task_list_menu(event)
        end

    -- Toggle viewing completed/incomplete tasks 
    elseif element_name == constants.jolt.task_list.show_completed_checkbox then
        -- Invert the setting stored in task manager 
        local show_completed = Task_manager.get_setting_show_completed(player)
        Task_manager.set_setting_show_completed(player, not show_completed)

        -- Refresh list of tasks
        open_task_list_menu(event)

    -- Toggle details for individual task
    elseif element_name == constants.jolt.task_list.toggle_details_button then
        -- Get the task 
        local task_id = event.element.tags.task_id
        local task = Task_manager.get_task(task_id)

        -- invert property to mark that details should be shown/hidden
        task.show_details = not task.show_details

        -- Refresh list of tasks
        open_task_list_menu(event)
    
    -- On click of the "+ Subtask" button 
    elseif element_name == constants.jolt.task_list.add_subtask_button then
        -- Get the task 
        local task_id = event.element.tags.task_id
        local task = Task_manager.get_task(task_id)

        -- Open the add task window
        local subtitle = "Subtask of " .. task.title
        local subtask = {}
        subtask.parent_id = task.id
        open_task_form_window(event, "New Subtask", subtitle, subtask)

    -- If selected an tab group icon button change the tasks
    elseif event.element.tags.is_group_change_button then
        -- Save selected group id
        local selected_group_id = event.element.tags.group_id
        Task_manager.set_current_group_id(player, selected_group_id)

        -- Clear selected tasks 
        Task_manager.clear_selected_tasks(player)

        -- Refresh list of tasks
        open_task_list_menu(event)

    -- Group Management button
    elseif element_name == constants.jolt.group_management.open_window_button then
        -- If the window is already open close it
        if player.gui.screen[constants.jolt.group_management.window_name] then
            -- clear the selected group 
            Task_manager.clear_group_management_selected_group_id(player)

            -- close the window
            player.gui.screen[constants.jolt.group_management.window_name].destroy()
        else -- otherwise open the group management window
            open_group_management_window(event)
        end
        

    -- Group Management button 
    elseif element_name == constants.jolt.group_management.add_new_group_icon_button then
        -- Add group with template data and open window
        -- !! Use "virtual-signal" and not "virtual" for sprites
        local group = {name="", icon="virtual-signal/signal-question-mark"}
        local new_group_id = Task_manager.add_group(group)

        -- If new group id is nil then display an error 
        if not new_group_id then
            local max_groups_error_message =  {"jolt_group_management.error_max_groups_reached"}
            Utils.display_error(player, max_groups_error_message)
        else
            -- Make it the currently selected group
            Task_manager.set_group_management_selected_group_id(player, new_group_id)

            -- Refresh windows
            open_task_list_menu(event)
            open_group_management_window(event)
        end


    -- Delete selected group
    elseif element_name ==  constants.jolt.group_management.delete_group then
        -- Get group id
        local group_id = Task_manager.get_group_management_selected_group_id(player)

        -- If tasks in group show warning
        local task_count = Task_manager.count_tasks_for_group(group_id)

        -- If group has tasks in it, show warning
        if task_count > 0 then
            -- Make the new window and set close button
            -- Setup options for the new window
            local options = {
                width = WARNING_WINDOW_WIDTH,
                height = WARNING_WINDOW_HEIGHT,
                player = player,
                window_name = constants.jolt.delete_group.window_name,
                window_title = {"jolt_group_management.confirm_delete_window_title"},
                back_button_name = constants.jolt.delete_group.back_button,
                confirm_button_name = constants.jolt.delete_group.confirm_button
            }
            -- Open new confirmation dialog window
            local confirm_delete_window = Gui.new_dialog_window(options)

            -- Add event to watch for button click to close the window
            Task_manager.bind_close_button(player, options.back_button_name, options.window_name)

            -- Confirm delete button
            local confirm_delete_frame = confirm_delete_window.add {
                type = "frame",
                direction = "vertical",
                index = 2,
                style = "jolt_content_frame"
            }

            -- Get from en.cfg for translation reasons
            local message = {"jolt_group_management.confirm_delete_group_warning_message", task_count, task_count > 1}

            -- Label to hold warning message
            local confirm_delete_label = Gui.new_label(confirm_delete_frame, message, player)

            -- Force onto multiple lines
            confirm_delete_label.style.single_line = false
        else -- If group has no tasks delete it without a warning
        
            -- Delete group
            local is_deleted = Task_manager.delete_group(group_id)

            -- Display error if it fails and returns false
            if not is_deleted then
                local min_groups_error_message = {"jolt_group_management.error_min_groups_reached"}
                Utils.display_error(player, min_groups_error_message)
            end

            -- Refresh windows
            open_task_list_menu(event)
            open_group_management_window(event)
        end

    -- Confirm deleted group button
    elseif element_name ==  constants.jolt.delete_group.confirm_button then
        -- Get group id
        local group_id = Task_manager.get_group_management_selected_group_id(player)

        -- Delete group
        local is_deleted = Task_manager.delete_group(group_id)

        -- Display error if it fails and returns false
        if not is_deleted then
            local min_groups_error_message = {"jolt_group_management.error_min_groups_reached"}
            Utils.display_error(player, min_groups_error_message)
        end

        -- Refresh windows
        open_task_list_menu(event)
        open_group_management_window(event)

        -- Close confirmation window
        player.gui.screen[constants.jolt.delete_group.window_name].destroy()

    -- If selected an group icon button in the group management window
    elseif event.element.tags.is_group_management_icon_button then
        -- Save new selected group id 
        local selected_group_id = event.element.tags.group_id
        Task_manager.set_group_management_selected_group_id(player, selected_group_id)

        -- Refresh windows
        open_task_list_menu(event)
        open_group_management_window(event)

    -- Move group left button
    elseif element_name == constants.jolt.group_management.move_group_left then
        -- Get current selected group
        local group_id = Task_manager.get_group_management_selected_group_id(player)

        -- save group changes to prevent them being lost
        Task_manager.save_current_group(player)

        -- Swap with the previous
        Task_manager.move_group_left(group_id)

        -- Refresh windows
        open_task_list_menu(event)
        open_group_management_window(event)

    -- Move group right button
    elseif element_name == constants.jolt.group_management.move_group_right then
        -- Get current selected group
        local group_id = Task_manager.get_group_management_selected_group_id(player)

        -- save group changes to prevent them being lost
        Task_manager.save_current_group(player)

        -- Swap with the next
        Task_manager.move_group_right(group_id)

        -- Refresh windows
        open_task_list_menu(event)
        open_group_management_window(event)

    -- Save group button 
    elseif element_name == constants.jolt.group_management.btn_save_group then
        
        -- Go through element tree to get to the form_container
        local player = game.get_player(event.player_index)

        Task_manager.save_current_group(player)
        

        -- Refresh windows
        open_task_list_menu(event)
        open_group_management_window(event)
    end
end)


--- Called when a window is moved
--- save locations to make window locations persistent
script.on_event(defines.events.on_gui_location_changed, function(event)
    -- Get player
    local player = game.get_player(event.player_index)

    -- Get new location
    local new_location = event.element.location
    
    -- Save new location to storage
    -- storage.players[event.player_index].saved_window_locations[event.element.name] = new_location
    Task_manager.save_window_location(player, event.element.name, new_location)
end)

--- Called when the player closes the GUI they have open.
--- can set player.opened = window_name_open 
--- this will then close the window when 'e' is pressed
--- https://lua-api.factorio.com/latest/events.html#on_gui_closed
---@param event any
script.on_event(defines.events.on_gui_closed, function(event)
    if not event.element then return end
    local player = game.get_player(event.player_index)
    local window_name = event.element.name

    -- Do not continue if it is not a window from JOLT
    if not Task_manager.is_jolt_window(window_name) then return end

    -- Don't close if task_list window and it is pinned open 
    if window_name == constants.jolt.task_list.window and Task_manager.is_task_list_pinned_open(player) then
        return
    end

    -- Close the window
    if event.element.valid then event.element.destroy() end
    
    -- Can run run cleanup specific to that window (see also section in on_gui_click)
    if window_name == constants.jolt.group_management.window_name then
    end
    if window_name == constants.jolt.task_list.window_name then
        Task_manager.clear_selected_tasks(player)
    end
end)

--[[
script.on_event(defines.events.on_gui_closed, function(event)
    debug_print(event, "closing with e")
    -- Exit if invalid
    local element = event.element
    if not element or not element.valid then return end
    local element_name = event.element.name


    -- Early exit: ignore elements that don't belong to me
    if element_name:find("^jolt") then
        --TIP: uncomment below to debug naming issues
        -- is our gui element so continue
    else
        -- debug_print(event, "tags is jolt = " )
        debug_print(event, event.element.name)
        return
    end

    -- Get the player that is interacting with our gui
    local player = game.get_player(event.player_index)


    -- Check if element is a close button for one of jolt's windows
    local window_name = Task_manager.pop_close_button(player, element_name)
    debug_print(event, window_name)
    debug_print(event, element_name)
    window_name = element_name

    -- If it is then attempt to close the window
    if window_name ~= nil then
        -- Check if the frame still exists before destroying
        if player.gui.screen[window_name] and player.gui.screen[window_name].valid then
            player.gui.screen[window_name].destroy()
        end

        -- When closing group management, clear the selected group 
        -- (so the window opens with nothing selected)
        if window_name == constants.jolt.group_management.window_name then
            Task_manager.clear_group_management_selected_group_id(player)
        end

        -- clear selected tasks
        Task_manager.clear_selected_tasks(player)
    end
end)
]]--
