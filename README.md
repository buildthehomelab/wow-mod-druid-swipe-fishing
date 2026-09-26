# Swipe Fishing

An [AzerothCore](https://www.azerothcore.org/) (WotLK 3.3.5a) module: druids fish in Bear Form. No
client patch needed.

With the **Idol of Voracity** in the relic slot, a druid in **Bear Form** faces the water and types
**`/roar`**, and Fishing starts, with no pole. The 3.3.5 client never lets you cast Fishing yourself
while shapeshifted, and a bear can't hold a pole anyway.

It's the normal Fishing spell: your best rank, a real bobber you click, fishing pools, skill-ups
and the zone's loot, all as usual. **In caster form nothing changes:** Fishing needs a pole and
looks as it always does.

## Getting the idol

**Tavar Riverclaw** <Druid of the Claw>, a tauren druid on the south shore of Lake Elune'ara in
Moonglade, a short walk south of Nighthaven, gives one quest to druids who know Fishing (level 16
or higher):

**The Way of the Claw**: bring him 10 **Raw Bristle Whisker Catfish**. You'll need a pole for these
one last time. They bite at 55 to 130 fishing skill in the rivers and lakes of Ashenvale,
Stonetalon, the Wetlands, Hillsbrad, Redridge and Duskwood.

## The idol

**Idol of Voracity**: relic, druid only, level 20, blue, bind on pickup, unique. **Equip: Increased
Fishing +5.** Its yellow description says the rest: in Bear Form, face the water and `/roar`.

## How it works

- **The pole rule.** The core checks for a pole in a way no script or trigger flag can skip, even
  when the server casts Fishing itself. So at startup the module takes the requirement off every
  Fishing rank and checks it itself instead: a pole in the main hand, or Bear Form with the idol.
  Without either, you get the same "Requires Fishing Pole" error as before.
- **Bear Form.** `/roar` makes the server cast your best Fishing rank for you, skipping the check
  for shapeshift forms. The usual Fishing checks still apply, such as water in front of you, and
  their errors show as usual.
- **The item.** The client takes item icons from its own files, by item number, so the idol reuses
  an item number players can't get in 3.3.5: 25667, the old "Idol of the Beast" that TBC replaced,
  with a roaring bear icon. The SQL rewrites its database row, and the uninstall SQL puts the
  original back.

## Install

```bash
cd azerothcore-wotlk/modules
git clone https://github.com/buildthehomelab/wow-mod-swipe-fishing.git mod-swipe-fishing
```

Clone into `mod-swipe-fishing` exactly: AzerothCore derives the loader function's name from the
folder name. Re-run CMake, rebuild, and copy `conf/mod_swipe_fishing.conf.dist` to
`mod_swipe_fishing.conf` in your config folder. The world database SQL in
`data/sql/db-world/updates` runs automatically on the next worldserver start.

Tavar's spawn row is copied from an existing one and sets the creature's entry in a column named
`id`, as on AzerothCore builds from before multi-entry spawns. On a newer build, where the column is
`id1`, change it in `mod_swipe_fishing_2026_09_26_00.sql`.

### Upgrading from the salmon minigame version

The first version was a Swipe-the-leaping-salmon minigame with four pieces of gear and four quests.
`mod_swipe_fishing_2026_09_26_01.sql` removes all of that:

- It deletes the salmon creatures and the three extra quests, and rewrites the first quest.
- It restores the helm, pants and salmon off-hand items (3063, 3064, 13842) to their original rows.
  Characters who had them keep them as the original placeholder items.

Rebuild the worldserver: the C++ changed.

## Settings

| Setting | Default | What it does |
|---|---|---|
| `SwipeFishing.Enable` | 1 | 0: the idol does nothing |
| `SwipeFishing.StartEmote` | 75 | Text emote that casts Fishing in Bear Form with the idol on (75 = `/roar`) |

## Turning it off

`SwipeFishing.Enable = 0` makes the idol do nothing: no fishing in Bear Form. The quest and item
stay.

To remove the module completely:

1. Delete the module folder and rebuild.
2. Run `data/sql/uninstall/mod_swipe_fishing_uninstall_world.sql` on the world database by hand;
   AzerothCore doesn't run it. It removes Tavar, the quest and anything left from the minigame
   version, and restores the reused items' original rows.

## Limits and untested parts

It compiles against current AzerothCore but hasn't been tested in game yet.

- **Clicking the bobber in Bear Form.** Druids can loot in forms, so this should work, but it's
  untested.
- **The bear's look while fishing.** The bear model has no fishing animation and can't show a
  pole, so the client plays some other animation, probably just standing, while the bobber floats.
  A real fishing animation would need a client patch with an edited bear model.
- **Unequipping mid-cast.** Taking off the pole or the idol mid-cast no longer cancels the fishing
  channel, because Fishing no longer lists a required item.
- **Tavar's spot.** It comes from terrain data, not from standing there. If he's inside a rock or in
  the lake, move him with `.npc move`.

## License

MIT
