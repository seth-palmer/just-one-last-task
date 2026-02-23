--- gui.lua
--- A file to store premade graphical elements
local constants = require("constants")

local Gui = {}

--- Makes a new window for the player
function Gui.new_window(player, window_title, window_name, close_button_name, width, height)
    local drag_bar_height = 24
    local close_button_size = 24
    
    local screen_element = player.gui.screen

    -- Check if window already exists and destroy it
    if player.gui.screen[window_name] then
        player.gui.screen[window_name].destroy()
    end

    local window = screen_element.add {
        type = "frame",
        name = window_name,
        direction = "vertical",
    }
    window.style.size = {width, height}

    -- Set window to close when 'e' is pressed or other window opened
    player.opened = window
    

    -- Move the window to the saved location if it exists 
    local saved_location = Task_manager.get_saved_window_position(player, window_name)
    if saved_location then
        window.location = saved_location

    -- Otherwise center it in the screen
    else
        -- center the window in the screen (not its contents)
        window.auto_center = true
    end

    -- Title Bar
    local title_bar = window.add {
        type = "flow",
        direction = "horizontal",
    }
    -- Add some spacing to the title bar
    title_bar.style.horizontal_spacing = 8

    -- Title in top left
    local title = title_bar.add {
        type = "label",
        caption = window_title,
        style = constants.styles.frame.title,
    }

    -- drag handle to drag window around
    local dragger = title_bar.add {
        type = "empty-widget",
        style = constants.styles.frame.drag_bar,
    }
    -- Make it expand to fill the space
    dragger.style.minimal_width = 50
    dragger.style.height = drag_bar_height
    dragger.style.horizontally_stretchable = true
    dragger.drag_target = window

    -- Add pin button only if main window
    if window_name == constants.jolt.task_list.window then
        local pin_button = title_bar.add {
        type = "sprite-button",
        style = constants.styles.frame.button,
        sprite = constants.jolt.sprites.pin,
        name = constants.jolt.task_list.keep_window_open_button,
        tooltip = {"jolt.tooltip_pin"}
        }
        -- If this button is selected change its style to 
        -- be yellow button background
        if Task_manager.is_task_list_pinned_open(player) then
            pin_button.style = constants.styles.buttons.yellow
            pin_button.style.size = {24, 24}
        end
    end
    

    local close_button = title_bar.add {
        type = "sprite-button",
        style = constants.styles.frame.button,
        sprite = constants.jolt.sprites.close,
        name = close_button_name,
        tooltip = {"jolt.tooltip_close"}
    }


    return window
end


function Gui.new_dialog_window(options)
    -- Default values if none provided
    local default_width = 300
    local default_height = 400
    local drag_bar_height = 24

    -- Load options
    local player = options.player
    local window_title = options.window_title
    local window_name = options.window_name
    local back_button_name = options.back_button_name
    local confirm_button_name = options.confirm_button_name
    local width = options.width or default_width
    local height = options.height or default_height
    local auto_center = options.auto_center
    
    -- Get screen to display to
    local screen_element = player.gui.screen

    

    -- Check if window already exists and destroy it
    if player.gui.screen[window_name] then
        player.gui.screen[window_name].destroy()
    end

    local window = screen_element.add {
        type = "frame",
        name = window_name,
        direction = "vertical"
    }
    window.style.size = {width, height}


    -- Move the window to the saved location if it exists 
    local saved_location = Task_manager.get_saved_window_position(player, window_name)
    if auto_center and saved_location then
        window.location = saved_location
    else
        -- center the window in the screen (not its contents)
        window.auto_center = true
    end

    -- Title Bar
    local title_bar = window.add {
        type = "flow",
        direction = "horizontal",
    }
    -- Add some spacing to the title bar
    title_bar.style.horizontal_spacing = 8

    -- Title in top left
    local title = title_bar.add {
        type = "label",
        caption = window_title,
        style = constants.styles.frame.title,
    }

    -- drag handle to drag window around
    local dragger = title_bar.add {
        type = "empty-widget",
        style = constants.styles.frame.drag_bar,
    }
    -- Make it expand to fill the space
    dragger.style.minimal_width = 50
    dragger.style.height = drag_bar_height
    dragger.style.horizontally_stretchable = true
    dragger.drag_target = window

    -- Bottom row for buttons
    local bottom_controls = window.add {
        type = "flow",
        style = constants.styles.frame.h_buttons_row
    }

    -- Back button 
    local back_button = bottom_controls.add {
        type = "button",
        caption = {"jolt.back_button"},
        style = constants.styles.frame.back_button,
        name = back_button_name
    }

    -- drag handle to drag window around and add some spaceing
    local bottom_dragger = bottom_controls.add {
        type = "empty-widget",
        style = constants.styles.frame.drag_bar,
    }
    -- Make it expand to fill the space
    bottom_dragger.style.minimal_width = 10
    bottom_dragger.style.height = drag_bar_height
    bottom_dragger.style.horizontally_stretchable = true
    bottom_dragger.drag_target = window

    -- Confirm button
    local confirm_button = bottom_controls.add {
        type = "button",
        caption = {"jolt.confirm_button"},
        style = constants.styles.frame.confirm_button,
        name = confirm_button_name
    }

    --[[
    IMPORTANT: to put stuff in this and still have the bottom 
    controls be at the bottom add content and set index to 2
    
    Example:
    local new_task_form = new_task_window.add {
        type = "frame",
        direction = "vertical",
        index = 2
    }
    ]]

    return window
end


--- Adds a label to the provided parent and returns the reference
---@param parent gui-element
---@param text string
---@param any player - player associated
function Gui.new_label(parent, text, player)
    local label = parent.add {
        type = "label",
        caption = text
    }
    return label
end

--- Adds a row to the parent, for a individual task displaying title  
---@param parent LuaGuiElement The gui object that the task will be added to
---@param task Task The task object with title, desc, etc
function Gui.new_gui_task(parent, task, tab_in_ammount, selected_tasks, player)

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
                Gui.new_gui_task(task_container, subtask, tab_in_ammount, selected_tasks, player)
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

return Gui
