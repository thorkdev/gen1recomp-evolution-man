-- Soft compatibility patches for other mods that touch the trade-evolution
-- species this NPC depends on. Each patch only applies when its target mod
-- is actually loaded (mod.find), so this file is a no-op without it.

-- true if def already has a TRADE row evolving into targetSpecies -- guards
-- both blocks below against appending a redundant duplicate when a save
-- somehow runs more than one compat block over the same species (e.g. both
-- all_pokemon_catchable_151_mod and CRYSTAL_251 installed together).
local function hasTradeEvo(def, targetSpecies)
  for _, evo in ipairs((def or {}).evolutions or {}) do
    if evo.method == "TRADE" and evo.species == targetSpecies then return true end
  end
  return false
end

return function(mod)
  -- all_pokemon_catchable_151_mod's "Impossible Evolutions" patch
  -- (mods/All_Pokemon_Catchable_151_Mod-main/main.lua) replaces KADABRA's,
  -- GRAVELER's, HAUNTER's, and MACHOKE's whole `evolutions` array with a
  -- single LEVEL row, so those species can evolve without trading. The
  -- pokemon registry is "record" semantics (src/mods/Schemas.lua), and a
  -- bare array patch value fully replaces the target array under those
  -- semantics (src/mods/Merge.lua Merge.deepMerge) -- it deletes the TRADE
  -- row rather than merging alongside it, so this NPC's
  -- `Evolution.pendingFor(game, mon, { kind = "trade" })` check stops
  -- matching those four species even though they're exactly the vanilla
  -- trade-evolution mons it exists for.
  --
  -- Fix: append a TRADE row back on via the __append wrapper, which
  -- extends whatever array is already there regardless of registry
  -- semantics (Merge.lua: isWrapper short-circuits before the
  -- array-replace rule). Both mods' intents survive: level 42/45 still
  -- works for players who don't want to pay, and this NPC still works for
  -- players who do.
  if mod.find("all_pokemon_catchable_151_mod") then
    local TRADE_EVOS = {
      KADABRA = "ALAKAZAM",
      GRAVELER = "GOLEM",
      HAUNTER = "GENGAR",
      MACHOKE = "MACHAMP",
    }
    for species, evolvesInto in pairs(TRADE_EVOS) do
      if not hasTradeEvo(mod.content.pokemon:get(species), evolvesInto) then
        mod.content.pokemon:patch(species, {
          evolutions = { __append = {
            { method = "TRADE", species = evolvesInto },
          } },
        })
      end
    end
    mod.log:info("compat: restored TRADE evolutions on KADABRA/GRAVELER/HAUNTER/"
      .. "MACHOKE for all_pokemon_catchable_151_mod")
  end

  -- CRYSTAL_251's ROM import (lib/extractor.lua parseEvolutionData) folds
  -- every EVOLVE_TRADE row -- Gen I's plain trades (KADABRA, MACHOKE,
  -- GRAVELER, HAUNTER) included -- into an ITEM evolution instead of a
  -- TRADE one: a real link partner isn't available in a single-player
  -- recomp, so a no-held-item trade (held byte 0xff) becomes
  -- `{ method = "ITEM", item = "LINKING_CORD" }`, a buyable stand-in item
  -- (main.lua: `LINKING_CORD={"LINKING CORD",15000}`) the player uses
  -- directly instead of trading. mod.content.pokemon:override then
  -- replaces each species record outright (Registry:override -- no merge
  -- at all), so every one of those rows loses whatever TRADE row it had.
  --
  -- item == "LINKING_CORD" is CRYSTAL_251's own unambiguous marker for "was
  -- a plain trade evolution" -- held-item trades (Poliwhirl, Onix, Seadra,
  -- etc.) resolve to their real held item instead and are left alone, since
  -- those already have a legitimate non-trade path.  Scanning the merged
  -- data for that marker (rather than hardcoding a species list) keeps this
  -- working if Crystal 251's roster changes.  Both paths stay valid:
  -- LINKING CORD for players who'd rather shop, this NPC for players who'd
  -- rather pay.
  if mod.find("CRYSTAL_251") then
    local additions = {}
    for id, def in mod.content.pokemon:each() do
      for _, evo in ipairs(def.evolutions or {}) do
        if evo.method == "ITEM" and evo.item == "LINKING_CORD"
            and not hasTradeEvo(def, evo.species) then
          additions[#additions + 1] = { id = id, species = evo.species }
        end
      end
    end
    for _, addition in ipairs(additions) do
      mod.content.pokemon:patch(addition.id, {
        evolutions = { __append = {
          { method = "TRADE", species = addition.species },
        } },
      })
    end
    if #additions > 0 then
      mod.log:info("compat: restored %d TRADE evolution(s) alongside "
        .. "CRYSTAL_251's LINKING_CORD item evolutions", #additions)
    end
  end
end
