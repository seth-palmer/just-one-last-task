require "group"
require "task"



local params = {}
params.groupId = 0
params.name = "Nauvis"
local defaultGroups = {}
local g1 = Group.new(params)
table.insert(defaultGroups, g1)


function swap()
    
end

TaskManager = {}

-- Named Arguments as per - lua style https://www.lua.org/pil/5.3.html
function TaskManager.new(params)
    -- Handle empty params
    if params == nil then
        params = {}
    end

    local self = {}


    -- Store group, player, and task data
    local groups = params.groups or {}
    local players = params.players or {}
    local tasks = params.tasks or {}

    -- A list of taskIds
    local priorities = params.priorities or {}

    --add to list with table.insert(players, "p1")

    -- Add a task using provided parameters
    function self.addTask(params, isInsertAtEnd)
        isInsertAtEnd = isInsertAtEnd or false
        newTask = Task.new(params)

        -- Add id to priorities list
        if isInsertAtEnd then
            table.insert(priorities, #priorities, newTask)    
        else
            -- insert to end then swap with first value
            table.insert(priorities, #priorities, newTask) 
        end

    end

    -- For debugging
    function self.stats()
        -- '#' before a list makes it return a count (won't work for dictionaries)
        stats = string.format("Groups: %d, Players: %d, Tasks: %d", #groups, #players, #tasks)
        return stats
    end


    return self
end

params = {}
print(g1.toString())
params.groups = defaultGroups

manager = TaskManager.new(params)
print("=====Stats=====")
print(manager.stats())
print()




local t1 = Task.new()
t1.print()
print("got title: ", t1.getTitle())
t1.setTitle("title2")
print("new title: ", t1.getTitle())


