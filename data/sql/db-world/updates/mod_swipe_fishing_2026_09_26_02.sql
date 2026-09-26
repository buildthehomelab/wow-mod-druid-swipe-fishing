-- mod-swipe-fishing: the idol is for Bear Form only. In caster form Fishing needs a pole as always.
-- Updates the idol's description and Tavar's reward text to say so. Idempotent.

UPDATE `item_template`
SET `description` = 'Lets you fish in Bear Form, without a pole: face the water and /roar.'
WHERE `entry` = 25667;

UPDATE `quest_offer_reward`
SET `RewardText` = 'Good fish, and good fishing. Take the idol.$B$BA bear can''t hold a pole, and with this it doesn''t need one. Take the shape of the bear, face the water and /roar, and the fish will come to you.'
WHERE `ID` = 9500400;
