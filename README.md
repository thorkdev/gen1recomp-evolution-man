# Evolution Man

An NPC in the Game Corner in Celadon who evolves a trade-only POKéMON for $4000, no link cable needed:
KADABRA, MACHOKE, GRAVELER, HAUNTER, or any species another mod gives a
`TRADE` evolution. Talk to him, pay, pick a party member from the picker,
and — if it has a trade evolution — it evolves right there, movie and all.

No per-mon flag: he'll do it again on a second HAUNTER if you want two
GENGARs, etc.

<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/980d4895-0f8a-4365-8510-aad02db28f3d" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/70db16b8-237c-461d-8c66-f857f6fef81c" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/c1ad8a5c-7c42-4aa7-91c1-fc669a74204f" />

## How it works

- `mod.content.maps:patch` appends one new NPC object to `GAME_CORNER`
  (`__append`, so the map's real object list is untouched, not replaced).
- Talking to him runs a single custom script command,
  `evolution_man:offer`, registered via `mod.content.commands:register`.
  It mirrors `Commands.trade` in `src/script/Commands.lua` (the vanilla
  in-game-trade NPCs): push the `PartyMenu` screen in `pickOnly` mode,
  yield the script runner, resume on `onSwitch`/`onCancel`.
- Eligibility is checked with `Evolution.pendingFor(game, mon, { kind =
  "trade" })` — the same TRADE-method check the engine runs for a real
  link trade (`src/pokemon/Evolution.lua`). Nothing here hardcodes a
  species list, so it keeps working if another mod adds its own trade
  evolution.
- On a match: `Commands.give_money(ctx, -4000)`, then
  `Evolution.evolve(game, mon, species, onDone, "TRADE")` — the `"TRADE"`
  tag is what keeps the animation non-cancelable, same as a real trade
  (`EvolutionState`'s cancelable check).
