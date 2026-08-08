-- Evolution Man: pay ¥4000 to evolve a trade-only POKéMON (KADABRA,
-- MACHOKE, GRAVELER, HAUNTER, or any mod-added species with a TRADE
-- evolution) on the spot, no link cable needed.
--
-- The party picker and the evolution call both reuse the exact same paths
-- the real in-game-trade NPCs use (src/script/Commands.lua Commands.trade
-- for the picker shape; src/pokemon/Evolution.lua for the TRADE method
-- check and the evolve-with-movie call), so this NPC recognizes any trade
-- evolution the loaded data defines -- nothing here is a hardcoded species
-- list -- and the evolution plays out identically to a real trade,
-- non-cancelable included.
--
-- No per-mon flag: nothing stops paying again for a second GENGAR, etc.

-- Placeholder spot near the CERULEAN CITY POKéMON CENTER. Object index is
-- deliberately high to dodge the map's real vanilla object indices.
-- Verify the tile is walkable before shipping -- the dev console
-- (`warp CERULEAN_CITY 10 12`) or Tiled (docs/tiled-map-editing.md) will
-- show it; nudge NPC_X/NPC_Y below if it lands on an obstacle.
local MAP_ID = "GAME_CORNER"
local NPC_X, NPC_Y = 19, 8
local NPC_INDEX = 90

local TALK_TEXT = "TEXT_EVOLUTION_MAN"
local COST = 4000

return function(mod)
  mod.content.maps:patch(MAP_ID, {
    objects = { __append = { {
      index = NPC_INDEX, name = "EVOLUTION_MAN", sprite = "SPRITE_GENTLEMAN",
      movement = "STAY", range = "LEFT", text = TALK_TEXT,
      x = NPC_X, y = NPC_Y,
    } } },
  })

  mod.content.commands:register("evolution_man:offer", {
    -- interactive dialogue, like the vanilla trade command it mirrors:
    -- illegal inside a parallel/ambient script
    foreground = true,
    fn = function(ctx)
      local Commands = require("src.script.Commands")
      local Evolution = require("src.pokemon.Evolution")
      local Screens = require("src.ui.Screens")

      Commands.show_text(ctx, "Yo! For just ¥4000\nI can make a TRADE-evolving")
      Commands.show_text(ctx, "POKéMON evolve, right here, no cable needed!")

      if (ctx.save.money or 0) < COST then
        Commands.show_text(ctx, "Come back with more\ncash, {PLAYER}!")
        return
      end

      Commands.ask(ctx, "Want me to do it?\nIt's ¥4000 a pop.")
      if not ctx.lastCheck then
        Commands.show_text(ctx, "Suit yourself.")
        return
      end

      -- InGameTrade_DoTrade-style picker (Commands.trade): push, yield,
      -- resume from onSwitch/onCancel
      local runner = ctx.runner
      local picked
      Screens.push(ctx.game, "PartyMenu", {
        pickOnly = true,
        onCancel = function() runner:resume() end,
        onSwitch = function(mon)
          picked = mon
          runner:resume()
        end,
      })
      runner:yield()
      if not picked then return end

      -- the real TRADE method check (src/pokemon/Evolution.lua): any
      -- species with a trade evolution row matches, vanilla or modded
      local species = Evolution.pendingFor(ctx.game, picked, { kind = "trade" })
      if not species then
        Commands.show_text(ctx, "That one won't\nevolve that way!")
        return
      end

      Commands.give_money(ctx, -COST)
      Commands.show_text(ctx, "Here we go!")
      Evolution.evolve(ctx.game, picked, species, function() runner:resume() end, "TRADE")
      runner:yield()
    end,
  })

  mod.content.map_scripts:register(MAP_ID, {
    talk = {
      [TALK_TEXT] = { { "evolution_man:offer" } },
    },
  })
end