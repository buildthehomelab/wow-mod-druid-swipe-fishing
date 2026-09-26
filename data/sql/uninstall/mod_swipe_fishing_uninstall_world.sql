-- mod-swipe-fishing: uninstall, world database. Not run automatically: AzerothCore only runs a
-- module's SQL from data/sql/db-world and similar folders. Run it by hand after removing the module.
--
-- Removes the salmon, Tavar Riverclaw and his spawn, the quests and the spell script bindings, and
-- puts back the original rows of the four reused items, as in AzerothCore's base data.
-- Characters keep quest progress and the items they already have; those items go back to being the
-- original placeholder items.

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
INSERT INTO `item_template` VALUES
(3063,4,2,-1,'Deprecated Deepwood Helm',13250,0,16,8192,1,2593,518,1,-1,-1,27,22,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,2,'',0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,0,0,'',0,0,0,0,0,15595),
(3064,4,2,-1,'Deprecated Deepwood Pants',3205,0,16,0,1,2791,558,7,-1,-1,25,20,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,67,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,2,'',0,0,0,0,0,8,0,0,0,0,0,60,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,0,0,'',0,0,0,0,0,1),
(13842,15,0,-1,'Fall/Winter Morning',18705,1,0,0,1,1500,375,23,-1,-1,25,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,'',0,0,0,0,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,0,0,0,'',0,0,0,0,0,1),
(25667,4,8,-1,'ObsoleteIdol of the Beast',40160,3,0,8192,1,94198,18839,28,32767,-1,79,64,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,32410,1,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,0,0,0,0,-1,0,-1,1,'',0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,14,0,0,0,0,0,0,0,-1,0,0,0,0,'',0,0,0,0,0,15595);
