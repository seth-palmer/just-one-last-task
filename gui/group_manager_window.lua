
local GROUP_MANAGEMENT_WINDOW_WIDTH = 320
local GROUP_MANAGEMENT_WINDOW_HEIGHT = 480

-- Imports
local constants = require("constants")
local Gui = require("gui")
local TaskManager = require("scripts.task_manager")
local PlayerState = require("scripts.player_state")


local GroupManagerWindow = {}

--- Opens the group management window
---@param event any
function GroupManagerWindow.open(event)
    local player = game.get_player(event.player_index)
    local title = {"jolt_group_management.window_title"}
    local window_name = constants.jolt.group_management.window_name
    local close_name = constants.jolt.group_management.close_button
    local window_width = GROUP_MANAGEMENT_WINDOW_WIDTH
    local window_height = GROUP_MANAGEMENT_WINDOW_HEIGHT
    local window = Gui.new_window(player, title, window_name, close_name, window_width, window_height)

    -- Add event to watch for button click to close the window
    PlayerState.bind_close_button(player, close_name, window_name)

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
        local selected_group_id = PlayerState.get_group_management_selected_group_id(player)
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
        icon_selector = true, -- add icon selector section
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

--- Close the window for the player
---@param player any
function GroupManagerWindow.close(player)
    if player.gui.screen[constants.jolt.group_management.window_name] then
        player.gui.screen[constants.jolt.group_management.window_name].destroy()
    end
end


return GroupManagerWindow