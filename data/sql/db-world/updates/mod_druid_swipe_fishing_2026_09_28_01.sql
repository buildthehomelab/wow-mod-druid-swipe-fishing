-- mod-druid-swipe-fishing: the salmon always swims. Idempotent: safe to run again.
--
-- The core decides on its own whether a creature swims, and in shallow water it said no: the fish
-- then stood upright in its idle pose and poked out of the surface. CREATURE_FLAG_EXTRA_NO_MOVE_FLAGS_UPDATE
-- (0x200) makes the core leave the salmon's movement flags alone; the script sets it swimming.

UPDATE `creature_template`
SET `flags_extra` = `flags_extra` | 512
WHERE `entry` = 9500400;
