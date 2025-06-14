--- gui.lua
--- A file to store premade graphical elements
local constants = require("constants")

function new_window(player, window_title, frame_name, close_button_name, width, height)
    local drag_bar_height = 24
    local close_button_size = 24
    
    local screen_element = player.gui.screen

    -- Check if window already exists and destroy it
    if player.gui.screen[frame_name] then
        player.gui.screen[frame_name].destroy()
    end

    local window = screen_element.add {
        type = "frame",
        name = frame_name,
        direction = "vertical"
    }
    window.style.size = {width, height}

    -- center the window in the screen (not its contents)
    window.auto_center = true

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


    local close_button = title_bar.add {
        type = "sprite-button",
        style = constants.styles.frame.button,
        sprite = "utility/close",
        name = close_button_name,
        tooltip = "Close"
    }


    return window
end


function new_dialog_window(options)
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

    -- center the window in the screen (not its contents)
    window.auto_center = true

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
        caption = {"gui.back_button"},
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
        caption = {"gui.confirm_button"},
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
function new_label(parent, text)
    local label = parent.add {
        type = "label",
        caption = text
    }
    return label
end

