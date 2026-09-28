# Swipe Fishing

An [AzerothCore](https://www.azerothcore.org/) (WotLK 3.3.5a) module: druids fish like bears. No
pole, no bobber, just claws.

Put on a salmon relic, take Bear Form, wade into water facing deeper water, and **use the relic**
(Salmon Run). The bear roars, sits and watches the water. A salmon waits under the surface in front of you. When it bites,
it surfaces at your feet with a splash and the fishing bobber's bite sound, and you have 2 seconds
to **target it and Swipe** (Swipe needs a target; target the fish while you wait):

- **In time** and you catch it. The loot window opens with whatever normal fishing would give in
  that spot. If you close it, loot the salmon's body for the rest.
- **Swipe too early** and you scare it off for a few seconds.
- **Too late** and it gets away; wait for the next bite.

The fishing goes on, one bite after another, until you move, leave the water or leave Bear Form,
or use the relic again.

## Salmon Run

Every salmon relic has it as its Use effect:

> Use: Call the salmon. Wade into the water and watch; when a salmon surfaces with a splash, Swipe
> it before it gets away. Use again to stop fishing.

- Use the relic from the character window, or put it on an action bar: drag it from the character
  window, or make a `/use 18` macro (18 is the relic slot).
- Instant, no cost, the normal global cooldown.
- Bear Form or Dire Bear Form only, like Swipe; in other forms the client says so.
- Not in combat. It works while sitting, so using the relic again stops the fishing.

It's a new spell (90060), so players need the realm's client patch; see [Client patch](#client-patch).
Before Salmon Run, `/roar` started the fishing. `SwipeFishing.StartEmote = 75` brings that back,
alongside the relic.

If your client's Auto Loot option is on, it takes everything as soon as the window opens; turn it
off (or hold Shift) to pick. The server can't change that.

## Catches follow the fishing rules

- **Loot:** the zone's normal fishing loot (the area's, else the zone's), like a bobber.
- **Catch chance:** your fishing skill against the zone's fishing level, the core's own formula,
  certain at zone level + 95. A well-timed Swipe can still fail: the salmon slips out of your
  claws. By default the chance never drops below 50%, because Moonglade's fishing level is 205 and
  a level 20 druid would otherwise catch about one fish in nine.
- **Skill-ups:** every catch attempt can raise fishing skill, as with a bobber.
- **Achievements and statistics:** a caught salmon's loot counts as fishing, in open water and in
  pools, so the fish-caught counters and fishing achievements go up as with a bobber.
- You need to know Fishing.

## Fishing pools

Pools (schools of fish) work as they do for a bobber:

- Start fishing with a pool within 12 yards and the salmon waits in the middle of the pool instead of in
  front of you.
- A salmon in a pool is a **sure catch**, and it opens the **pool's own loot**, like a bobber in a
  pool.
- Each catch uses up one of the pool's catches. When it's empty the pool despawns and moves on as
  usual, and the next salmon gives the zone's ordinary fishing loot.

## The relic

One druid idol that grows with your fishing. There's one per fishing rank, and wearing any of them
is what lets you fish in Bear Form. They have Stamina and fishing skill, and nothing else.

| Relic | Rank | Level | Stats |
|---|---|---|---|
| Ossified Salmon | Journeyman | 16 | +5 Stamina, +5 Fishing |
| Fossilized Salmon | Expert | 20 | +10 Stamina, +15 Fishing |
| Petrified Salmon | Artisan | 35 | +15 Stamina, +20 Fishing |
| Moonstone Salmon | Master | 50 | +20 Stamina, +25 Fishing |
| Voracious Salmon | Grand Master | 65 | +25 Stamina, +30 Fishing |

All are bind on pickup and unique; the first four are blue and the last is epic. There's no +10
Fishing step because the client has no +10 fishing item spell.

**Tavar Riverclaw** <Druid of the Claw>, a tauren druid on the south shore of Lake Elune'ara in
Moonglade, a short walk south of Nighthaven, gives them out. Every druid can get there with
Teleport: Moonglade. Each quest opens when you can train the matching fishing rank: the fishing
skill and the character level that rank needs.

| Quest | Needs | Hand in | Reward |
|---|---|---|---|
| The Way of the Claw | Fishing 50, level 16 | | Ossified Salmon |
| Stone and Scale | Fishing 125, level 20 | Ossified Salmon | Fossilized Salmon |
| The Mountain's Catch | Fishing 200, level 35 | Fossilized Salmon | Petrified Salmon |
| Under Elune's Light | Fishing 275, level 50 | Petrified Salmon | Moonstone Salmon |
| The Old Bear's River | Fishing 350, level 65 | Moonstone Salmon | Voracious Salmon |

You can hand in the relic you're wearing; there's no need to take it off first. A druid who's
already past several ranks can do the quests back to back.

## What needs the client patch, and what doesn't

- **Salmon Run** is the one thing that does. See [Client patch](#client-patch).
- **Swipe, not Fishing.** The 3.3.5 client refuses to cast Fishing in Bear Form or without a
  pole, so the druid never casts it: the salmon is a creature, and a Swipe while it bites
  catches it.
- **Rage.** A bear out of combat has no rage, and Swipe costs 20. When a salmon bites you're
  topped up to 25 rage, enough for one Swipe.
- **Items.** The client takes item icons from its own files, by item number, and a custom
  number would show a question mark. So the relics reuse idol numbers players can't get in 3.3.5:
  - 23004 and 42574, a green idol icon (Ossified and Fossilized Salmon).
  - 42576 and 42577, a nature idol icon (Petrified and Moonstone Salmon).
  - 25667, a removed TBC idol with a roaring bear icon (Voracious Salmon).

  The module's SQL rewrites their database rows. The uninstall SQL puts the originals back.
- **Tooltips.** The "Equip: Fishing skill increased by N" lines are the item spells real fishing
  gear uses.
- **Effects.** When a salmon bites you hear the fishing bobber's bite sound and see a water burst.
  That splash is the only one: the fish is quiet while it waits.

## Install

```bash
cd azerothcore-wotlk/modules
git clone https://github.com/buildthehomelab/wow-mod-swipe-fishing.git mod-swipe-fishing
```

Clone into `mod-swipe-fishing` exactly: AzerothCore derives the loader function's name from the
folder name. Re-run CMake, rebuild, and copy `conf/mod_swipe_fishing.conf.dist` to
`mod_swipe_fishing.conf` in your config folder. The world database SQL in
`data/sql/db-world/updates` runs automatically on the next worldserver start.

### Upgrading from older versions

- **From the gear version** (helm, pants, off-hand and Idol of Voracity):
  `mod_swipe_fishing_2026_09_26_04.sql` removes that gear and its quests, puts the reused items'
  original rows back, and adds the relics and their quests. The quests have new numbers, so
  druids who did the old chain can do the new one. The Idol of Voracity's item number becomes
  the Grand Master relic, the Voracious Salmon, so anyone who had the idol now has that (level 65
  to wear), without the idol's old effect. Anyone with the old helm, pants or off-hand keeps them
  as the original placeholder items.
- **From the pole-less idol version** that briefly replaced the minigame: if your server ran its
  SQL (`_01` and `_02`), `_03` and then `_04` bring the minigame back with the relics.

- **From the leaping-salmon version:** `_05` and `_06` stop the leap (the fish surfaces at your
  feet with a splash instead). In your `mod_swipe_fishing.conf`, `RequireRelic` and `RippleSpell`
  are gone (a relic is always needed), and `RageOnLeap` and `LeapSound` are now `RageOnBite` and
  `BiteSound`. Old names are ignored and the defaults apply. `CatchWindow` now counts from the
  splash; its default went from 1500 to 2000.

- **From the /roar version:** `mod_swipe_fishing_2026_09_28_00.sql` adds Salmon Run, puts it on
  the relics as their Use effect, and rewrites Tavar's first quest to match. Add `SwipeFishing.SpellId = 90060` to your
  `mod_swipe_fishing.conf`, and set `SwipeFishing.StartEmote = 0` there unless you want `/roar` to
  keep working too (the old conf has 75). Ship the new client patch before or with the server
  update.

Rebuild the worldserver either way: the C++ changed.

## Client patch

The 3.3.5 client only casts spells in its own `Spell.dbc`, and a patch MPQ replaces the whole
file, so Salmon Run has to go into the `Spell.dbc` your realm patch already ships.
`client/build_patch.py` adds it. It needs Python 3 and [StormLib](https://github.com/ladislav-zezula/StormLib):

```bash
python3 client/build_patch.py --from-mpq patch-P.MPQ --out patch-P.MPQ.new
```

That keeps everything else in the patch. If your realm has no patch with a `Spell.dbc` yet, start
from the client's own:

```bash
python3 client/build_patch.py --dbc Spell.dbc --out patch-P.MPQ
```

Players put the MPQ in `World of Warcraft/Data/`. Without it the relic has no Use line and
can't start fishing.

If you change the spell in the script, regenerate the server's row:

```bash
python3 client/build_patch.py --from-mpq patch-P.MPQ.new --sql
```

## Settings

Everything is in `mod_swipe_fishing.conf.dist`, with defaults:

| Setting | Default | What it does |
|---|---|---|
| `SwipeFishing.Enable` | 1 | Master switch for the minigame |
| `SwipeFishing.SpellId` | 90060 | Salmon Run, the relics' Use effect that starts and stops fishing; 0 for none |
| `SwipeFishing.StartEmote` | 0 | A text emote that also starts fishing (75 is `/roar`); 0 for none |
| `SwipeFishing.SitWhileWaiting` | 1 | The bear sits while it waits |
| `SwipeFishing.BiteDelayMin` / `Max` | 5000 / 15000 | Time until a salmon bites, in ms |
| `SwipeFishing.CatchWindow` | 2000 | How long after the splash you can Swipe, in ms |
| `SwipeFishing.SpookDelay` | 6000 | Extra wait after Swiping too early, in ms |
| `SwipeFishing.RageOnBite` | 25 | Rage a bite tops you up to |
| `SwipeFishing.MinCatchChance` | 50 | Lowest catch chance, in %; 0 for pure fishing rules |
| `SwipeFishing.CorpseSeconds` | 60 | How long a caught salmon stays for looting |
| `SwipeFishing.SpotDistance` | 4.5 | How far in front of you the salmon waits, in yards |
| `SwipeFishing.PoolReach` | 12 | A pool this close when you start is where the salmon waits |
| `SwipeFishing.BiteSound` / `SplashSpell` | 3355 / 69665 | Sound and visual of the bite, 0 for none |

## Turning it off

`SwipeFishing.Enable = 0` stops the minigame. The quests and relics stay.

To remove the module completely:

1. Delete the module folder and rebuild.
2. Run `data/sql/uninstall/mod_swipe_fishing_uninstall_world.sql` on the world database by hand;
   AzerothCore doesn't run it. It removes the creatures, quests, script bindings and Salmon Run,
   and restores the original rows of every item the module reused.

## Limits and untested parts

This is a prototype. It compiles against current AzerothCore, but it hasn't been run on a server
yet. Things to check in game:

- Tavar's spot comes from terrain data, not from standing there. If he's inside a rock or in the
  lake, move him with `.npc move`.
- Does the bear sit in shallow water, and does Swiping stand it up?
- Does the relic's Use line show, can it be used in Bear Form (and not outside it), and does the
  roar animation play before the bear sits?
- Is the 2 second window after the splash right?
- Does the water burst (69665) show well?
- Do the reused relic numbers show the right icon and equip in the relic slot in your client?

## License

MIT
