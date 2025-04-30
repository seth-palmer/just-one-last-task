--control.lua

script.on_event(defines.events.on_player_created, function(event)
  -- get current player
  local player = game.get_player(event.player_index)

  -- get screen to add our gui to
  local screen_element = player.gui.screen

  -- make a 'frame' (window)
  local main_frame = screen_element.add{type="frame", name="ugg_main_frame", caption={"jolt.hello_world"}}

  -- set gui settings
  main_frame.style.size = {400, 400}
  main_frame.auto_center = false

end)


--[[ code from tutorial
script.on_event(defines.events.on_player_changed_position,
  function(event)
    local player = game.get_player(event.player_index) -- get the player that moved
    -- if they're currently controlling the character
    if player.controller_type == defines.controllers.character then
      -- and wearing our armor
      if player.get_inventory(defines.inventory.character_armor).get_item_count("fire-armor") >= 1 then
        -- create the fire where they're standing
        player.surface.create_entity{name="fire-flame", position=player.position, force="neutral"}
      end
    end
  end
)
]]
