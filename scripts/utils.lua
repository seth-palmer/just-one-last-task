-- A file to put helpful methods that could be used in more than one file

-- Generate a random uuid https://gist.github.com/jrus/3197011
math.randomseed(os.time())
local random = math.random
function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end