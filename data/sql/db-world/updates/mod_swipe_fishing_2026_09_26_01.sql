-- mod-swipe-fishing: one idol instead of the salmon minigame. Idempotent: safe to run again.
--
-- The module used to be a Swipe-the-leaping-salmon minigame with four pieces of gear and four
-- quests (the _00 file). Now the Idol of Voracity lets a druid fish without a pole, and one quest
-- gives it. This file takes the database from the old version to the new one, and a fresh install
-- runs _00 then this.
--
--   - Removes the salmon creatures (9500400, 9500401), quests 9500401-9500403 and the Swipe and
--     Bear Form script bindings.
--   - Quest 9500400 now asks for 10 Raw Bristle Whisker Catfish (caught at 55-130 fishing skill in
--     Ashenvale, Stonetalon, Wetlands, Hillsbrad, Redridge and Duskwood) and gives the idol.
--   - Items 3063, 3064 and 13842 (the old helm, pants and salmon off-hand) go back to their
--     original rows, as in AzerothCore's base data. Characters who had them keep the items as the
--     original placeholders.
--   - Item 25667 becomes the new Idol of Voracity.
--
-- Tavar Riverclaw (9500402, spawn 9500400) and his gossip stay from _00.

-- The salmon
DELETE FROM `creature_template` WHERE `entry` IN (9500400, 9500401);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9500400, 9500401);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (9500400, 9500401);

-- Scripts the module no longer has
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_swipe_fishing_swipe', 'spell_swipe_fishing_bear_form');

-- Quests: only the first stays, rewritten
DELETE FROM `quest_template` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `quest_template_addon` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `quest_request_items` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `quest_offer_reward` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `creature_queststarter` WHERE `quest` BETWEEN 9500400 AND 9500403;
DELETE FROM `creature_questender` WHERE `quest` BETWEEN 9500400 AND 9500403;

INSERT INTO `quest_template`
    (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `RewardXPDifficulty`, `RewardMoney`,
     `RewardItem1`, `RewardAmount1`, `RequiredItemId1`, `RequiredItemCount1`,
     `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`)
VALUES
    (9500400, 2, 20, 16, -263, 5, 1500,
     25667, 1, 6308, 10,
     'The Way of the Claw',
     'Bring 10 Raw Bristle Whisker Catfish to Tavar Riverclaw at Lake Elune''ara in Moonglade.',
     'A pole? A bobber? The bears of this lake never needed either, $N.$B$BBring me ten Raw Bristle Whisker Catfish and I''ll give you what my own teacher gave me: an idol that lets a druid fish with nothing but claws. The catfish swim in the rivers and lakes of Ashenvale and Stonetalon, or the Wetlands and Hillsbrad if you come from the east.$B$BYes, you''ll need a pole for these. It''s the last time, I promise.',
     'Return to Tavar Riverclaw at Lake Elune''ara in Moonglade.');

INSERT INTO `quest_template_addon` (`ID`, `AllowableClasses`, `PrevQuestID`, `RequiredSkillID`, `RequiredSkillPoints`)
VALUES (9500400, 1024, 0, 356, 1);

INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`)
VALUES (9500400, 1, 1, 'No catfish yet, $N? Pole in hand, and patience.');

INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`)
VALUES (9500400, 1, 'Good fish, and good fishing. Take the idol, and leave your pole in the bank.$B$BWith it on, you can fish with empty hands. Or take the shape of the bear, face the water and /roar, and the fish will come to you.');

INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (9500402, 9500400);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (9500402, 9500400);

DELETE FROM `npc_text` WHERE `ID` = 9500402;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang0`, `Probability0`)
VALUES (9500402,
    'The bears of this lake never needed a pole, $c. Why should you?',
    'The bears of this lake never needed a pole, $c. Why should you?',
    0, 0, 1);

-- The old gear back to the original rows
DELETE FROM `item_template` WHERE `entry` IN (3063, 3064, 13842);
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `name`, `displayid`, `Flags`, `FlagsExtra`, `BuyPrice`, `SellPrice`, `InventoryType`, `ItemLevel`, `RequiredLevel`, `delay`, `bonding`, `Material`, `VerifiedBuild`, `armor`, `MaxDurability`, `Quality`)
VALUES
    (3063, 4, 2, 'Deprecated Deepwood Helm', 13250, 16, 8192, 2593, 518, 1, 27, 22, 0, 2, 8, 15595, 0, 0, 0),
    (3064, 4, 2, 'Deprecated Deepwood Pants', 3205, 16, 0, 2791, 558, 7, 25, 20, 0, 2, 8, 1, 67, 60, 0),
    (13842, 15, 0, 'Fall/Winter Morning', 18705, 0, 0, 1500, 375, 23, 25, 0, 0, 0, -1, 1, 0, 0, 1);

-- The idol: druid relic, level 20, blue, bind on pickup, unique. "Increased Fishing +5" (7823) is
-- the item spell real fishing gear uses; the rest can't have an "Equip:" line without a client
-- patch, so the description says it.
DELETE FROM `item_template` WHERE `entry` = 25667;
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`,
     `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
     `maxcount`, `stackable`, `spellid_1`, `spelltrigger_1`, `bonding`, `description`, `Material`,
     `RequiredDisenchantSkill`, `VerifiedBuild`)
VALUES
    (25667, 4, 8, -1, 'Idol of Voracity', 40160, 3, 0,
     52268, 13067, 28, 1024, -1, 25, 20,
     1, 1, 7823, 1, 1, 'Fish without a fishing pole. In Bear Form, face the water and /roar to fish.', 2,
     -1, 0);
