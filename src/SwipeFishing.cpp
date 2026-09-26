/*
 * mod-swipe-fishing
 *
 * Druids fish like bears: no pole, just claws. A druid in Bear Form, standing in water with a
 * salmon relic on, roars (/roar) and waits. A salmon circles just under the surface in front of
 * them; after a while it leaps out and lands at the bear's feet. The druid has a moment to Swipe
 * it. A hit catches it, and its loot opens with whatever normal fishing would give in that spot,
 * counted as fishing for achievements and statistics. Too early and the fish is spooked; too late
 * and it flops back into the water. The fishing session goes on, one salmon after another, until
 * the druid moves, leaves the water or leaves Bear Form.
 *
 * Catches follow the core's fishing rules: the zone's fishing loot, a catch chance from fishing
 * skill against the zone's fishing level, and a skill-up check on every attempt.
 *
 * Fishing pools work as they do for a bobber. Roar with a pool in reach and the salmon waits
 * inside it. A salmon caught inside a pool's radius is a sure catch and opens the pool's own loot,
 * which uses up one of the pool's catches, so it runs out and despawns as usual.
 *
 * Nothing here needs a client patch: the druid casts Swipe, which bears always can, not Fishing,
 * which the client refuses in Bear Form or without a pole.
 *
 * The relics: one idol per fishing rank, Journeyman to Grand Master, each with Stamina and fishing
 * skill. Wearing any of them lets a druid fish (configurable). Tavar Riverclaw gives the first, and
 * each time the druid can train the next fishing rank, he trades their relic for the next one (see
 * the SQL).
 *
 * Released under the MIT License.
 */

#include "Chat.h"
#include "Config.h"
#include "CellImpl.h"
#include "CreatureAI.h"
#include "GameObject.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "LootMgr.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "TemporarySummon.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <initializer_list>

namespace
{
    // The salmon. Must match the SQL.
    constexpr uint32 NPC_LEAPING_SALMON = 9500400;

    // The relics, Journeyman to Grand Master. Reused Item.dbc idols players can't get, so the client
    // shows an idol icon; the SQL rewrites their item_template rows. Must match the SQL.
    constexpr std::array<uint32, 5> SALMON_RELICS = {
        23004, // Ossified Salmon     (was "Idol of Longevity")
        42574, // Fossilized Salmon   (was "Savage Gladiator's Idol of Resolve")
        42576, // Petrified Salmon    (was "Savage Gladiator's Idol of Tenacity")
        42577, // Moonstone Salmon    (was "Hateful Gladiator's Idol of Tenacity")
        25667  // Voracious Salmon    (was "Idol of the Beast", replaced in TBC)
    };

    // Swipe (Bear) is bound to the spell script below in the SQL.

    // Movement point ids for MovementInform.
    constexpr uint32 POINT_LANDED        = 1;
    constexpr uint32 POINT_BACK_IN_WATER = 2;

    constexpr uint32 WATER_LIQUIDS = MAP_LIQUID_TYPE_WATER | MAP_LIQUID_TYPE_OCEAN;
    constexpr float GRAVITY        = 19.29110527038574f; // Movement::gravity
    constexpr float FISH_DEPTH     = 0.4f;  // How far under the surface a waiting fish swims
    constexpr float MIN_WATER_DEPTH = 0.6f; // Shallower than this is no place for a salmon
    constexpr float LAND_DISTANCE  = 1.5f;  // Where a leaping fish lands, in front of the bear
    constexpr float LEAP_TIME      = 0.8f;  // Seconds a leap takes, however far it goes
    constexpr float MIN_LEAP_SPEED = 3.0f;  // Yards per second
    constexpr float LEAP_HEIGHT    = 2.5f;
    constexpr float POOL_CATCH_RANGE = 20.0f + CONTACT_DISTANCE; // The core's search range for a bobber
    constexpr float MAX_ANCHOR_DRIFT = 2.5f; // Moving further than this from where you roared ends it
    constexpr Milliseconds OWNER_CHECK_INTERVAL = 500ms;

    struct Config
    {
        bool enabled = true;
        uint32 startEmote = TEXT_EMOTE_ROAR;
        bool requireRelic = true;
        bool sitWhileWaiting = true;
        uint32 biteDelayMin = 5000;
        uint32 biteDelayMax = 15000;
        uint32 catchWindow = 1500;
        uint32 spookDelay = 6000;
        uint32 rageOnLeap = 25;
        uint32 minCatchChance = 50;
        uint32 corpseSeconds = 60;
        float spotDistance = 4.5f;
        float poolReach = 12.0f;

        uint32 leapSound = 3355;    // "Fishing Hooked", the bobber's bite
        uint32 rippleSpell = 69657; // Water Splash (Self)
        uint32 splashSpell = 69665; // [DND] Water Visual
    };

    Config config;

    // Per player: the salmon they're fishing for right now, if any.
    struct SwipeFishingData : public DataMap::Base
    {
        ObjectGuid fish;
    };

    SwipeFishingData* GetFishingData(Player* player)
    {
        return player->CustomData.GetDefault<SwipeFishingData>("mod-swipe-fishing");
    }

    bool IsBear(Unit const* unit)
    {
        ShapeshiftForm const form = unit->GetShapeshiftForm();
        return form == FORM_BEAR || form == FORM_DIREBEAR;
    }

    // Any of the salmon relics, whatever the rank.
    bool HasSalmonRelic(Player const* player)
    {
        for (uint32 relic : SALMON_RELICS)
            if (player->HasItemOrGemWithIdEquipped(relic, 1))
                return true;

        return false;
    }

    bool IsSalmon(Unit const* unit)
    {
        return unit && unit->GetEntry() == NPC_LEAPING_SALMON;
    }

    // Standing or swimming in water (not lava or slime).
    bool IsInWater(Player const* player)
    {
        LiquidData const& liquid = player->GetLiquidData();
        return (liquid.Status & MAP_LIQUID_STATUS_SWIMMING) && (liquid.Flags & WATER_LIQUIDS);
    }

    // A place for a salmon: open water `distance` yards from the player, `angle` off where they
    // face, deep enough and in sight. The fish waits just under the surface there, facing the player.
    bool FindWaterSpot(Player* player, float distance, float angle, Position& spot)
    {
        float const o = player->GetOrientation() + angle;
        float const x = player->GetPositionX() + distance * std::cos(o);
        float const y = player->GetPositionY() + distance * std::sin(o);

        LiquidData const liquid = player->GetMap()->GetLiquidData(player->GetPhaseMask(), x, y,
            player->GetPositionZ(), player->GetCollisionHeight(), WATER_LIQUIDS);

        if (!(liquid.Status & MAP_LIQUID_STATUS_SWIMMING) || liquid.Level <= INVALID_HEIGHT)
            return false;

        if (liquid.DepthLevel > INVALID_HEIGHT && liquid.Level - liquid.DepthLevel < MIN_WATER_DEPTH)
            return false;

        if (!player->IsWithinLOS(x, y, liquid.Level))
            return false;

        spot.Relocate(x, y, liquid.Level - FISH_DEPTH, Position::NormalizeOrientation(o + float(M_PI)));
        return true;
    }

    // Finds the nearest spawned fishing pool whose centre is within `range` of `obj`.
    class NearestFishingPoolInRange
    {
    public:
        NearestFishingPoolInRange(WorldObject const& obj, float range) : _obj(obj), _range(range) { }

        bool operator()(GameObject* go)
        {
            if (go->GetGoType() != GAMEOBJECT_TYPE_FISHINGHOLE || !go->isSpawned() || !_obj.IsWithinDistInMap(go, _range))
                return false;

            _range = _obj.GetDistance(go);
            return true;
        }

    private:
        WorldObject const& _obj;
        float _range;
    };

    // A fishing pool in reach of the player, if there is one: the salmon waits in its middle.
    bool FindPoolSpot(Player* player, Position& spot)
    {
        if (config.poolReach <= 0.0f)
            return false;

        GameObject* pool = nullptr;
        NearestFishingPoolInRange check(*player, config.poolReach);
        Acore::GameObjectLastSearcher<NearestFishingPoolInRange> searcher(player, pool, check);
        Cell::VisitObjects(player, searcher, config.poolReach);

        if (!pool || !player->IsWithinLOSInMap(pool))
            return false;

        spot.Relocate(pool->GetPositionX(), pool->GetPositionY(), pool->GetPositionZ() - FISH_DEPTH,
            pool->GetAbsoluteAngle(player));
        return true;
    }

    // The core's test for a bobber in a pool (NearestGameObjectFishingHole), made for a point
    // instead of an object: a spawned pool whose radius covers `spot`.
    class FishingPoolAtSpot
    {
    public:
        explicit FishingPoolAtSpot(Position const& spot) : _spot(spot) { }

        bool operator()(GameObject* go) const
        {
            return go->GetGoType() == GAMEOBJECT_TYPE_FISHINGHOLE && go->isSpawned()
                && go->GetExactDist(&_spot) <= std::min(POOL_CATCH_RANGE, float(go->GetGOInfo()->fishinghole.radius));
        }

    private:
        Position const& _spot;
    };

    // The pool a salmon came out of, if any. It's judged by where it waited, not where it
    // landed: it leapt out of the pool even if it's lying at the bear's feet now.
    GameObject* GetPoolAt(Creature* fish, Position const& spot)
    {
        GameObject* pool = nullptr;
        FishingPoolAtSpot check(spot);
        Acore::GameObjectSearcher<FishingPoolAtSpot> searcher(fish, pool, check);
        Cell::VisitObjects(fish, searcher, fish->GetExactDist(&spot) + POOL_CATCH_RANGE);
        return pool;
    }

    // The core's fishing formula (GameObject::Use, fishing bobber): skill against the zone's
    // fishing level, certain at zone level + 95. Never below the configured floor.
    int32 GetCatchChance(Player* player, Creature* fish, int32& skill, int32& zoneSkill)
    {
        uint32 zone, area;
        fish->GetZoneAndAreaId(zone, area);

        zoneSkill = sObjectMgr->GetFishingBaseSkillLevel(area);
        if (!zoneSkill)
            zoneSkill = sObjectMgr->GetFishingBaseSkillLevel(zone);

        skill = player->GetSkillValue(SKILL_FISHING);

        int32 const noMissSkill = zoneSkill + 95;
        int32 chance = 100;
        if (noMissSkill > 0 && skill < noMissSkill)
            chance = int32(std::pow(double(skill) / noMissSkill, 2) * 100);

        return std::max<int32>(chance, config.minCatchChance);
    }

    // What fishing here would give, like GameObject::GetFishLoot: the area's loot, else the zone's,
    // else the fallback zone 1.
    void FillFishLoot(Creature* fish, Player* player)
    {
        fish->loot.clear();

        uint32 zone, area;
        fish->GetZoneAndAreaId(zone, area);

        for (uint32 lootZone : { area, zone, 1u })
        {
            fish->loot.FillLoot(lootZone, LootTemplates_Fishing, player, true, true);
            if (!fish->loot.empty() && !fish->loot.isLooted())
                break;
        }
    }

    void Notify(Player* player, char const* text)
    {
        player->GetSession()->SendAreaTriggerMessage(text);
    }

    Creature* SpawnSalmon(Player* player, Position const& spot, Position const& anchor);

    // Can this player go on fishing where they started? Checked twice a second while they wait.
    bool CanKeepFishing(Player* player, Position const& anchor)
    {
        return player->IsAlive() && IsBear(player) && IsInWater(player) && !player->IsMounted()
            && player->GetExactDist2d(&anchor) <= MAX_ANCHOR_DRIFT
            && (!config.requireRelic || HasSalmonRelic(player));
    }
}

// The salmon. It waits under the surface, leaps at the bear's feet, and either gets caught by a
// Swipe or flops back. One fish per player at a time; it goes back to waiting after each leap, and
// a fresh one takes over when it's caught.
struct npc_swipe_fishing_salmon : public CreatureAI
{
    enum class State
    {
        Waiting,  // Under the surface, before the bite
        Leaping,  // In the air: catchable
        Landed,   // At the bear's feet: catchable
        Escaping, // On its way back into the water
        Caught
    };

    enum Events
    {
        EVENT_CHECK_OWNER = 1,
        EVENT_RIPPLE,
        EVENT_LEAP,
        EVENT_LANDED,
        EVENT_ESCAPE,
        EVENT_BACK_IN_WATER
    };

    explicit npc_swipe_fishing_salmon(Creature* creature) : CreatureAI(creature) { }

    // Called right after the summon. The fish keeps coming back as long as the owner stays put.
    void Start(Player* owner, Position const& anchor)
    {
        _owner = owner->GetGUID();
        _anchor = anchor;
        _spot = me->GetPosition();

        me->SetReactState(REACT_PASSIVE);
        me->SetDisableGravity(true);

        _events.ScheduleEvent(EVENT_CHECK_OWNER, OWNER_CHECK_INTERVAL);
        Wait(0);
    }

    Player* GetOwner() const
    {
        return ObjectAccessor::GetPlayer(*me, _owner);
    }

    // Back under the surface until the next bite.
    void Wait(uint32 extraDelay)
    {
        _state = State::Waiting;
        _events.CancelEvent(EVENT_LEAP);
        _events.ScheduleEvent(EVENT_LEAP, Milliseconds(extraDelay + urand(config.biteDelayMin, std::max(config.biteDelayMin, config.biteDelayMax))));

        _events.CancelEvent(EVENT_RIPPLE);
        if (config.rippleSpell)
            _events.ScheduleEvent(EVENT_RIPPLE, 2s, 4s);
    }

    void Leap()
    {
        Player* owner = GetOwner();
        if (!owner)
        {
            End(nullptr, nullptr);
            return;
        }

        _state = State::Leaping;
        _events.CancelEvent(EVENT_RIPPLE);

        // Out of combat a bear has no rage; the leap gives enough for one Swipe.
        if (config.rageOnLeap && owner->getPowerType() == POWER_RAGE)
        {
            int32 const wanted = int32(config.rageOnLeap * 10);
            int32 const current = int32(owner->GetPower(POWER_RAGE));
            if (current < wanted)
                owner->ModifyPower(POWER_RAGE, wanted - current);
        }

        if (config.splashSpell)
            me->CastSpell(me, config.splashSpell, true);

        if (config.leapSound)
            me->PlayDirectSound(config.leapSound, owner);

        Notify(owner, "A salmon leaps! Swipe!");

        // Land at the bear's feet, on the water or ground there.
        float const toFish = owner->GetAngle(me);
        float x = owner->GetPositionX() + LAND_DISTANCE * std::cos(toFish);
        float y = owner->GetPositionY() + LAND_DISTANCE * std::sin(toFish);
        float z = owner->GetMapWaterOrGroundLevel(x, y, owner->GetPositionZ());
        if (z <= INVALID_HEIGHT)
            z = owner->GetPositionZ();

        // A salmon from a pool further out leaps faster, so every leap takes about as long.
        float const speedXY = std::max(MIN_LEAP_SPEED, me->GetExactDist2d(x, y) / LEAP_TIME);
        float const speedZ = std::sqrt(2.0f * GRAVITY * LEAP_HEIGHT);
        me->GetMotionMaster()->MoveJump(x, y, z, speedXY, speedZ, POINT_LANDED);

        // In case the movement never reports back.
        _events.ScheduleEvent(EVENT_LANDED, Milliseconds(uint32(me->GetExactDist2d(x, y) / speedXY * 1000.0f) + 300));
    }

    void Landed()
    {
        if (_state != State::Leaping)
            return;

        _state = State::Landed;
        _events.CancelEvent(EVENT_LANDED);
        _events.ScheduleEvent(EVENT_ESCAPE, Milliseconds(config.catchWindow));
    }

    // Too late, or it slipped free: back into the water.
    void Escape(char const* message)
    {
        if (Player* owner = GetOwner())
            Notify(owner, message);

        _state = State::Escaping;
        _events.CancelEvent(EVENT_ESCAPE);
        _events.CancelEvent(EVENT_LANDED);

        float const speedXY = std::max(MIN_LEAP_SPEED, me->GetExactDist2d(&_spot) / LEAP_TIME);
        me->GetMotionMaster()->MoveJump(_spot, speedXY, std::sqrt(2.0f * GRAVITY * 1.5f), POINT_BACK_IN_WATER);
        _events.ScheduleEvent(EVENT_BACK_IN_WATER, Milliseconds(uint32(LEAP_TIME * 1000.0f) + 700));
    }

    void BackInWater()
    {
        if (_state != State::Escaping)
            return;

        _events.CancelEvent(EVENT_BACK_IN_WATER);

        if (GetOwner())
            Wait(0);
        else
            End(GetOwner(), nullptr);
    }

    // Swiped by `caster`. Only the owner's Swipe counts.
    void OnSwiped(Player* caster)
    {
        if (caster->GetGUID() != _owner)
            return;

        switch (_state)
        {
            case State::Waiting:
                Notify(caster, "Too soon! The salmon darts away.");
                Wait(config.spookDelay);
                break;
            case State::Leaping:
            case State::Landed:
                TryCatch(caster);
                break;
            default:
                break;
        }
    }

    void TryCatch(Player* player)
    {
        // Like a bobber in a pool, a salmon from a pool is a sure catch.
        GameObject* pool = GetPoolAt(me, _spot);

        int32 skill, zoneSkill;
        int32 chance = GetCatchChance(player, me, skill, zoneSkill);
        if (pool)
            chance = 100;
        int32 const roll = irand(1, 100);

        // Every attempt can raise fishing skill, as with a bobber.
        if (sScriptMgr->OnPlayerUpdateFishingSkill(player, skill, zoneSkill, chance, roll))
            player->UpdateFishingSkill();

        if (roll > chance)
        {
            Escape("The salmon slips out of your claws!");
            return;
        }

        _state = State::Caught;
        _poolCatch = pool ? pool->GetGUID() : ObjectGuid::Empty;
        _events.Reset();
        me->GetMotionMaster()->Clear();
        me->SetLootRecipient(player);
        Unit::Kill(player, me);
    }

    void JustDied(Unit* /*killer*/) override
    {
        Player* owner = GetOwner();
        if (!owner)
            return;

        // Caught from a pool: open the pool's loot, as the core does for a bobber. Closing it uses
        // up one of the pool's catches. The salmon's body has nothing, so it goes soon.
        GameObject* pool = _poolCatch ? ObjectAccessor::GetGameObject(*me, _poolCatch) : nullptr;
        if (pool && pool->isSpawned())
        {
            pool->Use(owner);
            me->DespawnOrUnsummon(3s);
        }
        else
        {
            // Unit::Kill has already cleared the (empty) creature loot; the catch is fishing loot.
            FillFishLoot(me, owner);
            if (!me->loot.empty())
            {
                me->SetDynamicFlag(UNIT_DYNFLAG_LOOTABLE);
                me->SetCorpseRemoveTime(config.corpseSeconds);

                // Open it as fishing loot, as a bobber does, so the catch counts as fishing.
                owner->SendLoot(me->GetGUID(), LOOT_FISHING);
            }
        }

        // The corpse stays for looting; a fresh salmon takes its place in the water.
        if (CanKeepFishing(owner, _anchor))
            SpawnSalmon(owner, _spot, _anchor);
        else
            End(owner, nullptr);
    }

    // Stop fishing: forget this fish and send it away (unless it's a corpse to loot).
    void End(Player* owner, char const* message)
    {
        _events.Reset();

        if (owner)
        {
            SwipeFishingData* data = GetFishingData(owner);
            if (data->fish == me->GetGUID())
                data->fish.Clear();

            if (message)
                Notify(owner, message);

            if (owner->IsSitState())
                owner->SetStandState(UNIT_STAND_STATE_STAND);
        }

        if (me->IsAlive())
            me->DespawnOrUnsummon();
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type != EFFECT_MOTION_TYPE)
            return;

        if (id == POINT_LANDED)
            Landed();
        else if (id == POINT_BACK_IN_WATER)
            BackInWater();
    }

    // Only a caught fish dies, and only by Unit::Kill: no damage from anything.
    void DamageTaken(Unit* /*attacker*/, uint32& damage, DamageEffectType /*type*/, SpellSchoolMask /*school*/) override
    {
        damage = 0;
    }

    void AttackStart(Unit* /*target*/) override { }
    void MoveInLineOfSight(Unit* /*who*/) override { }
    void EnterEvadeMode(EvadeReason /*why*/) override { }

    void UpdateAI(uint32 diff) override
    {
        if (!me->IsAlive())
            return;

        // A Swipe puts the druid in combat with the fish, and the fish never fights back or
        // evades, so that combat would never end. End it; the druid's real fights are untouched.
        if (me->IsInCombat())
            me->CombatStop(true);

        _events.Update(diff);

        while (uint32 eventId = _events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_CHECK_OWNER:
                {
                    Player* owner = GetOwner();
                    if (!owner || !CanKeepFishing(owner, _anchor))
                    {
                        End(owner, "You stop fishing.");
                        return;
                    }
                    if (owner->IsInCombat() && _state == State::Waiting)
                    {
                        End(owner, "You can't fish in a fight.");
                        return;
                    }
                    _events.ScheduleEvent(EVENT_CHECK_OWNER, OWNER_CHECK_INTERVAL);
                    break;
                }
                case EVENT_RIPPLE:
                    if (_state == State::Waiting && config.rippleSpell)
                    {
                        me->CastSpell(me, config.rippleSpell, true);
                        _events.ScheduleEvent(EVENT_RIPPLE, 3s, 6s);
                    }
                    break;
                case EVENT_LEAP:
                    Leap();
                    break;
                case EVENT_LANDED:
                    Landed();
                    break;
                case EVENT_ESCAPE:
                    Escape("The salmon flops back into the water.");
                    break;
                case EVENT_BACK_IN_WATER:
                    BackInWater();
                    break;
                default:
                    break;
            }

            if (!me->IsAlive() || !me->IsInWorld())
                return;
        }
    }

private:
    EventMap _events;
    ObjectGuid _owner;
    ObjectGuid _poolCatch;
    Position _anchor;
    Position _spot;
    State _state = State::Waiting;
};

namespace
{
    Creature* SpawnSalmon(Player* player, Position const& spot, Position const& anchor)
    {
        TempSummon* fish = player->SummonCreature(NPC_LEAPING_SALMON, spot, TEMPSUMMON_MANUAL_DESPAWN, 0, 0, nullptr, true);
        if (!fish)
            return nullptr;

        auto* ai = dynamic_cast<npc_swipe_fishing_salmon*>(fish->AI());
        if (!ai)
        {
            fish->DespawnOrUnsummon();
            return nullptr;
        }

        GetFishingData(player)->fish = fish->GetGUID();
        ai->Start(player, anchor);
        return fish;
    }

    // The player's current salmon, if it's still around and alive.
    Creature* GetCurrentSalmon(Player* player)
    {
        SwipeFishingData* data = GetFishingData(player);
        if (!data->fish)
            return nullptr;

        Creature* fish = ObjectAccessor::GetCreature(*player, data->fish);
        if (!fish || !fish->IsAlive())
        {
            data->fish.Clear();
            return nullptr;
        }
        return fish;
    }

    // /roar: start a fishing session, or say why not. Druids who aren't dressed for it get no reply,
    // so roaring stays just roaring for everyone else.
    void TryStartFishing(Player* player)
    {
        if (player->getClass() != CLASS_DRUID || !IsBear(player))
            return;

        if (config.requireRelic && !HasSalmonRelic(player))
            return;

        ChatHandler chat(player->GetSession());

        if (!player->HasSkill(SKILL_FISHING))
        {
            chat.SendNotification("You need to know Fishing.");
            return;
        }

        if (GetCurrentSalmon(player))
            return;

        if (!IsInWater(player))
        {
            chat.SendNotification("Wade into the water first.");
            return;
        }

        if (player->IsInCombat() || player->IsMounted())
        {
            chat.SendNotification("You can't fish right now.");
            return;
        }

        Position spot;
        bool found = FindPoolSpot(player, spot);
        for (float distance : { config.spotDistance, config.spotDistance - 1.0f, config.spotDistance - 2.0f })
            if (!found && distance > LAND_DISTANCE && FindWaterSpot(player, distance, 0.0f, spot))
            {
                found = true;
                break;
            }

        if (!found)
        {
            chat.SendNotification("Face deeper water.");
            return;
        }

        if (!SpawnSalmon(player, spot, player->GetPosition()))
            return;

        if (config.sitWhileWaiting)
            player->SetStandState(UNIT_STAND_STATE_SIT);

        Notify(player, "You settle in and watch the water...");
    }
}

// Swipe (Bear), every rank: a Swipe that hits a salmon tries to catch it, and does no damage.
class spell_swipe_fishing_swipe : public SpellScript
{
    PrepareSpellScript(spell_swipe_fishing_swipe);

    void HandleHit(SpellEffIndex /*effIndex*/)
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        Unit* target = GetHitUnit();
        if (!player || !IsSalmon(target))
            return;

        PreventHitDamage();
        if (auto* ai = dynamic_cast<npc_swipe_fishing_salmon*>(target->ToCreature()->AI()))
            ai->OnSwiped(player);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_swipe_fishing_swipe::HandleHit, EFFECT_ALL, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class SwipeFishingWorldScript : public WorldScript
{
public:
    SwipeFishingWorldScript() : WorldScript("SwipeFishingWorldScript", { WORLDHOOK_ON_BEFORE_CONFIG_LOAD }) { }

    void OnBeforeConfigLoad(bool /*reload*/) override
    {
        config.enabled         = sConfigMgr->GetOption<bool>("SwipeFishing.Enable", true);
        config.startEmote      = sConfigMgr->GetOption<uint32>("SwipeFishing.StartEmote", TEXT_EMOTE_ROAR);
        config.requireRelic    = sConfigMgr->GetOption<bool>("SwipeFishing.RequireRelic", true);
        config.sitWhileWaiting = sConfigMgr->GetOption<bool>("SwipeFishing.SitWhileWaiting", true);
        config.biteDelayMin    = sConfigMgr->GetOption<uint32>("SwipeFishing.BiteDelayMin", 5000);
        config.biteDelayMax    = sConfigMgr->GetOption<uint32>("SwipeFishing.BiteDelayMax", 15000);
        config.catchWindow     = sConfigMgr->GetOption<uint32>("SwipeFishing.CatchWindow", 1500);
        config.spookDelay      = sConfigMgr->GetOption<uint32>("SwipeFishing.SpookDelay", 6000);
        config.rageOnLeap      = sConfigMgr->GetOption<uint32>("SwipeFishing.RageOnLeap", 25);
        config.minCatchChance  = std::min<uint32>(100, sConfigMgr->GetOption<uint32>("SwipeFishing.MinCatchChance", 50));
        config.corpseSeconds   = sConfigMgr->GetOption<uint32>("SwipeFishing.CorpseSeconds", 60);
        config.spotDistance    = std::clamp(sConfigMgr->GetOption<float>("SwipeFishing.SpotDistance", 4.5f), 2.0f, 8.0f);
        config.poolReach       = std::clamp(sConfigMgr->GetOption<float>("SwipeFishing.PoolReach", 12.0f), 0.0f, 30.0f);

        config.leapSound       = sConfigMgr->GetOption<uint32>("SwipeFishing.LeapSound", 3355);
        config.rippleSpell     = sConfigMgr->GetOption<uint32>("SwipeFishing.RippleSpell", 69657);
        config.splashSpell     = sConfigMgr->GetOption<uint32>("SwipeFishing.SplashSpell", 69665);
    }
};

class SwipeFishingPlayerScript : public PlayerScript
{
public:
    SwipeFishingPlayerScript() : PlayerScript("SwipeFishingPlayerScript", { PLAYERHOOK_ON_TEXT_EMOTE, PLAYERHOOK_ON_BEFORE_SEND_LOOT }) { }

    void OnPlayerTextEmote(Player* player, uint32 textEmote, uint32 /*emoteNum*/, ObjectGuid /*guid*/) override
    {
        if (config.enabled && textEmote == config.startEmote)
            TryStartFishing(player);
    }

    // Achievements and statistics count fish by the loot's type, and opening a body by hand makes
    // it corpse loot. A salmon's body holds a catch, so keep it fishing loot however it's opened.
    void OnPlayerBeforeSendLoot(Player* player, ObjectGuid lootGuid, Loot* loot) override
    {
        if (!lootGuid.IsCreature() || loot->loot_type != LOOT_CORPSE)
            return;

        if (IsSalmon(ObjectAccessor::GetCreature(*player, lootGuid)))
            loot->loot_type = LOOT_FISHING;
    }
};

void AddSwipeFishingScripts()
{
    new SwipeFishingWorldScript();
    new SwipeFishingPlayerScript();
    RegisterSpellScript(spell_swipe_fishing_swipe);
    RegisterCreatureAI(npc_swipe_fishing_salmon);
}
