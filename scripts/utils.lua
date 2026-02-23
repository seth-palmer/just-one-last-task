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



-- TIP:
-- use log to debug without and 'event'
-- check `factorio-current.log` next the the `saves` dir
-- log("subtask_id: " .. subtask_id)
-- Log tables
-- log("subtask_id: " .. subtask_id)
-- log(serpent.block(my_table))
-- log(serpent.line(my_table))
return Utils