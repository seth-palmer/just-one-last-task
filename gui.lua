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

