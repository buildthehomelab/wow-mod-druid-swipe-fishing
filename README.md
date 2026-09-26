# Swipe Fishing

An [AzerothCore](https://www.azerothcore.org/) (WotLK 3.3.5a) module: druids fish like bears. No
pole, no bobber, just claws. No client patch needed.

Put on a salmon relic, take Bear Form, wade into water and `/roar`. The bear sits and watches
the water. After a while a salmon leaps out and lands at your feet, and you have a moment to
**Swipe** it:

- **Hit it** and you catch it. The loot window opens with whatever normal fishing would give in
  that spot. If you close it, loot the salmon's body for the rest.
- **Swipe too early** and you scare it off for a few seconds.
- **Too late** and it flops back into the water.

The fishing goes on, one salmon after another, until you move, leave the water or leave Bear Form.

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

- Roar with a pool within 12 yards and the salmon waits in the middle of the pool instead of in
  front of you. A salmon from further out leaps faster, so every leap takes about the same time.
- A salmon that leapt out of a pool is a **sure catch**, and instead of a body to loot it opens
  the **pool's own loot**, like a bobber in a pool.
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

## Without a client patch

- **Swipe, not Fishing.** The 3.3.5 client refuses to cast Fishing in Bear Form or without a
  pole, so the druid never casts it: the salmon is a creature, and Swipe catches it.
- **Rage.** A bear out of combat has no rage, and Swipe costs 20. When a salmon leaps you're
  topped up to 25 rage, enough for one Swipe.
- **Items.** The client takes item icons from its own files, by item number, and a custom
  number would show a question mark. So the relics reuse idol numbers players can't get in 3.3.5:
  - 23004 and 42574, a green idol icon (Ossified and Fossilized Salmon).
  - 42576 and 42577, a nature idol icon (Petrified and Moonstone Salmon).
  - 25667, a removed TBC idol with a roaring bear icon (Voracious Salmon).

  The module's SQL rewrites their database rows. The uninstall SQL puts the originals back.
- **Tooltips.** The "Equip: Fishing skill increased by N" lines are the item spells real fishing
  gear uses.
- **Effects.** When a salmon leaps you hear the fishing bobber's bite sound and see a water burst.
  While a salmon waits it splashes now and then, so you can see where it is.

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

Rebuild the worldserver either way: the C++ changed.

## Settings

Everything is in `mod_swipe_fishing.conf.dist`, with defaults:

| Setting | Default | What it does |
|---|---|---|
| `SwipeFishing.Enable` | 1 | Master switch for the minigame |
| `SwipeFishing.StartEmote` | 75 | Text emote that starts fishing (75 = `/roar`) |
| `SwipeFishing.RequireRelic` | 1 | 0 lets any druid in Bear Form fish, relic or not |
| `SwipeFishing.SitWhileWaiting` | 1 | The bear sits while it waits |
| `SwipeFishing.BiteDelayMin` / `Max` | 5000 / 15000 | Time until a salmon leaps, in ms |
| `SwipeFishing.CatchWindow` | 1500 | How long a salmon lies at your feet, in ms |
| `SwipeFishing.SpookDelay` | 6000 | Extra wait after Swiping too early, in ms |
| `SwipeFishing.RageOnLeap` | 25 | Rage a leap tops you up to |
| `SwipeFishing.MinCatchChance` | 50 | Lowest catch chance, in %; 0 for pure fishing rules |
| `SwipeFishing.CorpseSeconds` | 60 | How long a caught salmon stays for looting |
| `SwipeFishing.SpotDistance` | 4.5 | How far in front of you the salmon waits, in yards |
| `SwipeFishing.PoolReach` | 12 | A pool this close when you roar is where the salmon waits |
| `SwipeFishing.LeapSound` / `SplashSpell` / `RippleSpell` | 3355 / 69665 / 69657 | Sound and visuals, 0 for none |

## Turning it off

`SwipeFishing.Enable = 0` stops the minigame. The quests and relics stay.

To remove the module completely:

1. Delete the module folder and rebuild.
2. Run `data/sql/uninstall/mod_swipe_fishing_uninstall_world.sql` on the world database by hand;
   AzerothCore doesn't run it. It removes the creatures, quests and script bindings, and restores
   the original rows of every item the module reused.

## Limits and untested parts

This is a prototype. It compiles against current AzerothCore, but it hasn't been run on a server
yet. Things to check in game:

- Tavar's spot comes from terrain data, not from standing there. If he's inside a rock or in the
  lake, move him with `.npc move`.
- Does the bear sit in shallow water, and does Swiping stand it up?
- Do the leap arc, the landing spot and the 1.5 second window feel right?
- Is the red "frenzy" fish model (the Northrend Rainbow Trout's) salmon-like enough?
- Does the water burst visual (69665) show in the 3.3.5 client?
- Do the reused relic numbers show the right icon and equip in the relic slot in your client?

## License

MIT
