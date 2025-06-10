-- Run from mod folder with `lua tests/test_tasks.lua`

luaunit = require('luaunit')
require "scripts.task"



function testTaskValidCreation()
    
    local t1Params = {title="Red Science", groupId=1, desc="Automate 5/sec"}

    local t = Task.new(t1Params)
    print(t)

    luaunit.assertEquals(t.getTitle(), t1Params.title)
end


function testTaskCreationWithEmptyParams()
    local params = {}
    local t = Task.new(params)
    luaunit.assertEquals(t.getTitle(), "")
end




os.exit( luaunit.LuaUnit.run() )
