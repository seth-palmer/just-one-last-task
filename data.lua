local constants = require "constants"

-- Factorio LuaStyle
-- https://lua-api.factorio.com/latest/classes/LuaStyle.html


-- Style prototypes 
local styles = data.raw["gui-style"].default

styles["jolt_content_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame",
    padding = 12
}

styles["jolt_deep_frame"] = {
    type = "frame_style",
    parent = "slot_button_deep_frame",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    top_margin = 16,
    left_margin = 8,
    right_margin = 8,
    bottom_margin = 4
}

-- Style for blue "+ subtask" button
styles["jolt_link_button"] = {
    type = "label_style",
    font = "default-semibold",
    font_color = {0.501961, 0.807843, 0.941176},
    hovered_font_color = {0.603922, 0.980392, 1},
}


-- styles["jolt_controls_flow"] = {
--     type = "horizontal_flow_style",
--     vertical_align = "center",
--     horizontal_spacing = 16
-- }

-- styles["jolt_controls_textfield"] = {
--     type = "textbox_style",
--     width = 36
-- }


-- styles["task_list"] = {
--     type = "frame_style",
--     parent = "inside_shallow_frame_with_padding",
--     vertically_stretchable = "on",
--     top_margin = 20
-- }

-- styles["task_controls"] = {
--     type = "frame_style",
--     parent = "inside_shallow_frame_with_padding",
--     vertically_stretchable = "on",
--     top_margin = 20
-- }


-- styles["jolt_add_task_textfield"] = {
--     type = "textbox_style",
--     width = 200
-- }



data:extend({
    -- Custom shortcut icon 
    {
        type = "shortcut",
        name = constants.jolt.shortcuts.open_task_list_window,
        order = "b[blueprints]-i[deconstruction-planner]",
        action = "lua",
        localised_name = {"jolt.tasks-menu"},
        associated_control_input = constants.jolt.shortcuts.open_task_list_window,
        -- style = "blue",
        icon = "__just-one-last-task__/graphics/icons/jolt-shortcutx64.png",
        icon_size = 64,
        small_icon = "__just-one-last-task__/graphics/icons/jolt-shortcutx24.png",
        small_icon_size = 24,
        scale = 0.5,  -- scale down to 32x32
        flags = {"gui-icon"},
    },
    -- Custom icons for GUI
    {
        type = "sprite",
        name = "jolt-icon-left",
        filename = "__just-one-last-task__/graphics/icons/leftx64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-right",
        filename = "__just-one-last-task__/graphics/icons/rightx64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-up",
        filename = "__just-one-last-task__/graphics/icons/upx64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-down",
        filename = "__just-one-last-task__/graphics/icons/downx64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-plus",
        filename = "__just-one-last-task__/graphics/icons/plusx64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-folder",
        filename = "__just-one-last-task__/graphics/icons/folderx64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-edit",
        filename = "__just-one-last-task__/graphics/icons/editx64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-edit-group",
        filename = "__just-one-last-task__/graphics/icons/edit-groupx64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-pin",
        filename = "__just-one-last-task__/graphics/icons/pinx64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-trash",
        filename = "__just-one-last-task__/graphics/icons/trashx64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-plus-folder",
        filename = "__just-one-last-task__/graphics/icons/plus-folder.png",
        priority = "extra-high-no-scale",
        width=156,
        height=64,
        flags = {"gui-icon"}
    },
})







