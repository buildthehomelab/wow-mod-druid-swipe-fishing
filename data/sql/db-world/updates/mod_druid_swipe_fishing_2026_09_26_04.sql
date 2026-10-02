-- mod-swipe-fishing: the gear becomes one relic that grows with your fishing. Idempotent: safe to
-- run again.
--
-- The minigame stays; the helm, pants, off-hand and Idol of Voracity go, and so do their effects.
-- In their place, one salmon relic per fishing rank, Journeyman to Grand Master: Stamina and
-- fishing skill, nothing else. Wearing any of them is what lets a druid fish in Bear Form.
--
--   - Removes the Twenty-Six Pound Salmon (9500401), the old quests 9500400-9500403 and the Bear
--     Form script binding.
--   - Items 3063, 3064 and 13842 (the old helm, pants and off-hand) go back to their original rows,
--     as in AzerothCore's base data. Characters who had them keep them as the original placeholders.
--   - Five relics, reusing Item.dbc idols players can't get, so the client shows an idol icon
--     without a patch. displayid must stay what the client has for them. The uninstall SQL puts the
--     original rows back.
--   - New quests 9500404-9500408: Tavar gives the first relic, then trades each one for the next
--     when the druid can train the next fishing rank. New IDs, so druids who did the old chain
--     still get this one. The last relic, the Voracious Salmon, is item 25667, the old Idol of
--     Voracity, so a character who had the idol now has the Grand Master relic (level 65 to wear).
--
-- Entry numbers must match src/SwipeFishing.cpp.

-- The big salmon and the Bear Form buff are gone
DELETE FROM `creature_template` WHERE `entry` = 9500401;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9500401;
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 9500401;
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_swipe_fishing_bear_form';

-- The old quests
DELETE FROM `quest_template` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `quest_template_addon` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `quest_request_items` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `quest_offer_reward` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `creature_queststarter` WHERE `quest` BETWEEN 9500400 AND 9500403;
DELETE FROM `creature_questender` WHERE `quest` BETWEEN 9500400 AND 9500403;

-- The old gear back to the original rows
DELETE FROM `item_template` WHERE `entry` IN (3063, 3064, 13842);
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `name`, `displayid`, `Flags`, `FlagsExtra`, `BuyPrice`, `SellPrice`, `InventoryType`, `ItemLevel`, `RequiredLevel`, `delay`, `bonding`, `Material`, `VerifiedBuild`, `armor`, `MaxDurability`, `Quality`)
VALUES
    (3063, 4, 2, 'Deprecated Deepwood Helm', 13250, 16, 8192, 2593, 518, 1, 27, 22, 0, 2, 8, 15595, 0, 0, 0),
    (3064, 4, 2, 'Deprecated Deepwood Pants', 3205, 16, 0, 2791, 558, 7, 25, 20, 0, 2, 8, 1, 67, 60, 0),
    (13842, 15, 0, 'Fall/Winter Morning', 18705, 0, 0, 1500, 375, 23, 25, 0, 0, 0, -1, 1, 0, 0, 1);

-- ---------------------------------------------------------------------------------------------
-- The relics: druid idols, bind on pickup, unique. Level and stats follow the fishing rank each
-- one belongs to. The "Equip: Fishing skill increased by N" lines are the item spells real fishing
-- gear uses: 7823 +5, 7825 +15, 7826 +20, 8082 +25, 59731 +30 (there is no +10).
-- stat_type 7 is Stamina.
--   23004 Ossified Salmon    Journeyman    level 16  +5 Stamina   +5 Fishing   (green idol icon)
--   42574 Fossilized Salmon  Expert        level 20  +10 Stamina  +15 Fishing  (green idol icon)
--   42576 Petrified Salmon   Artisan       level 35  +15 Stamina  +20 Fishing  (nature idol icon)
--   42577 Moonstone Salmon   Master        level 50  +20 Stamina  +25 Fishing  (nature idol icon)
--   25667 Voracious Salmon   Grand Master  level 65  +25 Stamina  +30 Fishing  (bear roar icon)
-- The Voracious Salmon is the gear version's Idol of Voracity, renamed. Its old effect (salmon
-- leaping in during fights) is gone.
-- ---------------------------------------------------------------------------------------------

DELETE FROM `item_template` WHERE `entry` IN (23004, 42574, 42576, 42577, 25667);
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`,
     `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
     `maxcount`, `stackable`, `stat_type1`, `stat_value1`, `spellid_1`, `spelltrigger_1`, `bonding`,
     `description`, `Material`, `RequiredDisenchantSkill`, `VerifiedBuild`)
VALUES
    (23004, 4, 8, -1, 'Ossified Salmon', 34953, 3, 0,
     8000, 2000, 28, 1024, -1, 20, 16,
     1, 1, 7, 5, 7823, 1, 1,
     'The roar of the bear scares away most. But the proud salmon is called, to be swept up in mighty claws', 2, -1, 0),
    (42574, 4, 8, -1, 'Fossilized Salmon', 34953, 3, 0,
     16000, 4000, 28, 1024, -1, 30, 20,
     1, 1, 7, 10, 7825, 1, 1,
     'Years in the riverbed turned its bones to stone. The salmon still answer when it calls.', 2, -1, 0),
    (42576, 4, 8, -1, 'Petrified Salmon', 9659, 3, 0,
     40000, 10000, 28, 1024, -1, 45, 35,
     1, 1, 7, 15, 7826, 1, 1,
     'It leapt one waterfall too many, and the mountain kept it.', 2, -1, 0),
    (42577, 4, 8, -1, 'Moonstone Salmon', 9659, 3, 0,
     80000, 20000, 28, 1024, -1, 60, 50,
     1, 1, 7, 20, 8082, 1, 1,
     'Elune''s light swims in it still. Salmon rise to meet it.', 2, -1, 0),
    (25667, 4, 8, -1, 'Voracious Salmon', 40160, 4, 0,
     160000, 40000, 28, 1024, -1, 75, 65,
     1, 1, 7, 25, 59731, 1, 1,
     'Ursoc fished these waters before there were druids to watch him. Nothing that swims has forgotten his hunger.', 2, -1, 0);

-- ---------------------------------------------------------------------------------------------
-- The quests, from Tavar Riverclaw. Druids only (class mask 1024). Each opens when the druid can
-- train the next fishing rank: fishing skill 50, 125, 200, 275, 350, and the character level that
-- rank needs. The upgrades take the old relic, even while it's equipped.
--   9500404 The Way of the Claw     skill 50,  level 16  -> Ossified Salmon
--   9500405 Stone and Scale         skill 125, level 20  Ossified Salmon    -> Fossilized Salmon
--   9500406 The Mountain's Catch    skill 200, level 35  Fossilized Salmon  -> Petrified Salmon
--   9500407 Under Elune's Light     skill 275, level 50  Petrified Salmon   -> Moonstone Salmon
--   9500408 The Old Bear's River    skill 350, level 65  Moonstone Salmon   -> Voracious Salmon
-- ---------------------------------------------------------------------------------------------

DELETE FROM `quest_template` WHERE `ID` BETWEEN 9500404 AND 9500408;
INSERT INTO `quest_template`
    (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `RewardXPDifficulty`, `RewardMoney`,
     `RewardItem1`, `RewardAmount1`, `RequiredItemId1`, `RequiredItemCount1`,
     `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`)
VALUES
    (9500404, 2, 20, 16, -263, 1, 0,
     23004, 1, 0, 0,
     'The Way of the Claw',
     'Take the Ossified Salmon from Tavar Riverclaw at Lake Elune''ara in Moonglade.',
     'You fish with a pole and a bobber, $N? Like a hairless $r? Hah!$B$BThe bears of this lake taught me better. Wear this old salmon bone, take the shape of the bear, and wade in. Roar, so the salmon know you''ve come. Then sit, and wait, and watch the water.$B$BWhen one leaps, you Swipe. Not before, or you''ll only scare it off. Not after, or it flops back home.$B$BCome back to me as your fishing grows. The bone grows with you.',
     'Return to Tavar Riverclaw at Lake Elune''ara in Moonglade.'),
    (9500405, 2, 25, 20, -263, 1, 0,
     42574, 1, 23004, 1,
     'Stone and Scale',
     'Bring the Ossified Salmon to Tavar Riverclaw at Lake Elune''ara in Moonglade.',
     'The water knows you now, $N. I can see it in the way you stand in it.$B$BGive me the salmon bone. The riverbed has been keeping something harder for a fisher like you.',
     'Return to Tavar Riverclaw at Lake Elune''ara in Moonglade.'),
    (9500406, 2, 40, 35, -263, 1, 0,
     42576, 1, 42574, 1,
     'The Mountain''s Catch',
     'Bring the Fossilized Salmon to Tavar Riverclaw at Lake Elune''ara in Moonglade.',
     'You''ve fished rivers I''ve only heard of, $N. Your old stone fish is too light for those paws now.$B$BHand it over. There''s a salmon that leapt one waterfall too many, and the mountain kept it. It''s yours.',
     'Return to Tavar Riverclaw at Lake Elune''ara in Moonglade.'),
    (9500407, 2, 55, 50, -263, 1, 0,
     42577, 1, 42576, 1,
     'Under Elune''s Light',
     'Bring the Petrified Salmon to Tavar Riverclaw at Lake Elune''ara in Moonglade.',
     'Few fishers ever reach where you stand, $N. Fewer still with claws.$B$BLeave the stone fish with me tonight. Under Elune''s light, it will become something better.',
     'Return to Tavar Riverclaw at Lake Elune''ara in Moonglade.'),
    (9500408, 2, 70, 65, -263, 1, 0,
     25667, 1, 42577, 1,
     'The Old Bear''s River',
     'Bring the Moonstone Salmon to Tavar Riverclaw at Lake Elune''ara in Moonglade.',
     'There''s nothing left for me to teach you, $N. So I''ll tell you a story instead.$B$BBefore there were druids, Ursoc himself fished these waters, and nothing that swam was safe from his hunger. When he left, the salmon kept one of his catches, and it has been hungry ever since. Give me the moonstone, and I''ll give you the Voracious Salmon.',
     'Return to Tavar Riverclaw at Lake Elune''ara in Moonglade.');

DELETE FROM `quest_template_addon` WHERE `ID` BETWEEN 9500404 AND 9500408;
INSERT INTO `quest_template_addon` (`ID`, `AllowableClasses`, `PrevQuestID`, `RequiredSkillID`, `RequiredSkillPoints`)
VALUES
    (9500404, 1024, 0,       356, 50),
    (9500405, 1024, 9500404, 356, 125),
    (9500406, 1024, 9500405, 356, 200),
    (9500407, 1024, 9500406, 356, 275),
    (9500408, 1024, 9500407, 356, 350);

DELETE FROM `quest_request_items` WHERE `ID` BETWEEN 9500404 AND 9500408;
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`)
VALUES
    (9500405, 1, 1, 'The salmon bone, $N. I need it back before I can give you the next.'),
    (9500406, 1, 1, 'Where''s your stone fish, $N?'),
    (9500407, 1, 1, 'Bring me the petrified salmon, $N.'),
    (9500408, 1, 1, 'The moonstone, $N. Then the story ends the way it should.');

DELETE FROM `quest_offer_reward` WHERE `ID` BETWEEN 9500404 AND 9500408;
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`)
VALUES
    (9500404, 1, 'Wear it well. A bear doesn''t need a pole, and neither do you.$B$BRemember: Bear Form, in the water, and roar.'),
    (9500405, 1, 'Stone now, and heavier. The fish will feel it.'),
    (9500406, 4, 'The mountain gave it up without a fight. I think it wanted you to have it.'),
    (9500407, 2, 'See how it shines? The salmon will see it too, from a long way off.'),
    (9500408, 5, 'The Voracious Salmon. Wear it, $N, and every river on Azeroth is your lake.');

DELETE FROM `creature_queststarter` WHERE `quest` BETWEEN 9500404 AND 9500408;
INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES (9500402, 9500404), (9500402, 9500405), (9500402, 9500406), (9500402, 9500407), (9500402, 9500408);

DELETE FROM `creature_questender` WHERE `quest` BETWEEN 9500404 AND 9500408;
INSERT INTO `creature_questender` (`id`, `quest`)
VALUES (9500402, 9500404), (9500402, 9500405), (9500402, 9500406), (9500402, 9500407), (9500402, 9500408);
