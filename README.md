# Swipe Fishing

An [AzerothCore](https://www.azerothcore.org/) (WotLK 3.3.5a) module: druids fish like bears. No
pole, no bobber, just claws. No client patch needed.

Put on the Grizzly Helm, take Bear Form, wade into water and `/roar`. The bear sits and watches
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
- The Idol of Voracity's salmon also come out of a nearby pool if there is one.

## The quest chain

**Tavar Riverclaw** <Druid of the Claw>, a tauren druid on the south shore of Lake Elune'ara in
Moonglade, a short walk south of Nighthaven. Every druid can get there with Teleport: Moonglade.
The quests are for druids of level 16 or higher (when Swipe is learned) who know Fishing, and are
level 20.

| Quest | Objective | Reward |
|---|---|---|
| The Way of the Claw | None: he explains how | Grizzly Helm |
| Salmon Run | Catch 5 Leaping Salmon | Fish Heart Pants |
| Twenty-Six Pounds | Catch the Twenty-Six Pound Salmon | 26 Pound Salmon |
| A Voracious Appetite | Catch 8 Leaping Salmon | Idol of Voracity |

The salmon count wherever you catch them, not only in Moonglade. While "Twenty-Six Pounds" is in
your quest log, each fish has a 20% chance to be the big one.

## The gear

All blue, bind on pickup, level 20.

| Item | Slot | Stats | Effect |
|---|---|---|---|
| Grizzly Helm | Head, leather, druid | 72 armor, +8 Spirit, +5 Stamina, +5 Fishing | Needed to fish at all. Taking Bear Form gives +25 Fishing for 1 minute. |
| Fish Heart Pants | Legs, leather | 84 armor, +8 Stamina, +16 Attack Power, +3 Fishing | Each catch gives +5 Stamina for 1 minute, stacking up to 5 times. |
| 26 Pound Salmon | Held in off-hand | +4 Strength, +4 Stamina | Swipe deals 1 extra damage per 5 fishing skill, to every target. |
| Idol of Voracity | Relic, druid | | While you stand in water, each Swipe that hits an enemy has a 15% chance to make a salmon leap at you, in combat too. Catch it with another Swipe. |

The 26 Pound Salmon makes Swipe much stronger at level 20: rank 1 Swipe does 9 damage plus about
6% of attack power, and with 150 fishing skill the fish adds 30 to each target.

## Without a client patch

- **Swipe, not Fishing.** The 3.3.5 client refuses to cast Fishing in Bear Form or without a
  pole, so the druid never casts it: the salmon is a creature, and Swipe catches it.
- **Rage.** A bear out of combat has no rage, and Swipe costs 20. When a salmon leaps you're
  topped up to 25 rage, enough for one Swipe.
- **Items.** The client takes item icons and models from its own files, by item number. The four
  items reuse numbers players can't get in 3.3.5, with fitting looks:
  - 3063 and 3064: an old green leather helm and pants.
  - 13842: an unused test fish, held like the real salmon.
  - 25667: a removed TBC idol with a roaring bear icon.

  The module's SQL rewrites their database rows. The uninstall SQL puts the originals back.
- **Tooltips.** Item effects that aren't stock spells can't have green "Equip:" lines, so each
  item's yellow description says what it does. The +5 and +3 Fishing are real item spells.
- **Buffs.** The helm's fishing buff shows as "Captain Rumsey's Lager", and the pants' stamina
  buff as "Invigorated". Both are buffs the client already has, but their tooltips show the
  client's own numbers (+10 Fishing, +24 Stamina per stack), not the real ones. Both buffs
  disappear on logout.
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

### Back from the idol version

For a while this module was a single idol that let a bear cast Fishing without a pole. That
version is gone and the salmon minigame is back. If your server ran its SQL (`_01` and `_02`),
`mod_swipe_fishing_2026_09_26_03.sql` puts the salmon, the quest chain and the gear back on the
next start. Rebuild the worldserver: the C++ changed.

## Settings

Everything is in `mod_swipe_fishing.conf.dist`, with defaults:

| Setting | Default | What it does |
|---|---|---|
| `SwipeFishing.Enable` | 1 | Master switch for the minigame and the gear's effects |
| `SwipeFishing.StartEmote` | 75 | Text emote that starts fishing (75 = `/roar`) |
| `SwipeFishing.RequireHelm` | 1 | 0 lets any druid in Bear Form fish |
| `SwipeFishing.SitWhileWaiting` | 1 | The bear sits while it waits |
| `SwipeFishing.BiteDelayMin` / `Max` | 5000 / 15000 | Time until a salmon leaps, in ms |
| `SwipeFishing.CatchWindow` | 1500 | How long a salmon lies at your feet, in ms |
| `SwipeFishing.SpookDelay` | 6000 | Extra wait after Swiping too early, in ms |
| `SwipeFishing.RageOnLeap` | 25 | Rage a leap tops you up to |
| `SwipeFishing.MinCatchChance` | 50 | Lowest catch chance, in %; 0 for pure fishing rules |
| `SwipeFishing.CorpseSeconds` | 60 | How long a caught salmon stays for looting |
| `SwipeFishing.SpotDistance` | 4.5 | How far in front of you the salmon waits, in yards |
| `SwipeFishing.PoolReach` | 12 | A pool this close when you roar is where the salmon waits |
| `SwipeFishing.BigFishChance` | 20 | Chance of the Twenty-Six Pound Salmon while its quest is open |
| `SwipeFishing.Salmon.SkillPerDamage` | 5 | Fishing skill per point of extra Swipe damage |
| `SwipeFishing.Helm.SkillBonus` / `Duration` | 25 / 60000 | Fishing buff on taking Bear Form |
| `SwipeFishing.Pants.Stamina` / `MaxStacks` / `Duration` | 5 / 5 / 60000 | Stamina buff per catch |
| `SwipeFishing.Idol.Chance` | 15 | Chance per Swipe in water for a salmon to leap |
| `SwipeFishing.LeapSound` / `SplashSpell` / `RippleSpell` | 3355 / 69665 / 69657 | Sound and visuals, 0 for none |

The item descriptions have the default numbers written in. If you change the gear settings, change
the descriptions in the SQL too.

## Turning it off

`SwipeFishing.Enable = 0` stops the minigame and the gear's effects. The quests and items stay.

To remove the module completely:

1. Delete the module folder and rebuild.
2. Run `data/sql/uninstall/mod_swipe_fishing_uninstall_world.sql` on the world database by hand;
   AzerothCore doesn't run it. It removes the creatures, quests and script bindings, and restores
   the four original item rows.

## Limits and untested parts

This is a prototype. It compiles against current AzerothCore, but it hasn't been run on a server
yet. Things to check in game:

- Tavar's spot comes from terrain data, not from standing there. If he's inside a rock or in the
  lake, move him with `.npc move`.
- Does the bear sit in shallow water, and does Swiping stand it up?
- Do the leap arc, the landing spot and the 1.5 second window feel right?
- Is the red "frenzy" fish model (the Northrend Rainbow Trout's) salmon-like enough?
- Does the water burst visual (69665) show in the 3.3.5 client?
- "Invigorated" is also the buff of an Icecrown Citadel tank trinket. A druid wearing that trinket
  and the pants could see the two mix up.
- Party members near you also get quest credit for your salmon, like any kill.

## License

MIT
