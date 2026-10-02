-- mod-druid-swipe-fishing: uninstall, world database. Not run automatically: AzerothCore only runs a
-- module's SQL from data/sql/db-world and similar folders. Run it by hand after removing the module.
--
-- Removes the salmon, Tavar Riverclaw and his spawn, the quests and the spell script bindings, and
-- puts back the original rows of the reused items (the old gear and the relics), as in
-- AzerothCore's base data.
-- Characters keep quest progress and the items they already have; those items go back to being the
-- original placeholder items.

DELETE FROM `creature_template` WHERE `entry` IN (9500400, 9500401, 9500402);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9500400, 9500401, 9500402);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (9500400, 9500401); -- From the first version of the SQL
DELETE FROM `creature` WHERE `guid` = 9500400;
DELETE FROM `npc_text` WHERE `ID` = 9500402;
DELETE FROM `gossip_menu` WHERE `MenuID` = 9500402;
DELETE FROM `quest_template` WHERE `ID` BETWEEN 9500400 AND 9500408;
DELETE FROM `quest_template_addon` WHERE `ID` BETWEEN 9500400 AND 9500408;
DELETE FROM `quest_request_items` WHERE `ID` BETWEEN 9500400 AND 9500408;
DELETE FROM `quest_offer_reward` WHERE `ID` BETWEEN 9500400 AND 9500408;
DELETE FROM `creature_queststarter` WHERE `quest` BETWEEN 9500400 AND 9500408;
DELETE FROM `creature_questender` WHERE `quest` BETWEEN 9500400 AND 9500408;
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_swipe_fishing_swipe', 'spell_swipe_fishing_bear_form');

DELETE FROM `item_template` WHERE `entry` IN (3063, 3064, 13842, 25667, 23004, 42574, 42576, 42577);
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`,
    `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`,
    `AllowableRace`, `ItemLevel`, `RequiredLevel`, `RequiredSkill`, `RequiredSkillRank`,
    `requiredspell`, `requiredhonorrank`, `RequiredCityRank`, `RequiredReputationFaction`,
    `RequiredReputationRank`, `maxcount`, `stackable`, `ContainerSlots`, `stat_type1`, `stat_value1`,
    `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`, `stat_type5`,
    `stat_value5`, `stat_type6`, `stat_value6`, `stat_type7`, `stat_value7`, `stat_type8`,
    `stat_value8`, `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`,
    `ScalingStatDistribution`, `ScalingStatValue`, `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`,
    `dmg_max2`, `dmg_type2`, `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`,
    `arcane_res`, `delay`, `ammo_type`, `RangedModRange`, `spellid_1`, `spelltrigger_1`,
    `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`,
    `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`,
    `spellcategory_2`, `spellcategorycooldown_2`, `spellid_3`, `spelltrigger_3`, `spellcharges_3`,
    `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`, `spellid_4`,
    `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`,
    `spellcategorycooldown_4`, `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`,
    `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`, `bonding`, `description`,
    `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`,
    `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`,
    `TotemCategory`, `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`,
    `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`,
    `ArmorDamageModifier`, `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`,
    `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`)
VALUES
(3063,4,2,-1,'Deprecated Deepwood Helm',13250,0,16,8192,1,2593,518,1,-1,-1,27,22,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,2,'',0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,0,0,'',0,0,0,0,0,15595),
(3064,4,2,-1,'Deprecated Deepwood Pants',3205,0,16,0,1,2791,558,7,-1,-1,25,20,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,67,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,2,'',0,0,0,0,0,8,0,0,0,0,0,60,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,0,0,'',0,0,0,0,0,1),
(13842,15,0,-1,'Fall/Winter Morning',18705,1,0,0,1,1500,375,23,-1,-1,25,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,'',0,0,0,0,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,0,0,'',0,0,0,0,0,1),
(25667,4,8,-1,'ObsoleteIdol of the Beast',40160,3,0,8192,1,94198,18839,28,32767,-1,79,64,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,32410,1,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,1,'',0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,14,0,0,0,0,0,0,0,-1,0,0,0,0,'',0,0,0,0,0,15595),
(23004,4,8,-1,'Idol of Longevity',34953,4,0,0,1,125795,25159,28,32767,-1,83,60,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,28847,1,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,1,'',0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,225,0,0,0,0,'',65,0,0,0,0,12340),
(42574,4,8,-1,'Savage Gladiator''s Idol of Resolve',34953,3,36864,0,1,0,0,28,-1,-1,200,80,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,60693,1,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,1,'',0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,0,0,'',0,0,0,0,0,1),
(42576,4,8,-1,'Savage Gladiator''s Idol of Tenacity',9659,3,36864,0,1,0,0,28,-1,-1,200,80,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,60733,1,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,1,'',0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,0,0,'',0,0,0,0,0,1),
(42577,4,8,-1,'Hateful Gladiator''s Idol of Tenacity',9659,4,0,0,1,0,0,28,-1,-1,200,80,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,60736,1,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,1,'',0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,0,0,'',0,0,0,0,0,1);

-- Salmon Run, the relics' Use effect (from mod_druid_swipe_fishing_2026_09_28_00.sql). The relic rows
-- above are restored whole, so they lose it too.
DELETE FROM `spell_dbc` WHERE `ID` = 90060;
