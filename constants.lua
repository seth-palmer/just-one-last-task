--- constants.lua 
--- A file to store constant vales that should never change

local constants = {}

constants.colors = {
    green = {94,182,99}
}

--- A place to store styles both built in and custom
--- so I can easily lookup what I might use
--- look in "data.lua" for styles
constants.styles = {
    frame = {
        title = "frame_title",
        drag_bar = "draggable_space",
        button = "frame_action_button",
        h_buttons_row = "dialog_buttons_horizontal_flow",
        confirm_button = "confirm_button",
        back_button = "back_button",
    },
    form = {
        textfield = "textbox",
    },
    text = {
        link = "jolt_link_button"
    },
    buttons = {
        red = "tool_button_red",
        yellow = "yellow_slot_button",
    }
    

}

--- Store all names used for jolt elements
--- divided by different windows
constants.jolt = {
    -- For shortcut buttons
    shortcuts = {
        open_task_list_window = "jolt_shortcut_open_task_list_window"
    },
    sprites = {
        add = "utility/add",
        close = "utility/close",
        edit = "utility/rename_icon",
        expand = "utility/expand",
        collapse = "utility/collapse",
        move = "utility/search",
        delete = "utility/trash",
    },
    group_management = {
        open_window_button = "jolt_open_group_management_button",
        window_name = "jolt_group_management_window",
        close_button = "jolt_group_management_close_button",
        delete_group = "jolt_delete_group_button",
        move_group_up = "jolt_move_group_up_button",
        move_group_down = "jolt_move_group_down_button",
        move_group_left = "jolt_move_group_left_button",
        move_group_right = "jolt_move_group_right_button",
        task_title_textbox = "jolt_groups_task_title_textbox",
        group_icon_button = "jolt_group_management_group_icon_button"
    },
    -- For main task list window
    task_list = {
        window = "jolt_task_list_window",
        close_window_button = "jolt_tasks_list_close_button",
        group_tabs_pane = "jolt_group_tabs_pane",
        add_task_button = "jolt_add_task_button",
        edit_task_button = "jolt_edit_task_button",
        toggle_details_button = "jolt_toggle_details_button",
        task_checkbox = "jolt_task_checkbox",
        show_completed_checkbox = "jolt_show_completed_tasks_checkbox",
        add_subtask_button = "jolt_add_subtask_button",
    },
    -- For new task window
    new_task = {
        window = "jolt_new_task_window",
        back_button = "jolt_new_task_back_button",
        confirm_button = "jolt_new_task_confirm_button",
        title_textbox = "jolt_new_task_title_textbox",
        add_to_top_checkbox = "jolt_new_task_checkbox_add_to_top",
        group_dropdown = "jolt_new_task_group_dropdown",
        form_container = "jolt_new_task_form_container",
    },
    -- Edit task window 
    edit_task = {
        confirm_button = "jolt_edit_task_confirm_button",
    },

}

return constants