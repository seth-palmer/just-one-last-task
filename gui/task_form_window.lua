---@diagnostic disable: undefined-field
-- If the "add to top" is selected in the new task window
local ADD_TO_TOP_CHECKBOX_DEFAULT_STATE = false
local TASK_LIST_WINDOW_WIDTH = 600
local SUBTITLE_MAX_WIDTH = TASK_LIST_WINDOW_WIDTH - 130

local DEFAULT_WINDOW_WIDTH = 400
local DEFAULT_WINDOW_HEIGHT = 550


-- Imports
local constants = require("constants")
local Gui = require("gui")
local TaskManager = require("scripts.task_manager")
local PlayerState = require("scripts.player_state")
local Utils = require("scripts.utils")


local TaskFormWindow = {}

function TaskFormWindow.create_form()
    
end

function TaskFormWindow.refresh_task_location_camera(player, new_coordinates, new_surface)
    local window = player.gui.screen[constants.jolt.new_task.window]
    if not window or not window.valid then return nil end

    local camera = Utils.find_element(window, constants.jolt.new_task.task_location_camera)

    -- local camera = window[constants.jolt.new_task.form_container].camera
    -- local new_position = PlayerState.get_temp_location_for_task(player)
    camera.position = new_coordinates
    camera.surface_index = new_surface
    camera.visible = true
end

--- Opens a new window with a form to create a new task/subtask 
--- or edit an existing one
function TaskFormWindow.open(player, task)

    -- If data in task is there, then this must be an edit
    local is_edit = task and task.task_id ~= nil
    local is_subtask = task.parent_id ~= nil
    
    local window_title = "New Task"
    local window_subtitle = nil
    
    if is_subtask then
        window_title = "New Subtask"
        local parent_title = Task_manager.get_task(task.parent_id).title
        window_subtitle = {"jolt_task_list_window.label_subtask_of", parent_title}
    end

    if is_edit then
        window_title = "Edit Task"
    end

    if is_edit and is_subtask then
        window_title = "Edit Subtask"
    end

    -- Setup the data if editing an existing task
    task = task or {}
    local title = task.title or ""
    local description = task.description or ""
    local task_id = task.task_id or ""
    local task_status = task.status or constants.jolt.default_task_status
    local checkbox_state_add_to_top = task.checkbox_add_to_top or ADD_TO_TOP_CHECKBOX_DEFAULT_STATE
    
    -- Get the current groups' id
    local current_group_id = PlayerState.get_current_group_id(player)
    
    -- Set group id to the param if provided or the last group selected if new task
    local group_id = task.group_id or current_group_id

    -- Setup options for the new window
    local options = {
        player = player,
        width = DEFAULT_WINDOW_WIDTH,
        height = DEFAULT_WINDOW_HEIGHT,
        window_title = window_title,
        window_name = constants.jolt.new_task.window,
        back_button_name = constants.jolt.new_task.back_button,
        confirm_button_name = constants.jolt.new_task.confirm_button,
        confirm_button_tooltip = {"jolt_new_task_window.add_task_confirm_button_tooltip"}
    }
    -- Change the tooltip if it is and edit task
    if is_edit then
        options.confirm_button_tooltip = {"jolt_new_task_window.edit_task_confirm_button_tooltip"}
    end

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

     -- Task status dropdown 
    local task_status_label = Gui.new_label(new_task_form, "Status:", player)
    local dropdown_status = new_task_form.add {
        type = "drop-down",
        name = constants.jolt.new_task.status_dropdown,
        items = constants.jolt.status_icon_list,
        selected_index = task_status,
        style = "dropdown",
    }

    local task_description_label = Gui.new_label(new_task_form, "Location:", player)

    -- Location buttons 
    local sbtn_location = new_task_form.add {
        type = "button",
        caption = "Set location",
        name = constants.jolt.new_task.set_location_button,
        -- sprite = constants.jolt.sprites.location,
        -- tooltip={"jolt.tooltip_view_location"},
        -- provide task id since the location will be updated in an event
        tags = {task_id = task_id},
    }
    sbtn_location.style.padding = 2
    -- sbtn_location.style.height = 32
    -- sbtn_location.style.width = 32

    local DEFAULT_CAMERA_ZOOM = 0.040

    local camera = new_task_form.add {
        type = "camera",
        name = constants.jolt.new_task.task_location_camera,
        position = task.coordinates or {1,1},
        -- set the default view to the player's current surface
        surface_index = task.surface_index or player.surface.index,
        zoom = DEFAULT_CAMERA_ZOOM,
        visible = task.coordinates ~= nil
    }
    camera.style.width = DEFAULT_WINDOW_WIDTH - 20
    camera.style.height = 150


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
    task_description_textbox.style.maximal_width = DEFAULT_WINDOW_WIDTH - 20

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
    local dropdown_status = form_container[constants.jolt.new_task.status_dropdown]
    
    -- Get Values
    local task_id = form_container.tags.task_id
    local title = textbox_title.text
    local description = textbox_description.text
    local add_to_top = checkbox_add_to_top.state
    local task_status = dropdown_status.selected_index

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

    -- Get location from the PlayerState
    local location = PlayerState.get_temp_location_for_task(player)

    -- Clear the saved location 
    PlayerState.save_temp_location_for_task(player, nil)
    
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
        coordinates = location and location.coordinates or nil,
        surface_index = location and location.surface_index or nil,
        status = task_status,
    }


    return task_params
end


function TaskFormWindow.clear_form(player)
    -- Go through element tree to get to the form_container
    local screen = player.gui.screen
    local window = screen[constants.jolt.new_task.window]
    local form_container = window[constants.jolt.new_task.form_container]

    -- Get form elements
    local textbox_title = form_container[constants.jolt.new_task.title_textbox]
    local textbox_description = form_container[constants.jolt.new_task.description_textbox]
    local checkbox_add_to_top = form_container[constants.jolt.new_task.add_to_top_checkbox]
    local dropdown_group = form_container[constants.jolt.new_task.group_dropdown]

    -- Clear title and desc Values
    local task_id = form_container.tags.task_id
    textbox_title.text = ""
    textbox_description.text = ""

    -- Leave the checkbox the same
    local add_to_top = checkbox_add_to_top.state
end

--- Closes the task form window
---@param player any
function TaskFormWindow.close(player)
    if player.gui.screen[constants.jolt.new_task.window] then
        player.gui.screen[constants.jolt.new_task.window].destroy()
    end
end

return TaskFormWindow