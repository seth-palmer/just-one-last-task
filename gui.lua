--- gui.lua
--- A file to store premade graphical elements
local constants = require("constants")
local PlayerState = require("scripts.player_state")

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
    local saved_location = PlayerState.get_saved_window_position(player, window_name)
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
        if PlayerState.is_task_list_pinned_open(player) then
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
        direction = "vertical",
    }
    window.style.size = {width, height}


    -- Move the window to the saved location if it exists 
    local saved_location = PlayerState.get_saved_window_position(player, window_name)
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



return Gui
