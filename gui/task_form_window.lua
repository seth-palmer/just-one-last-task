-- If the "add to top" is selected in the new task window
local ADD_TO_TOP_CHECKBOX_DEFAULT_STATE = false

-- Imports
local constants = require("constants")
local Gui = require("gui")
local TaskManager = require("scripts.task_manager")
local PlayerState = require("scripts.player_state")


local TaskFormWindow = {}

--- Opens a new window with a form to create a new task/subtask 
--- or edit an existing one
function TaskFormWindow.open(event, window_title, window_subtitle, task)

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
    local current_group_id = PlayerState.get_current_group_id(player)
    
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
    PlayerState.bind_close_button(player, options.back_button_name, options.window_name)

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
            style = "control_settings_section_frame",
            -- style = "repeated_subheader_frame",
            -- style = "no_header_filler_frame",
            index = 2, -- Must set to 2 to place above the bottom row
        }
        controls_container.style.padding = 4
        controls_container.style.top_margin = 4
        controls_container.style.bottom_margin = 4

        -- subtitle 
        local lbl_subtitle = controls_container.add {
            type = "label",
            -- Add the icon this way to prevent a crash with not being able to concat tables
            caption = {"", "[img=" .. constants.jolt.sprites.subtasks .. "] ", window_subtitle},
            horizontally_stretchable = "on",
        }
        -- Limit the maximum width to prevent overflow for long task names
        lbl_subtitle.style.maximal_width = SUBTITLE_MAX_WIDTH
        lbl_subtitle.style.font = "default-bold"

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

    -- textbox for the task title
    local task_title_textbox = new_task_form.add {
        type = "textfield",
        name = constants.jolt.new_task.title_textbox,
        text = title,
        style = constants.styles.form.textfield,
        icon_selector = true, -- add an icon selector to insert icons
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
        icon_selector = true, -- add an icon selector to insert icons
    }
    task_description_textbox.style.horizontally_stretchable = true
    task_description_textbox.style.vertically_stretchable = true
    task_description_textbox.word_wrap = true
    task_description_textbox.style.maximal_width = 340

end

--- Returns the data in the form for the provided player
---@param player any - player associated
function TaskFormWindow.get_form_data(player)
    -- Go through element tree to get to the form_container
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
        id = task_id,
        is_edit_task = is_edit_task,
        is_subtask = is_subtask,
        title = title,
        description = description,
        group_id = group_id,
        parent_id = form_container.tags.parent_id or nil,
        add_to_top = add_to_top,
    }
    return task_params
end

--- Closes the task form window
---@param player any
function TaskFormWindow.close(player)
    if player.gui.screen[constants.jolt.new_task.window] then
        player.gui.screen[constants.jolt.new_task.window].destroy()
    end
end

return TaskFormWindow