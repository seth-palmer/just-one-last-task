--- constants.lua 
--- A file to store constant vales that should never change

local constants = {}

constants.colors = {
    green = {94,182,99}
}

--- A place to store styles both built in and custom
--- so I can easily lookup what I might use
constants.styles = {
    frame = {
        title = "frame_title",
        drag_bar = "draggable_space",
        button = "frame_action_button"
    }
    

}

return constants