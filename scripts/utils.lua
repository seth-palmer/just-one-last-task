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

return Utils