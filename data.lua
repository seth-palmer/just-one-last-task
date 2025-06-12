
-- Factorio LuaStyle
-- https://lua-api.factorio.com/latest/classes/LuaStyle.html


-- These are some style prototypes that the tutorial uses
-- You don't need to understand how these work to follow along
local styles = data.raw["gui-style"].default


data:extend({
    {
    type = "shortcut",
    name = "tasks-menu",
    order = "b[blueprints]-i[deconstruction-planner]",
    action = "lua",
    localised_name = {"jolt.tasks-menu"},
    associated_control_input = "tasks-menu",
    style = "green",
    icon = "__base__/graphics/icons/shortcut-toolbar/mip/new-deconstruction-planner-x56.png",
    icon_size = 56,
    small_icon = "__base__/graphics/icons/shortcut-toolbar/mip/new-deconstruction-planner-x24.png",
    small_icon_size = 24
    }
})


styles["ugg_content_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on"
}

styles["ugg_controls_flow"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 16
}

styles["ugg_controls_textfield"] = {
    type = "textbox_style",
    width = 36
}

styles["ugg_deep_frame"] = {
    type = "frame_style",
    parent = "slot_button_deep_frame",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    top_margin = 16,
    left_margin = 8,
    right_margin = 8,
    bottom_margin = 4
}

styles["task_list"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on",
    top_margin = 20
}

styles["task_controls"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on",
    top_margin = 20
}


styles["jolt_add_task_textfield"] = {
    type = "textbox_style",
    width = 200
}
