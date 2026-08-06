--- Imports
local TaskManager = require("scripts.task_manager")
local PlayerState = require("scripts.player_state")
local constants = require("constants")
local Gui = require("gui")
local Utils = require("scripts.utils")
local Outcome = require("scripts.outcome")
local VisualActionLog = require("scripts.visual_action_log")

-- Graphical Imports 
local TaskListWindow = require("gui.task_list_window")
local GroupManagerWindow = require("gui.group_manager_window")
local TaskFormWindow = require("gui.task_form_window")


local OnResearchFinished = {}

--- Adds a group when a new planet is researched
function OnResearchFinished.add_group_for_new_planet(event)
    -- get the name of the technology researched
    local tech = event.research.name

    -- Handle edge case for apia-carnova mod which has 2 planets under 1 research    
    if script.active_mods["apia"] and tech == 'planet-discovery-apia-carnova' then
        -- create groups for both planets
        -- create a group for the planet
        local group_name = "Apia"
        local group_icon = "space-location/apia"
        local new_group = {name = group_name, icon = group_icon}
        Task_manager.add_group(new_group)

        local group_name = "Carnova"
        local group_icon = "space-location/carnova"
        local new_group = {name = group_name, icon = group_icon}
        Task_manager.add_group(new_group)

        -- Refresh for players 
        TaskListWindow.refresh_for_all()
        GroupManagerWindow.refresh_for_all()
        
    -- if the tech is for a new planet add a group
    elseif Utils.string_starts_with(tech, constants.jolt.planet_tech_string_start) then
        -- Get the name from the end of the tech research
        local planet_name = tech:gsub(constants.jolt.planet_tech_name_search, "")

        -- create a group for the planet
        local group_name = Utils.first_to_upper(planet_name)
        local group_icon = "space-location/" .. planet_name
        local new_group = {name = group_name, icon = group_icon}
        Task_manager.add_group(new_group)

        -- Refresh for players 
        TaskListWindow.refresh_for_all()
        GroupManagerWindow.refresh_for_all()
    end
end


script.on_event(defines.events.on_research_finished, function(event)
    OnResearchFinished.add_group_for_new_planet(event)
end)

return OnResearchFinished