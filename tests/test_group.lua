luaunit = require('luaunit')
require "scripts.task"
require "scripts.group"

local t1Params = {title="Red Science", groupId=1, description="Automate 5/sec"}
local t2Params = {title="Green Science", groupId=1, description="Automate 5/sec"}
local t3Params = {title="Millitary Science", groupId=1, description="Automate 5/sec"}

function testGroup()
    local g = Group.new({groupId=1, name="Nauvis"})

    g.addTask(t1Params)
    g.addTask(t2Params)
    g.addTask(t3Params)

    local tasks = g.getTasks()
    for k, v in pairs(tasks) do 
        print(v) 
    end
    
    
    print(g)
end



os.exit( luaunit.LuaUnit.run() )