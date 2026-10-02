-- mod-swipe-fishing: the salmon is visible and targetable again, and /roar starts fishing again.
-- Idempotent: safe to run again.
--
-- _05 made it invisible and unselectable, but the client won't cast Swipe without a target. It
-- goes back to the red "frenzy" fish of the Northrend Rainbow Trout (display 24637), and loses
-- UNIT_FLAG_NOT_SELECTABLE (0x2000000). It still doesn't leap: when it bites, it surfaces at the
-- bear's feet with a splash.

UPDATE `creature_template`
SET `unit_flags` = `unit_flags` & ~33554432
WHERE `entry` = 9500400;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9500400;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (9500400, 0, 24637, 1, 1);

-- ---------------------------------------------------------------------------------------------
-- Fishing starts with /roar again, not by using the relic: the relics lose the use spell (Find
-- Fish) and item script _05 gave them, and Tavar's first quest says to roar.
-- ---------------------------------------------------------------------------------------------

UPDATE `item_template`
SET `spellid_2` = 0, `spelltrigger_2` = 0, `spellcharges_2` = 0, `spellcooldown_2` = -1,
    `spellcategory_2` = 0, `spellcategorycooldown_2` = -1, `ScriptName` = ''
WHERE `entry` IN (23004, 42574, 42576, 42577, 25667);

UPDATE `quest_template`
SET `QuestDescription` = 'You fish with a pole and a bobber, $N? Like a hairless $r? Hah!$B$BThe bears of this lake taught me better. Wear this old salmon bone, take the shape of the bear, and wade in. Roar, so the salmon know you''ve come. Then sit, and wait, and watch the water.$B$BWhen it splashes, you Swipe. Not before, or you''ll only scare the fish off. Not after, or it''s gone.$B$BCome back to me as your fishing grows. The bone grows with you.'
WHERE `ID` = 9500404;

UPDATE `quest_offer_reward`
SET `RewardText` = 'Wear it well. A bear doesn''t need a pole, and neither do you.$B$BRemember: Bear Form, in the water, and roar. Swipe when the water splashes.'
WHERE `ID` = 9500404;
