-- A file to put helpful methods that could be used in more than one file
local Utils = {}
-- Generate a random uuid https://gist.github.com/jrus/3197011
-- TODO fix to be truely random
math.randomseed(1)
local random = math.random
function Utils.uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- Enum to store Direction
Direction = {Up = 1, Down = 2}

--- Display the provided error to the player at the cursor position
---@param player any affected player 
---@param message string the message to display
function Utils.display_error(player, message)
    player.create_local_flying_text {
        text = message,
        create_at_cursor=true,
    }
end


--[[
    IMPORTANT: for a gui element to be detected it must either have an 
                element name with the prefix "jolt" 
                
                OR have the tag "is_jolt = true"

        Example: 

        local icon_button = button_table.add{
            type="sprite-button",
            sprite=group.icon,
            style="slot_button",
            -- Add tags since can't use the same name for each
            -- but can check tag for group_mgnmt_btn and then get group_id
            tags = {is_jolt = true, is_group_management_icon_button=true, group_id=group.id}
        }
    ]]--
--- Returns true if the element is from just-one-last-task mod
---@param element any element to check
function Utils.is_element_from_jolt_mod(event)
    -- Exit if invalid element data
    local element = event.element
    if not element or not element.valid then return false end

    local element_name = element.name

    -- Early exit: ignore elements that don't belong to me
    if element.tags and element.tags.is_jolt or element_name:find("^jolt") or (element.tags.name and element.tags.name:find("^jolt")) then
        --TIP: uncomment below to debug naming issues
        -- is our gui element so continue
        return true
    else
        -- debug_print(event, "tags is jolt = " )
        -- debug_print(event, event.element.tags.is_jolt)
        return false
    end
end

--- Helper function to find a child in a parent
---@param parent any
---@param name any
function Utils.find_element(parent, name)
    if parent.name == name then return parent end
    for _, child in pairs(parent.children) do
        local found = Utils.find_element(child, name)
        if found then return found end
    end
end

--- Determines if the string starts with the provided prefix
--- Source - https://stackoverflow.com/a/22831842
--- Posted by filmor
--- Retrieved 2026-05-06, License - CC BY-SA 3.0
function Utils.string_starts_with(original, prefix)
   return string.sub(original,1,string.len(prefix))==prefix
end

--- Returns the string after the provided prefix
function Utils.split_after(string, prefix)
    if string.sub(string, 1, #prefix) == prefix then
        return string.sub(string, #prefix + 1)
    end
    return nil  -- prefix not found
end

-- TIP:
-- use log to debug without and 'event'
-- check `factorio-current.log` next the the `saves` dir
-- log("subtask_id: " .. subtask_id)
-- Log tables
-- log("subtask_id: " .. subtask_id)
-- log(serpent.block(my_table))
-- log(serpent.line(my_table))
return Utils