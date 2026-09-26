-- mod-swipe-fishing: uninstall, world database. Not run automatically: AzerothCore only runs a
-- module's SQL from data/sql/db-world and similar folders. Run it by hand after removing the module.
--
-- Removes Tavar Riverclaw, his spawn and gossip, the quest, and anything left from the old salmon
-- minigame version, and puts back the original rows of the reused items (25667, and 3063, 3064 and
-- 13842 from the old version), as in AzerothCore's base data. Characters keep quest progress and
-- the idol; it goes back to being the original placeholder item.

DELETE FROM `creature_template` WHERE `entry` IN (9500400, 9500401, 9500402);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9500400, 9500401, 9500402);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (9500400, 9500401);
DELETE FROM `creature` WHERE `guid` = 9500400;
DELETE FROM `npc_text` WHERE `ID` = 9500402;
DELETE FROM `gossip_menu` WHERE `MenuID` = 9500402;
DELETE FROM `quest_template` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `quest_template_addon` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `quest_request_items` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `quest_offer_reward` WHERE `ID` BETWEEN 9500400 AND 9500403;
DELETE FROM `creature_queststarter` WHERE `quest` BETWEEN 9500400 AND 9500403;
DELETE FROM `creature_questender` WHERE `quest` BETWEEN 9500400 AND 9500403;
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_swipe_fishing_swipe', 'spell_swipe_fishing_bear_form');

DELETE FROM `item_template` WHERE `entry` IN (3063, 3064, 13842, 25667);
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `name`, `displayid`, `Flags`, `FlagsExtra`, `BuyPrice`, `SellPrice`, `InventoryType`, `ItemLevel`, `RequiredLevel`, `delay`, `bonding`, `Material`, `VerifiedBuild`, `armor`, `MaxDurability`, `Quality`)
VALUES
    (3063, 4, 2, 'Deprecated Deepwood Helm', 13250, 16, 8192, 2593, 518, 1, 27, 22, 0, 2, 8, 15595, 0, 0, 0),
    (3064, 4, 2, 'Deprecated Deepwood Pants', 3205, 16, 0, 2791, 558, 7, 25, 20, 0, 2, 8, 1, 67, 60, 0),
    (13842, 15, 0, 'Fall/Winter Morning', 18705, 0, 0, 1500, 375, 23, 25, 0, 0, 0, -1, 1, 0, 0, 1);
INSERT INTO `item_template`
    (`entry`, `name`, `class`, `subclass`, `displayid`, `Quality`, `FlagsExtra`, `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `ItemLevel`, `RequiredLevel`, `delay`, `spellid_1`, `spelltrigger_1`, `bonding`, `Material`, `socketColor_1`, `VerifiedBuild`)
VALUES
    (25667, 'ObsoleteIdol of the Beast', 4, 8, 40160, 3, 8192, 94198, 18839, 28, 32767, 79, 64, 0, 32410, 1, 1, 2, 14, 15595);
