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


-- A solid colored background using a pixel from Factorio's own GUI atlas
-- https://lua-api.factorio.com/latest/types/ElementImageSetLayer.html#draw_type
styles["jolt_task_selected"] = {
    type = "frame_style",
    parent = "invisible_frame",
    graphical_set = {
        base = {
            position = {34, 17},
            corner_size = 8,
            draw_type = "outer" -- draw outside the widget so it doesn't move
        },
    }
}

styles["jolt_dark_dropdown"] = {
    type = "dropdown_style",
    parent = "dropdown",

    top_padding = -1,
    bottom_padding = 1,
    left_padding = 8,
    right_padding = 4,
    selector_and_title_spacing = 8,

    button_style =  {
        type = "button_style",
        -- style take from "dark_button"

        default_graphical_set = {
            base = {position = {68, 0}, corner_size = 8},
            shadow = {position = {395, 86}, corner_size = 4, draw_type = "inner"}
        }
    },

    icon = {
        filename = "__core__/graphics/icons/mip/dropdown.png",
        priority = "extra-high-no-scale",
        size = 32,
        scale = 0.5,
        flags = {"gui-icon"},
        mipmap_count = 2
    },

    list_box_style = {
        type = "list_box_style",
        maximal_height = 400,
        minimal_width = 100,
        scroll_pane_style = {
            type = "scroll_pane_style",
            always_draw_borders = true,
            padding = 0,
            extra_padding_when_activated = 0,
            graphical_set = {shadow = default_shadow}
        }
    }
}

styles["jolt_dark_dropdown_old"] = {
   type = "dropdown_style",
    parent = "dropdown",
    minimal_width = 150,

    button_style = {
        type = "button_style",
        parent = "dropdown_button",
        font_color = {1, 1, 1},
        disabled_font_color = {179, 179, 179},

        -- position {68, 0} is the dark/shallow frame graphic — same as `shallow_frame`
        -- and `dark_button` in the file, which is the recessed dark look
        default_graphical_set = {
            base = {position = {68, 0}, corner_size = 8},
            shadow = {
                position = {395, 86},
                corner_size = 8,
                draw_type = "outer"
            }
        },
        hovered_graphical_set = {
            base = {position = {34, 17}, corner_size = 8},
            glow = {
                position = {200, 128},
                corner_size = 8,
                tint = {225, 177, 106, 255},
                scale = 0.5,
                draw_type = "outer"
            }
        },
        clicked_graphical_set = {
            base = {position = {51, 17}, corner_size = 8},
        },
        disabled_graphical_set = {
            base = {position = {17, 17}, corner_size = 8},
        },
    },

    list_box_style = {
        type = "list_box_style",
        parent = "list_box",
        maximal_height = 400,

        -- dark background matching `inside_deep_frame`
        item_style = {
            type = "button_style",
            parent = "list_box_item",
            default_font_color = {1, 1, 1},
            hovered_font_color = {0, 0, 0},
            selected_font_color = {241, 190, 100},  -- gold, matches Factorio selection colour
            selected_hovered_font_color = {0, 0, 0},
        },

    }
}



--- Code taken from Mission Tasks by Wysel
--- https://mods.factorio.com/mod/mission-tasks
--- prototypes/frames.lua
local function create_translucent_style(name, opacity)
  styles[name] = {
    type = "frame_style",
    parent = "frame",
    padding = 8,
    graphical_set = {
      type = "composition",
      filename = "__core__/graphics/gui.png",
      priority = "extra-high-no-scale",
      corner_size = {3, 3},
      position = {0, 0},
      opacity = opacity
    }
  }
end

create_translucent_style("jolt_frame_translucent_0",   0.0)
create_translucent_style("jolt_frame_translucent_10",  0.1)
create_translucent_style("jolt_frame_translucent_20",  0.2)
create_translucent_style("jolt_frame_translucent_30",  0.3)
create_translucent_style("jolt_frame_translucent_40",  0.4)
create_translucent_style("jolt_frame_translucent_50",  0.5)
create_translucent_style("jolt_frame_translucent_60",  0.6)
create_translucent_style("jolt_frame_translucent_70",  0.7)
create_translucent_style("jolt_frame_translucent_80",  0.8)
create_translucent_style("jolt_frame_translucent_90",  0.9)
create_translucent_style("jolt_frame_translucent_100", 1.0)

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
    -- Selection tool to set the location
    {
        type = "selection-tool",
        name = constants.jolt.tools.location_selector,
        icons = {
        {
            icon = "__just-one-last-task__/graphics/icons/map_marker_64x64.png",
            icon_size = 64,
            scale = 0.5
        }
        },
        flags = {"only-in-cursor", "spawnable", "not-stackable"},
        subgroup = "tool",
        order = "c[automated-construction]-a[task-location-selector]",
        stack_size = 1,

        select = {
        mode = "any-entity",
        cursor_box_type = "entity",
        border_color = { r = 0, g = 1, b = 0 },
        },
        alt_select = {
        mode = "any-entity",
        cursor_box_type = "entity",
        border_color = { r = 1, g = 0, b = 0 },
        },
    },
    -- Custom shortcut icon 
    {
        type = "shortcut",
        name = constants.jolt.shortcuts.open_task_list_window,
        order = "b[blueprints]-i[deconstruction-planner]",
        action = "lua",
        localised_name = {"jolt.tasks-menu"},
        associated_control_input = constants.jolt.shortcuts.open_task_list_window,
        icon = "__just-one-last-task__/graphics/icons/jolt_shortcut_64x64.png",
        icon_size = 64,
        small_icon = "__just-one-last-task__/graphics/icons/jolt_shortcut_24x24.png",
        small_icon_size = 24,
        scale = 0.5,  -- scale down to 32x32
        flags = {"gui-icon"},
        toggleable = true, -- change styles to show if it is on/off
    },
    {
        type = "custom-input",
        name = constants.jolt.shortcuts.open_task_list_window,  -- same name as shortcut
        key_sequence = "CONTROL + T",
        action = "lua",
    },
    -- Custom icons for GUI
    {
        type = "sprite",
        name = "jolt-icon-left",
        filename = "__just-one-last-task__/graphics/icons/left_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-right",
        filename = "__just-one-last-task__/graphics/icons/right_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-up",
        filename = "__just-one-last-task__/graphics/icons/up_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-down",
        filename = "__just-one-last-task__/graphics/icons/down_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-plus",
        filename = "__just-one-last-task__/graphics/icons/plus_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-folder",
        filename = "__just-one-last-task__/graphics/icons/folder_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-edit",
        filename = "__just-one-last-task__/graphics/icons/edit_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-edit-group",
        filename = "__just-one-last-task__/graphics/icons/edit_group_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-pin",
        filename = "__just-one-last-task__/graphics/icons/pin_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-trash",
        filename = "__just-one-last-task__/graphics/icons/trash_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-plus-folder",
        filename = "__just-one-last-task__/graphics/icons/plus_folder_156x64.png",
        priority = "extra-high-no-scale",
        width=156,
        height=64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-subtasks",
        filename = "__just-one-last-task__/graphics/icons/subtasks_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-location",
        filename = "__just-one-last-task__/graphics/icons/map_marker_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-status-completed",
        filename = "__just-one-last-task__/graphics/icons/status_completed_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-status-in-progress",
        filename = "__just-one-last-task__/graphics/icons/status_in_progress_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-status-blocked",
        filename = "__just-one-last-task__/graphics/icons/status_blocked_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-status-paused",
        filename = "__just-one-last-task__/graphics/icons/status_paused_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-status-not-started",
        filename = "__just-one-last-task__/graphics/icons/status_not_started_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-status-not-started_2",
        filename = "__just-one-last-task__/graphics/icons/status_not_started1_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
    {
        type = "sprite",
        name = "jolt-icon-status-not-started_3",
        filename = "__just-one-last-task__/graphics/icons/status_not_started3_64x64.png",
        priority = "extra-high-no-scale",
        size = 64,
        flags = {"gui-icon"}
    },
})







