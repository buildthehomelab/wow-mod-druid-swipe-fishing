/*
 * mod-swipe-fishing
 *
 * Druids fish in Bear Form. With the Idol of Voracity in the relic slot, a druid in Bear Form who
 * faces water and roars (/roar) casts Fishing, with no pole: the client never lets you cast
 * Fishing yourself while shapeshifted, and a bear can't hold a pole anyway. In caster form nothing
 * changes: Fishing needs a pole, as always.
 *
 * It's the core's own Fishing: the bobber, pools, skill-ups and loot are all unchanged. The bear
 * has no fishing animation, so it just stands there while the bobber floats.
 *
 * How: the server insists on a pole for Fishing even when it casts the spell itself, so at
 * startup the module removes that requirement from every Fishing rank and checks it itself
 * instead: a pole, or Bear Form with the idol. Without either you get the same "Requires Fishing
 * Pole" as before. /roar casts the druid's best Fishing rank for them, skipping the check for
 * shapeshift forms.
 *
 * Released under the MIT License.
 */

#include "Chat.h"
#include "Config.h"
#include "Item.h"
#include "Opcodes.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <array>

namespace
{
    // The idol. A reused Item.dbc entry, so the client shows a fitting icon; the SQL rewrites its
    // item_template row. Must match the SQL.
    constexpr uint32 ITEM_IDOL_OF_VORACITY = 25667;

    // Every rank of Fishing, lowest first: Apprentice to Grand Master.
    constexpr std::array<uint32, 6> FISHING_RANKS = { 7620, 7731, 7732, 18248, 33095, 51294 };

    struct Config
    {
        bool enabled = true;
        uint32 startEmote = TEXT_EMOTE_ROAR;
    };

    Config config;

    bool IsFishing(SpellInfo const* spellInfo)
    {
        return spellInfo->GetFirstRankSpell()->Id == FISHING_RANKS.front();
    }

    // A usable fishing pole in the main hand, what Fishing normally asks for.
    bool HasFishingPole(Player const* player)
    {
        Item const* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND);
        if (!item || item->IsBroken())
            return false;

        ItemTemplate const* proto = item->GetTemplate();
        return proto->Class == ITEM_CLASS_WEAPON && proto->SubClass == ITEM_SUBCLASS_WEAPON_FISHING_POLE;
    }

    bool IsBear(Unit const* unit)
    {
        ShapeshiftForm const form = unit->GetShapeshiftForm();
        return form == FORM_BEAR || form == FORM_DIREBEAR;
    }

    // A bear wearing the idol can fish without a pole.
    bool CanFishAsBear(Player const* player)
    {
        return config.enabled && IsBear(player) && player->HasItemOrGemWithIdEquipped(ITEM_IDOL_OF_VORACITY, 1);
    }

    // The "Requires Fishing Pole" error, as the core sends it when Fishing still needs a pole.
    void SendRequiresFishingPole(Player* player, uint32 spellId, uint8 castCount)
    {
        WorldPacket data(SMSG_CAST_FAILED, 1 + 4 + 1 + 4 + 4);
        data << uint8(castCount);
        data << uint32(spellId);
        data << uint8(SPELL_FAILED_EQUIPPED_ITEM_CLASS);
        data << uint32(ITEM_CLASS_WEAPON);
        data << uint32(1 << ITEM_SUBCLASS_WEAPON_FISHING_POLE);
        player->SendDirectMessage(&data);
    }

    // The druid's best Fishing rank, or 0.
    uint32 GetBestFishingRank(Player const* player)
    {
        for (auto rank = FISHING_RANKS.rbegin(); rank != FISHING_RANKS.rend(); ++rank)
            if (player->HasSpell(*rank))
                return *rank;

        return 0;
    }

    // /roar in Bear Form with the idol on: cast Fishing. The usual Fishing checks still apply
    // (water in front, not while moving), and their errors show as usual.
    void TryRoarFishing(Player* player)
    {
        if (!CanFishAsBear(player))
            return;

        uint32 const spellId = GetBestFishingRank(player);
        if (!spellId)
        {
            ChatHandler(player->GetSession()).SendNotification("You need to know Fishing.");
            return;
        }

        // Already fishing (or casting something else): roaring shouldn't recast over it.
        if (player->IsNonMeleeSpellCast(false))
            return;

        player->CastSpell(player, spellId, TRIGGERED_IGNORE_SHAPESHIFT);
    }
}

class SwipeFishingWorldScript : public WorldScript
{
public:
    SwipeFishingWorldScript() : WorldScript("SwipeFishingWorldScript", { WORLDHOOK_ON_BEFORE_CONFIG_LOAD, WORLDHOOK_ON_BEFORE_WORLD_INITIALIZED }) { }

    void OnBeforeConfigLoad(bool /*reload*/) override
    {
        config.enabled    = sConfigMgr->GetOption<bool>("SwipeFishing.Enable", true);
        config.startEmote = sConfigMgr->GetOption<uint32>("SwipeFishing.StartEmote", TEXT_EMOTE_ROAR);
    }

    // The core checks for a pole in a way no script or trigger flag can skip, so take the
    // requirement off Fishing here; SwipeFishingAllSpellScript puts it back for everyone but a
    // bear with the idol.
    void OnBeforeWorldInitialized() override
    {
        for (uint32 spellId : FISHING_RANKS)
            if (SpellInfo* spellInfo = const_cast<SpellInfo*>(sSpellMgr->GetSpellInfo(spellId)))
            {
                spellInfo->EquippedItemClass = -1;
                spellInfo->EquippedItemSubClassMask = 0;
            }
    }
};

class SwipeFishingAllSpellScript : public AllSpellScript
{
public:
    SwipeFishingAllSpellScript() : AllSpellScript("SwipeFishingAllSpellScript", { ALLSPELLHOOK_ON_SPELL_CHECK_CAST }) { }

    // Fishing needs a pole, or Bear Form and the idol. The core's own error names the item class from the spell,
    // which no longer has one, so send the "Requires Fishing Pole" error ourselves and have the
    // core report nothing.
    void OnSpellCheckCast(Spell* spell, bool strict, SpellCastResult& res) override
    {
        if (res != SPELL_CAST_OK || !IsFishing(spell->GetSpellInfo()))
            return;

        Player* player = spell->GetCaster() ? spell->GetCaster()->ToPlayer() : nullptr;
        if (!player || HasFishingPole(player) || CanFishAsBear(player))
            return;

        res = SPELL_FAILED_DONT_REPORT;
        if (strict)
            SendRequiresFishingPole(player, spell->GetSpellInfo()->Id, spell->m_cast_count);
    }
};

class SwipeFishingPlayerScript : public PlayerScript
{
public:
    SwipeFishingPlayerScript() : PlayerScript("SwipeFishingPlayerScript", { PLAYERHOOK_ON_TEXT_EMOTE }) { }

    void OnPlayerTextEmote(Player* player, uint32 textEmote, uint32 /*emoteNum*/, ObjectGuid /*guid*/) override
    {
        if (textEmote == config.startEmote)
            TryRoarFishing(player);
    }
};

void AddSwipeFishingScripts()
{
    new SwipeFishingWorldScript();
    new SwipeFishingAllSpellScript();
    new SwipeFishingPlayerScript();
}
