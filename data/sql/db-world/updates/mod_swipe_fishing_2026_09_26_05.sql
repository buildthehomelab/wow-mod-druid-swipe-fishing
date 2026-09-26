-- mod-swipe-fishing: no more leaping fish, and the relic starts fishing. Idempotent: safe to run
-- again.
--
-- The salmon stays under the water, unseen: its ripples show where it is, and a splash is the cue
-- to Swipe. It uses the invisible model triggers use (display 11686) and can't be selected
-- (UNIT_FLAG_NOT_SELECTABLE, 0x2000000), so nobody clicks, tabs to or hits it; the script catches
-- it on the owner's Swipe.

UPDATE `creature_template`
SET `name` = 'Salmon', `unit_flags` = `unit_flags` | 33554432
WHERE `entry` = 9500400;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9500400;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (9500400, 0, 11686, 1, 1);

-- ---------------------------------------------------------------------------------------------
-- Fishing starts by using the relic, not with /roar. The client only lets an item be used if it
-- has a use spell, and shows that spell's text as the "Use:" line, so the relics get Find Fish
-- (43308, "Nearby fishing nodes appear on the minimap"): true, handy for finding pools, and
-- allowed in Bear Form. The script starts fishing and lets Find Fish be cast too.
-- ---------------------------------------------------------------------------------------------

UPDATE `item_template`
SET `spellid_2` = 43308, `spelltrigger_2` = 0, `spellcharges_2` = 0, `spellcooldown_2` = -1,
    `spellcategory_2` = 0, `spellcategorycooldown_2` = -1, `ScriptName` = 'item_swipe_fishing_relic'
WHERE `entry` IN (23004, 42574, 42576, 42577, 25667);

UPDATE `quest_template`
SET `QuestDescription` = 'You fish with a pole and a bobber, $N? Like a hairless $r? Hah!$B$BThe bears of this lake taught me better. Wear this old salmon bone, take the shape of the bear, and wade in. Hold the bone up to the water, so the salmon know you''ve come. Then sit, and wait, and watch the water.$B$BWhen it splashes, you Swipe. Not before, or you''ll only scare the fish off. Not after, or it''s gone.$B$BCome back to me as your fishing grows. The bone grows with you.'
WHERE `ID` = 9500404;

UPDATE `quest_offer_reward`
SET `RewardText` = 'Wear it well. A bear doesn''t need a pole, and neither do you.$B$BRemember: Bear Form, in the water, and use the salmon. Swipe when the water splashes.'
WHERE `ID` = 9500404;
