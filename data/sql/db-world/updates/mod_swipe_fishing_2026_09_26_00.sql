-- mod-swipe-fishing: the salmon, the druid who teaches it, the quest chain, the gear and the
-- spell script bindings. Idempotent: safe to run again.
--
-- Entries (the user's modules live in the 9500000 range):
--   creature_template 9500400 Leaping Salmon and 9500401 Twenty-Six Pound Salmon (summoned by the
--   script, never spawned), 9500402 Tavar Riverclaw (quest giver); creature guid 9500400 (Tavar's
--   spawn); quests 9500400-9500403; gossip menu and npc_text 9500402.
--
-- The four items reuse Item.dbc entries players can't get in 3.3.5, so the client shows a fitting
-- icon and model without a patch: 3063 and 3064 (the "Deprecated Deepwood" helm and pants, green
-- leather), 13842 (an unused test fish, held like the real salmon) and 25667 (the TBC-replaced
-- "Idol of the Beast", a roaring bear icon). displayid must stay what the client has for them. The
-- uninstall SQL puts the original rows back.
--
-- Entry numbers must match src/SwipeFishing.cpp.

-- ---------------------------------------------------------------------------------------------
-- The salmon. Level 1, no XP, no loot of its own: the script fills its body with the zone's
-- fishing loot when it's caught. It never takes damage; the script kills it on a catch, and
-- NO_PLAYER_DAMAGE_REQ (0x200000) lets that kill give loot and quest credit. NO_XP is 0x40.
-- The model is the red "frenzy" fish of the Northrend Rainbow Trout (display 24637); the big one
-- uses a larger red frenzy display no creature uses (17533).
-- ---------------------------------------------------------------------------------------------

DELETE FROM `creature_template` WHERE `entry` IN (9500400, 9500401, 9500402);
INSERT INTO `creature_template`
    (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
     `speed_walk`, `speed_run`, `speed_swim`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`,
     `unit_flags2`, `type`, `HealthModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
    (9500400, 'Leaping Salmon', '', 0, 1, 1, 31, 0,
     1, 1.14286, 1, 2000, 2000, 1,
     2048, 1, 0.1, 1, 2097216, 'npc_swipe_fishing_salmon'),
    (9500401, 'Twenty-Six Pound Salmon', '', 0, 1, 1, 31, 0,
     1, 1.14286, 1, 2000, 2000, 1,
     2048, 1, 0.1, 1, 2097216, 'npc_swipe_fishing_salmon'),
    (9500402, 'Tavar Riverclaw', 'Druid of the Claw', 9500402, 30, 30, 35, 3,
     1, 1.14286, 1, 2000, 2000, 1,
     2048, 7, 1, 1, 0, '');

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9500400, 9500401, 9500402);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
    (9500400, 0, 24637, 1, 1),  -- Rainbow Trout's red frenzy fish
    (9500401, 0, 17533, 1, 1),  -- Larger red frenzy fish, unused
    (9500402, 0, 11772, 1, 1);  -- Tauren druid (Moren Riverbend's model)

DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (9500400, 9500401);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`)
VALUES
    (9500400, 0, 1, 0, 0, 0, 0),
    (9500401, 0, 1, 0, 0, 0, 0);

-- ---------------------------------------------------------------------------------------------
-- Tavar Riverclaw, on the south shore of Lake Elune'ara, about 130 yards south of Nighthaven,
-- facing the water. The spot comes from the terrain data, not from standing there: check it in game
-- with .gps and move him with .npc move if he's in a rock or in the lake.
-- ---------------------------------------------------------------------------------------------

-- The spawn row is a copy of Moren Riverbend's (guid 42335, a tauren druid in Nighthaven) with the
-- entry and position changed, so it fits whatever columns this server's `creature` table has.
-- Servers from before AzerothCore's multi-entry spawns call the entry column `id`, later ones `id1`;
-- this is written for `id`. On a newer server, change `id` to `id1` below.
DELETE FROM `creature` WHERE `guid` = 9500400;
DROP TEMPORARY TABLE IF EXISTS `tmp_swipe_fishing_spawn`;
CREATE TEMPORARY TABLE `tmp_swipe_fishing_spawn` SELECT * FROM `creature` WHERE `guid` = 42335;
UPDATE `tmp_swipe_fishing_spawn` SET
    `id`              = 9500402,
    `guid`            = 9500400,
    `position_x`      = 7847.9,
    `position_y`      = -2652.1,
    `position_z`      = 454.0,
    `orientation`     = 5.51,
    `equipment_id`    = 0,
    `MovementType`    = 0,
    `wander_distance` = 0;
INSERT INTO `creature` SELECT * FROM `tmp_swipe_fishing_spawn`;
DROP TEMPORARY TABLE `tmp_swipe_fishing_spawn`;

DELETE FROM `npc_text` WHERE `ID` = 9500402;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES (9500402,
    'The bears of this lake never needed a pole, $c. They wade in, they wait, and when the salmon leaps... one swipe. Sit with me a while.',
    'The bears of this lake never needed a pole, $c. They wade in, they wait, and when the salmon leaps... one swipe. Sit with me a while.',
    0, 0, 1);

DELETE FROM `gossip_menu` WHERE `MenuID` = 9500402;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`) VALUES (9500402, 9500402);

-- ---------------------------------------------------------------------------------------------
-- The quests. Druids only (class mask 1024), level 20, from level 16 (Swipe). The first needs
-- Fishing, so a druid without it never sees the chain.
--   9500400 The Way of the Claw     no objectives           -> Grizzly Helm
--   9500401 Salmon Run              5 Leaping Salmon        -> Fish Heart Pants
--   9500402 Twenty-Six Pounds       the big salmon          -> 26 Pound Salmon
--   9500403 A Voracious Appetite    8 Leaping Salmon        -> Idol of Voracity
-- The salmon count wherever they're caught, not just in Moonglade.
-- ---------------------------------------------------------------------------------------------

DELETE FROM `quest_template` WHERE `ID` BETWEEN 9500400 AND 9500403;
INSERT INTO `quest_template`
    (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `RewardXPDifficulty`, `RewardMoney`,
     `RewardItem1`, `RewardAmount1`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`,
     `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`)
VALUES
    (9500400, 2, 20, 16, -263, 1, 0,
     3063, 1, 0, 0, '',
     'The Way of the Claw',
     'Take the Grizzly Helm from Tavar Riverclaw at Lake Elune''ara in Moonglade.',
     'You fish with a pole and a bobber, $N? Like a hairless $r? Hah!$B$BThe bears of this lake taught me better. Put on this helm, take the shape of the bear, and wade in. Roar, so the salmon know you''ve come. Then sit, and wait, and watch the water.$B$BWhen one leaps, you Swipe. Not before, or you''ll only scare it off. Not after, or it flops back home.$B$BTake the helm. Then come back and show me.',
     'Return to Tavar Riverclaw at Lake Elune''ara in Moonglade.'),
    (9500401, 2, 20, 16, -263, 5, 1500,
     3064, 1, 9500400, 5, 'Leaping Salmon caught',
     'Salmon Run',
     'Catch 5 Leaping Salmon for Tavar Riverclaw at Lake Elune''ara in Moonglade.',
     'Now show me. Bear Form, the helm, water up to your knees. Or your paws. Roar, wait, and Swipe when the salmon leaps.$B$BAny water with fish in it will do; this lake is as good as any. Bring me five, and I''ll give you something to keep your legs warm while you stand in that cold water.',
     'Return to Tavar Riverclaw at Lake Elune''ara in Moonglade.'),
    (9500402, 2, 20, 16, -263, 5, 1500,
     13842, 1, 9500401, 1, 'Twenty-Six Pound Salmon caught',
     'Twenty-Six Pounds',
     'Catch the Twenty-Six Pound Salmon for Tavar Riverclaw at Lake Elune''ara in Moonglade.',
     'There''s one fish every angler on this lake talks about. Twenty-six pounds, they say, and meaner than a Timbermaw with a toothache.$B$BKeep fishing the way I taught you. Sooner or later something big will leap at you. When it does, don''t miss.',
     'Return to Tavar Riverclaw at Lake Elune''ara in Moonglade.'),
    (9500403, 2, 20, 16, -263, 5, 1500,
     25667, 1, 9500400, 8, 'Leaping Salmon caught',
     'A Voracious Appetite',
     'Catch 8 Leaping Salmon for Tavar Riverclaw at Lake Elune''ara in Moonglade.',
     'The young bears of the grove are hungry, and they eat more than I can catch. Eight more salmon should keep them quiet until morning.$B$BDo this, and I''ll give you the idol my own teacher gave me. With it the fish come to you even in a fight, as long as you''re standing in water.',
     'Return to Tavar Riverclaw at Lake Elune''ara in Moonglade.');

DELETE FROM `quest_template_addon` WHERE `ID` BETWEEN 9500400 AND 9500403;
INSERT INTO `quest_template_addon` (`ID`, `AllowableClasses`, `PrevQuestID`, `RequiredSkillID`, `RequiredSkillPoints`)
VALUES
    (9500400, 1024, 0,       356, 1),
    (9500401, 1024, 9500400, 0,   0),
    (9500402, 1024, 9500401, 0,   0),
    (9500403, 1024, 9500402, 0,   0);

DELETE FROM `quest_request_items` WHERE `ID` BETWEEN 9500400 AND 9500403;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`)
VALUES
    (9500401, 1, 1, 'Still dry, $N? The fish won''t jump into your paws on their own. Well, they will. But you have to be ready.'),
    (9500402, 1, 1, 'No? It''s out there. Keep fishing.'),
    (9500403, 1, 1, 'The cubs are still whining, $N.');

DELETE FROM `quest_offer_reward` WHERE `ID` BETWEEN 9500400 AND 9500403;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`)
VALUES
    (9500400, 1, 'Wear it well. A bear doesn''t need a pole, and neither do you.$B$BRemember: Bear Form, in the water, and roar.'),
    (9500401, 4, 'Five! Not bad for a cub. Here: the old druids stitched these from leather and luck. Every fish you catch will make you a little harder to knock over.'),
    (9500402, 5, 'By Ursoc, look at it! You caught it, you keep it. Hold it in your off hand, and when you Swipe with it, you''ll understand why the bears never let go of their fish.'),
    (9500403, 1, 'Quiet at last. Here, the Idol of Voracity. Swipe at your enemies while you stand in water, and now and then a salmon will leap in to join the fight. Catch it if you can.');

DELETE FROM `creature_queststarter` WHERE `quest` BETWEEN 9500400 AND 9500403;
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES (9500402, 9500400), (9500402, 9500401), (9500402, 9500402), (9500402, 9500403);

DELETE FROM `creature_questender` WHERE `quest` BETWEEN 9500400 AND 9500403;
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES (9500402, 9500400), (9500402, 9500401), (9500402, 9500402), (9500402, 9500403);

-- ---------------------------------------------------------------------------------------------
-- The gear: level 20, blue, bind on pickup. The equip lines use the item spells real fishing gear
-- has (7823 "Increased Fishing +5", 15956 "+3"). The module's own effects can't have "Equip:"
-- lines without a client patch, so the yellow description text says what they do.
-- stat types: 4 Strength, 6 Spirit, 7 Stamina, 38 Attack Power.
-- ---------------------------------------------------------------------------------------------

DELETE FROM `item_template` WHERE `entry` IN (3063, 3064, 13842, 25667);
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`,
     `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
     `maxcount`, `stackable`, `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `armor`,
     `spellid_1`, `spelltrigger_1`, `bonding`, `description`, `Material`, `MaxDurability`,
     `RequiredDisenchantSkill`, `VerifiedBuild`)
VALUES
    (3063, 4, 2, -1, 'Grizzly Helm', 13250, 3, 0,
     29684, 7421, 1, 1024, -1, 25, 20,
     0, 1, 6, 8, 7, 5, 72,
     7823, 1, 1, 'In Bear Form, stand in water and /roar to fish like a bear. Taking Bear Form grants +25 Fishing for 1 min.', 8, 50,
     -1, 0),
    (3064, 4, 2, -1, 'Fish Heart Pants', 3205, 3, 0,
     230452, 57613, 7, -1, -1, 25, 20,
     0, 1, 7, 8, 38, 16, 84,
     15956, 1, 1, 'Each fish you catch grants 5 Stamina for 1 min. Stacks up to 5 times.', 8, 65,
     -1, 0),
    (13842, 4, 0, -1, '26 Pound Salmon', 18705, 3, 0,
     21872, 5468, 23, -1, -1, 25, 20,
     0, 1, 4, 4, 7, 4, 0,
     0, 0, 1, 'Swipe deals 1 extra damage for every 5 Fishing skill.', -1, 0,
     -1, 0),
    (25667, 4, 8, -1, 'Idol of Voracity', 40160, 3, 0,
     52268, 13067, 28, 1024, -1, 25, 20,
     1, 1, 0, 0, 0, 0, 0,
     0, 0, 1, 'While you stand in water, Swipe has a chance to make a salmon leap at you.', 2, 0,
     -1, 0);

-- ---------------------------------------------------------------------------------------------
-- Spell scripts: every rank of Swipe (Bear), and Bear Form / Dire Bear Form. These spells keep
-- their other scripts (Bear Form's spell_dru_feral_swiftness).
-- ---------------------------------------------------------------------------------------------

DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_swipe_fishing_swipe', 'spell_swipe_fishing_bear_form');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES
    (779,   'spell_swipe_fishing_swipe'),
    (780,   'spell_swipe_fishing_swipe'),
    (769,   'spell_swipe_fishing_swipe'),
    (9754,  'spell_swipe_fishing_swipe'),
    (9908,  'spell_swipe_fishing_swipe'),
    (26997, 'spell_swipe_fishing_swipe'),
    (48561, 'spell_swipe_fishing_swipe'),
    (48562, 'spell_swipe_fishing_swipe'),
    (5487,  'spell_swipe_fishing_bear_form'),
    (9634,  'spell_swipe_fishing_bear_form');
