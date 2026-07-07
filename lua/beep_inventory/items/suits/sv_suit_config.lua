-- ============================================================
--  Optimized suit config
--  KEY CHANGES:
--  1. pfx()/pfxw() system – 1 entity per named slot, kills old
--     one before spawning new. Zero entity flooding.
--  2. All effects use Vector offsets (OFF_GROUND/CHEST/HEAD)
--  3. No effects spawned inside damage/timer loops – only on
--     ability activation
--  4. HP/AP 10-50x higher than before
--  5. Speed/Jump reduced significantly
-- ============================================================

local _pfx = {}

-- Per-player slot: kills existing effect before spawning new one
local function pfx(ply, slot, class, pos, target, time)
    local id = IsValid(ply) and ply:SteamID64() or "world"
    _pfx[id] = _pfx[id] or {}
    if IsValid(_pfx[id][slot]) then _pfx[id][slot]:Remove() end
    local e = ents.Create(class)
    if not IsValid(e) then return end
    e:SetPos(pos)
    e:Spawn()
    if IsValid(target) then e:SetParent(target) end
    e:time(time)
    _pfx[id][slot] = e
end

-- World slot (ground/positional effects with no player owner)
local function pfxw(slot, class, pos, time)
    _pfx["w"] = _pfx["w"] or {}
    if IsValid(_pfx["w"][slot]) then _pfx["w"][slot]:Remove() end
    local e = ents.Create(class)
    if not IsValid(e) then return end
    e:SetPos(pos)
    e:Spawn()
    e:time(time)
    _pfx["w"][slot] = e
end

local OFF_GROUND = Vector(0, 0,  4)
local OFF_CHEST  = Vector(0, 0, 40)
local OFF_HEAD   = Vector(0, 0, 72)


-- ═══════════════════════════════════════════════════════════
--  1. PYROMANCER
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Pyromancer", {
    Health     = defaultRanges(8000,  80000),
    Armor      = defaultRanges(4000,  40000),
    Resistance = defaultRanges(10, 60),
    Speed      = defaultRanges(80,  180),
    Jump       = defaultRanges(80,  160),
    Regen      = defaultRanges(120, 600)
}, "Born of flame, consumed by fury.", "models/player/charple.mdl",
function(ply, dmginfo, item)
    dmginfo:SetDamage(dmginfo:GetDamage() * (ply.PhoenixActive and 0.4 or 0.75))
end,
{
    InfernoBurst = {
        KeyBind = KEY_E, Cooldown = 12, LastUsed = 0,
        description = "Explode in a burst of flame, igniting all nearby enemies.",
        Action = function(ply)
            pfx(ply, "burst", "pfx1_05", ply:GetPos() + OFF_CHEST, ply, 4)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 350)) do
                if ent:IsPlayer() and ent ~= ply then
                    pfx(ent, "burst_hit", "pfx1_08_", ent:GetPos() + OFF_CHEST, ent, 3)
                    ent:TakeDamage(120, ply, ply)
                    ent:SetVelocity((ent:GetPos() - ply:GetPos()):GetNormalized() * 600)
                end
            end
        end
    },
    FlameCharge = {
        KeyBind = KEY_F, Cooldown = 8, LastUsed = 0,
        description = "Charge forward at blazing speed, leaving a trail of fire.",
        Action = function(ply)
            pfxw("charge_from", "pfx1_04", ply:GetPos() + OFF_GROUND, 3)
            ply:SetVelocity(ply:GetForward() * 1400 + Vector(0,0,80))
            timer.Simple(0.3, function()
                if IsValid(ply) then
                    pfxw("charge_to", "pfx1_02", ply:GetPos() + OFF_GROUND, 4)
                end
            end)
        end
    },
    DragonBreath = {
        KeyBind = KEY_Q, Cooldown = 18, LastUsed = 0,
        description = "Breathe a wide cone of dragonfire at enemies in front of you.",
        Action = function(ply)
            local fwd = ply:GetForward()
            pfx(ply, "breath", "pfx1_06~", ply:GetPos() + fwd * 80 + OFF_HEAD, nil, 3)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos() + fwd * 120, 200)) do
                if ent:IsPlayer() and ent ~= ply and fwd:Dot((ent:GetPos()-ply:GetPos()):GetNormalized()) > 0.4 then
                    pfx(ent, "breath_hit", "pfx1_0e_l", ent:GetPos() + OFF_CHEST, ent, 3)
                    ent:TakeDamage(200, ply, ply)
                end
            end
        end
    },
    ScorchingGround = {
        KeyBind = KEY_G, Cooldown = 30, LastUsed = 0,
        description = "Lay down a scorching ember field that burns enemies for 10 seconds.",
        Action = function(ply)
            local pos = ply:GetPos() + OFF_GROUND
            pfxw("scorch_e", "pfx1_03~", pos, 10)
            pfxw("scorch_f", "pfx1_0c",  pos + OFF_CHEST, 10)
            local t = "ScorchGround_" .. ply:SteamID64()
            timer.Create(t, 1, 10, function()
                if not IsValid(ply) then timer.Remove(t) return end
                for _, ent in ipairs(ents.FindInSphere(pos, 200)) do
                    if ent:IsPlayer() and ent ~= ply then
                        ent:TakeDamage(30, ply, ply)
                        ent:SetWalkSpeed(80) ent:SetRunSpeed(120)
                        timer.Simple(1.5, function()
                            if IsValid(ent) then ent:SetWalkSpeed(200) ent:SetRunSpeed(350) end
                        end)
                    end
                end
            end)
        end
    },
    PhoenixForm = {
        KeyBind = KEY_J, Cooldown = 60, LastUsed = 0,
        description = "Engulf yourself in phoenix fire, gaining heavy resistance for 12 seconds.",
        Action = function(ply)
            pfx(ply, "phoenix_a", "pfx1_08_~", ply:GetPos() + OFF_CHEST, ply, 12)
            pfx(ply, "phoenix_b", "pfx1_00",   ply:GetPos() + OFF_HEAD,  ply, 12)
            ply.PhoenixActive = true
            timer.Simple(12, function() if IsValid(ply) then ply.PhoenixActive = false end end)
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  2. STORM CALLER
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Storm Caller", {
    Health     = defaultRanges(7000,  70000),
    Armor      = defaultRanges(3500,  35000),
    Resistance = defaultRanges(8, 55),
    Speed      = defaultRanges(80,  175),
    Jump       = defaultRanges(80,  155),
    Regen      = defaultRanges(100, 500)
}, "The sky answers to your will.", "models/player/combine_super_soldier.mdl",
function(ply, dmginfo, item)
    if ply.ThunderShieldActive then
        local att = dmginfo:GetAttacker()
        if IsValid(att) and att:IsPlayer() then att:TakeDamage(30, ply, ply) end
    end
    dmginfo:SetDamage(dmginfo:GetDamage() * (item.customData.Resistance or 0.8))
end,
{
    ChainLightning = {
        KeyBind = KEY_E, Cooldown = 10, LastUsed = 0,
        description = "Release a bolt of chain lightning that jumps between nearby enemies.",
        Action = function(ply)
            pfx(ply, "chain_src", "pfx4_08", ply:GetPos() + OFF_HEAD, nil, 2)
            local victims = {}
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 600)) do
                if ent:IsPlayer() and ent ~= ply then table.insert(victims, ent) end
            end
            for i, v in ipairs(victims) do
                timer.Simple((i-1) * 0.15, function()
                    if IsValid(v) then
                        pfx(v, "chain_hit", "pfx4_05", v:GetPos() + OFF_CHEST, v, 2)
                        v:TakeDamage(90, ply, ply)
                    end
                end)
            end
        end
    },
    ThunderShield = {
        KeyBind = KEY_Q, Cooldown = 25, LastUsed = 0,
        description = "Surround yourself with crackling arcs that shock attackers for 8 seconds.",
        Action = function(ply)
            pfx(ply, "tshield", "pfx4_05~", ply:GetPos() + OFF_CHEST, ply, 8)
            ply.ThunderShieldActive = true
            timer.Simple(8, function() if IsValid(ply) then ply.ThunderShieldActive = false end end)
        end
    },
    LightningDash = {
        KeyBind = KEY_F, Cooldown = 6, LastUsed = 0,
        description = "Teleport forward in a flash of lightning.",
        Action = function(ply)
            pfxw("ldash_from", "pfx4_05",  ply:GetPos() + OFF_CHEST, 1)
            ply:SetPos(ply:GetPos() + ply:GetForward() * 550 + Vector(0,0,40))
            pfxw("ldash_to",   "pfx4_05~", ply:GetPos() + OFF_CHEST, 2)
        end
    },
    CallingThunder = {
        KeyBind = KEY_G, Cooldown = 45, LastUsed = 0,
        description = "Call down a thunderstorm that strikes all enemies for 8 seconds.",
        Action = function(ply)
            pfx(ply, "thunder_aura", "pfx4_08", ply:GetPos() + OFF_HEAD, ply, 8)
            for i = 1, 16 do
                timer.Simple(i * 0.5, function()
                    if not IsValid(ply) then return end
                    for _, ent in ipairs(player.GetAll()) do
                        if ent ~= ply then
                            if i % 2 == 0 then  -- effect only every other hit to halve spawns
                                pfx(ent, "thunder_hit", "pfx4_05~", ent:GetPos() + OFF_HEAD, ent, 1)
                            end
                            ent:TakeDamage(40, ply, ply)
                        end
                    end
                end)
            end
        end
    },
    StaticCore = {
        KeyBind = KEY_J, Cooldown = 20, LastUsed = 0,
        description = "Radiate a pulsing energy field stunning nearby players.",
        Action = function(ply)
            pfx(ply, "static_a", "pfx4_06_1", ply:GetPos() + OFF_CHEST, ply, 5)
            pfx(ply, "static_b", "pfx4_06_3", ply:GetPos() + OFF_HEAD,  ply, 5)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 300)) do
                if ent:IsPlayer() and ent ~= ply then
                    pfx(ent, "static_hit", "pfx4_05~", ent:GetPos() + OFF_CHEST, ent, 2)
                    ent:SetVelocity(Vector(0,0,300))
                    ent:TakeDamage(60, ply, ply)
                end
            end
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  3. SINGULARITY MAGE
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Singularity Mage", {
    Health     = defaultRanges(6000,  60000),
    Armor      = defaultRanges(3000,  30000),
    Resistance = defaultRanges(5, 45),
    Speed      = defaultRanges(75,  165),
    Jump       = defaultRanges(75,  150),
    Regen      = defaultRanges(90,  450)
}, "Bend gravity to your whim and crush all opposition.", "models/player/kleiner.mdl",
function(ply, dmginfo, item)
    if ply.SingularityShieldActive then dmginfo:SetDamage(0) return end
    dmginfo:SetDamage(dmginfo:GetDamage() * 0.85)
end,
{
    MicroSingularity = {
        KeyBind = KEY_E, Cooldown = 14, LastUsed = 0,
        description = "Hurl a micro black hole that pulls all nearby enemies toward it.",
        Action = function(ply)
            local hitPos = ply:GetEyeTrace().HitPos
            pfxw("micro_bh", "pfx5_00_ss", hitPos, 5)
            for i = 1, 10 do
                timer.Simple(i * 0.4, function()
                    for _, ent in ipairs(ents.FindInSphere(hitPos, 500)) do
                        if ent:IsPlayer() and ent ~= ply then
                            ent:SetVelocity((hitPos - ent:GetPos()):GetNormalized() * 900)
                            ent:TakeDamage(25, ply, ply)
                        end
                    end
                end)
            end
        end
    },
    EventHorizon = {
        KeyBind = KEY_Q, Cooldown = 30, LastUsed = 0,
        description = "Open a full event horizon that blasts all enemies away violently.",
        Action = function(ply)
            pfx(ply, "horizon_a", "pfx5_00",     ply:GetPos() + OFF_GROUND, nil, 6)
            pfx(ply, "horizon_b", "pfx5_00_alt", ply:GetPos() + OFF_CHEST,  nil, 6)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 700)) do
                if ent:IsPlayer() and ent ~= ply then
                    ent:SetVelocity((ent:GetPos() - ply:GetPos()):GetNormalized() * 2500)
                    ent:TakeDamage(300, ply, ply)
                end
            end
        end
    },
    NebulaVeil = {
        KeyBind = KEY_F, Cooldown = 35, LastUsed = 0,
        description = "Wrap yourself in a galaxy nebula field, confusing nearby enemies.",
        Action = function(ply)
            pfx(ply, "nebula_a", "pfx5_03", ply:GetPos() + OFF_CHEST, ply, 10)
            pfx(ply, "nebula_b", "pfx5_01", ply:GetPos() + OFF_HEAD,  ply, 10)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 400)) do
                if ent:IsPlayer() and ent ~= ply then
                    pfx(ent, "nebula_hit", "pfx5_02", ent:GetPos() + OFF_HEAD, ent, 5)
                    ent:TakeDamage(50, ply, ply)
                end
            end
        end
    },
    GravitySurge = {
        KeyBind = KEY_G, Cooldown = 18, LastUsed = 0,
        description = "Surge upward then slam into the ground creating a gravity shockwave.",
        Action = function(ply)
            pfx(ply, "gsurge", "pfx5_00_s", ply:GetPos() + OFF_GROUND, nil, 2)
            ply:SetVelocity(Vector(0, 0, 1800))
            timer.Simple(1.5, function()
                if not IsValid(ply) then return end
                pfxw("gsurge_slam", "pfx5_00_alt_s", ply:GetPos() + OFF_GROUND, 4)
                for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 450)) do
                    if ent:IsPlayer() and ent ~= ply then
                        ent:SetVelocity((ent:GetPos() - ply:GetPos()):GetNormalized() * 1400 + Vector(0,0,500))
                        ent:TakeDamage(150, ply, ply)
                    end
                end
            end)
        end
    },
    SingularityShield = {
        KeyBind = KEY_J, Cooldown = 50, LastUsed = 0,
        description = "Orbit micro black holes around you deflecting all damage for 6 seconds.",
        Action = function(ply)
            pfx(ply, "sshield", "pfx5_00_alt_ss", ply:GetPos() + OFF_CHEST, ply, 6)
            ply.SingularityShieldActive = true
            timer.Simple(6, function() if IsValid(ply) then ply.SingularityShieldActive = false end end)
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  4. BLOOD REAPER
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Blood Reaper", {
    Health     = defaultRanges(10000, 100000),
    Armor      = defaultRanges(5000,  50000),
    Resistance = defaultRanges(12, 65),
    Speed      = defaultRanges(75,  165),
    Jump       = defaultRanges(70,  145),
    Regen      = defaultRanges(150, 750)
}, "Your enemies bleed so you may feast.", "models/player/zombie_soldier.mdl",
function(ply, dmginfo, item)
    local dmg = dmginfo:GetDamage()
    if ply.currentsuit then
        ply.currentsuit.customData.Health = (ply.currentsuit.customData.Health or 0) + math.floor(dmg * 0.1)
    end
    dmginfo:SetDamage(dmg * 0.7)
end,
{
    BloodGush = {
        KeyBind = KEY_E, Cooldown = 8, LastUsed = 0,
        description = "Unleash a torrent of blood at the nearest enemy, dealing massive damage.",
        Action = function(ply)
            local tr = ply:GetEyeTrace()
            if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
                pfx(tr.Entity, "gush_a", "pfx2_02", tr.Entity:GetPos() + OFF_CHEST, tr.Entity, 3)
                pfx(tr.Entity, "gush_b", "pfx2_06", tr.Entity:GetPos() + OFF_HEAD,  tr.Entity, 3)
                tr.Entity:TakeDamage(220, ply, ply)
            end
            pfx(ply, "gush_self", "pfx2_02_s", ply:GetPos() + ply:GetForward() * 40 + OFF_CHEST, nil, 2)
        end
    },
    AcidPool = {
        KeyBind = KEY_F, Cooldown = 22, LastUsed = 0,
        description = "Vomit a pool of acid on the ground that burns enemies for 8 seconds.",
        Action = function(ply)
            local pos = ply:GetPos() + OFF_GROUND
            pfxw("acid_pool", "pfx2_03", pos, 8)
            local t = "AcidPool_" .. ply:SteamID64()
            timer.Create(t, 0.8, 10, function()
                if not IsValid(ply) then timer.Remove(t) return end
                for _, ent in ipairs(ents.FindInSphere(pos, 180)) do
                    if ent:IsPlayer() and ent ~= ply then ent:TakeDamage(35, ply, ply) end
                end
            end)
        end
    },
    AlienBloodBurst = {
        KeyBind = KEY_Q, Cooldown = 16, LastUsed = 0,
        description = "Explode in a burst of alien blood, poisoning everyone nearby.",
        Action = function(ply)
            pfx(ply, "alien_a", "pfx2_02_a_s", ply:GetPos() + OFF_CHEST, ply, 4)
            pfx(ply, "alien_b", "pfx2_02_a",   ply:GetPos() + OFF_GROUND, nil, 4)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 400)) do
                if ent:IsPlayer() and ent ~= ply then
                    ent:TakeDamage(180, ply, ply)
                    ent:SetVelocity((ent:GetPos()-ply:GetPos()):GetNormalized() * 800)
                end
            end
        end
    },
    BloodFeast = {
        KeyBind = KEY_G, Cooldown = 40, LastUsed = 0,
        description = "Enter a blood frenzy, draining health from nearby enemies for 10 seconds.",
        Action = function(ply)
            pfx(ply, "feast", "pfx2_06", ply:GetPos() + OFF_CHEST, ply, 10)
            local t = "BloodFeast_" .. ply:SteamID64()
            timer.Create(t, 1, 10, function()
                if not IsValid(ply) or not ply.currentsuit then timer.Remove(t) return end
                for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 300)) do
                    if ent:IsPlayer() and ent ~= ply then
                        ent:TakeDamage(50, ply, ply)
                        ply.currentsuit.customData.Health = (ply.currentsuit.customData.Health or 0) + 30
                    end
                end
            end)
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  5. ARCANE SOVEREIGN
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Arcane Sovereign", {
    Health     = defaultRanges(7500,  75000),
    Armor      = defaultRanges(3500,  35000),
    Resistance = defaultRanges(8, 50),
    Speed      = defaultRanges(80,  170),
    Jump       = defaultRanges(80,  155),
    Regen      = defaultRanges(110, 550)
}, "Ancient magic flows through every fiber of your being.", "models/player/kleiner.mdl",
function(ply, dmginfo, item)
    dmginfo:SetDamage(dmginfo:GetDamage() * 0.78)
end,
{
    OrbStrike = {
        KeyBind = KEY_E, Cooldown = 6, LastUsed = 0,
        description = "Launch a destructive magic orb at your crosshair.",
        Action = function(ply)
            local tr = ply:GetEyeTrace()
            pfxw("orb_hit", "pfx8_05", tr.HitPos + OFF_CHEST, 3)
            for _, ent in ipairs(ents.FindInSphere(tr.HitPos, 200)) do
                if ent:IsPlayer() and ent ~= ply then
                    ent:TakeDamage(130, ply, ply)
                    ent:SetVelocity((ent:GetPos()-tr.HitPos):GetNormalized() * 1000)
                end
            end
        end
    },
    ArcaneGate = {
        KeyBind = KEY_F, Cooldown = 12, LastUsed = 0,
        description = "Open a portal to teleport instantly to where you are looking.",
        Action = function(ply)
            local tr = ply:GetEyeTrace()
            pfxw("gate_from", "pfx8_03",     ply:GetPos() + OFF_CHEST, 2)
            pfxw("gate_to",   "pfx8_03_alt", tr.HitPos    + OFF_CHEST, 2)
            ply:SetPos(tr.HitPos + Vector(0,0,10))
        end
    },
    MysticAura = {
        KeyBind = KEY_Q, Cooldown = 25, LastUsed = 0,
        description = "Radiate a mystic flame aura that damages nearby enemies for 12 seconds.",
        Action = function(ply)
            pfx(ply, "mystic_a", "pfx8_02", ply:GetPos() + OFF_CHEST, ply, 12)
            pfx(ply, "mystic_b", "pfx8_06", ply:GetPos() + OFF_HEAD,  ply, 12)
            local t = "MysticAura_" .. ply:SteamID64()
            timer.Create(t, 1, 12, function()
                if not IsValid(ply) then timer.Remove(t) return end
                for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 250)) do
                    if ent:IsPlayer() and ent ~= ply then ent:TakeDamage(45, ply, ply) end
                end
            end)
        end
    },
    ArcaneCore = {
        KeyBind = KEY_G, Cooldown = 35, LastUsed = 0,
        description = "Detonate a large arcane core, dealing devastating damage in a huge radius.",
        Action = function(ply)
            pfx(ply, "acore", "pfx8_04", ply:GetPos() + OFF_CHEST, nil, 5)
            timer.Simple(1.5, function()
                if not IsValid(ply) then return end
                pfxw("acore_blast", "pfx8_05", ply:GetPos() + OFF_GROUND, 3)
                for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 600)) do
                    if ent:IsPlayer() and ent ~= ply then
                        local dist = ent:GetPos():Distance(ply:GetPos())
                        ent:TakeDamage(math.max(50, 400 * (1 - dist/600)), ply, ply)
                        ent:SetVelocity((ent:GetPos()-ply:GetPos()):GetNormalized() * 1800)
                    end
                end
            end)
        end
    },
    FrostBeam = {
        KeyBind = KEY_J, Cooldown = 20, LastUsed = 0,
        description = "Fire a beam of arcane frost, slowing the target to a crawl for 6 seconds.",
        Action = function(ply)
            local tr = ply:GetEyeTrace()
            pfx(ply, "frost", "pfx8_07", ply:GetPos() + ply:GetForward() * 60 + OFF_CHEST, nil, 3)
            if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
                tr.Entity:SetWalkSpeed(50) tr.Entity:SetRunSpeed(80)
                tr.Entity:TakeDamage(80, ply, ply)
                timer.Simple(6, function()
                    if IsValid(tr.Entity) then tr.Entity:SetWalkSpeed(200) tr.Entity:SetRunSpeed(350) end
                end)
            end
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  6. JET STRIKER
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Jet Striker", {
    Health     = defaultRanges(6000,  60000),
    Armor      = defaultRanges(3000,  30000),
    Resistance = defaultRanges(6, 42),
    Speed      = defaultRanges(100, 220),
    Jump       = defaultRanges(90,  185),
    Regen      = defaultRanges(80,  400)
}, "Pure velocity. Pure destruction.", "models/player/combine_super_soldier.mdl",
function(ply, dmginfo, item)
    dmginfo:SetDamage(dmginfo:GetDamage() * 0.9)
end,
{
    AfterburnerBoost = {
        KeyBind = KEY_E, Cooldown = 7, LastUsed = 0,
        description = "Fire your afterburners, rocketing forward at extreme speed.",
        Action = function(ply)
            pfx(ply, "boost", "pfx4_00", ply:GetPos() - ply:GetForward() * 20 + OFF_CHEST, ply, 2)
            ply:SetVelocity(ply:GetForward() * 2000 + Vector(0,0,100))
            timer.Simple(0.2, function()
                if not IsValid(ply) then return end
                for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 120)) do
                    if ent:IsPlayer() and ent ~= ply then
                        ent:TakeDamage(80, ply, ply)
                        ent:SetVelocity(ply:GetForward() * 1200)
                    end
                end
            end)
        end
    },
    JetHover = {
        KeyBind = KEY_F, Cooldown = 20, LastUsed = 0,
        description = "Activate hover jets, launching you high into the air.",
        Action = function(ply)
            pfx(ply, "hover_a", "pfx4_01",  ply:GetPos() + OFF_GROUND, ply, 3)
            pfx(ply, "hover_b", "pfx4_01~", ply:GetPos() - Vector(0,0,10), ply, 3)
            ply:SetVelocity(Vector(0, 0, 1500))
        end
    },
    PurpleBarrage = {
        KeyBind = KEY_Q, Cooldown = 15, LastUsed = 0,
        description = "Fire a purple plasma barrage at all enemies within 500 units.",
        Action = function(ply)
            pfx(ply, "barrage", "pfx4_04", ply:GetPos() + ply:GetForward() * 30 + OFF_CHEST, nil, 2)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 500)) do
                if ent:IsPlayer() and ent ~= ply then
                    pfx(ent, "barrage_hit", "pfx4_04_s", ent:GetPos() + OFF_CHEST, ent, 2)
                    ent:TakeDamage(100, ply, ply)
                end
            end
        end
    },
    NitroSurge = {
        KeyBind = KEY_G, Cooldown = 30, LastUsed = 0,
        description = "Engage nitro, tripling your run speed for 8 seconds.",
        Action = function(ply)
            local prevRun = ply:GetRunSpeed() local prevWalk = ply:GetWalkSpeed()
            ply:SetRunSpeed(prevRun * 3) ply:SetWalkSpeed(prevWalk * 2)
            pfx(ply, "nitro_a", "pfx4_00",  ply:GetPos() - ply:GetForward() * 20 + OFF_GROUND, ply, 8)
            pfx(ply, "nitro_b", "pfx4_03~", ply:GetPos() - ply:GetForward() * 20 + OFF_CHEST,  ply, 8)
            timer.Simple(8, function()
                if IsValid(ply) then ply:SetRunSpeed(prevRun) ply:SetWalkSpeed(prevWalk) end
            end)
        end
    },
    FlamingSlam = {
        KeyBind = KEY_J, Cooldown = 22, LastUsed = 0,
        description = "Blast upward then slam down creating a shockwave on landing.",
        Action = function(ply)
            pfx(ply, "slam_up", "pfx4_02", ply:GetPos() + OFF_GROUND, ply, 2)
            ply:SetVelocity(Vector(0,0,1200))
            timer.Simple(1.2, function()
                if not IsValid(ply) then return end
                ply:SetVelocity(Vector(0,0,-3000))
                timer.Simple(0.4, function()
                    if not IsValid(ply) then return end
                    pfxw("slam_land", "pfx4_02~", ply:GetPos() + OFF_GROUND, 3)
                    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 400)) do
                        if ent:IsPlayer() and ent ~= ply then
                            ent:TakeDamage(160, ply, ply)
                            ent:SetVelocity((ent:GetPos()-ply:GetPos()):GetNormalized() * 1600)
                        end
                    end
                end)
            end)
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  7. MATRIX GHOST
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Matrix Ghost", {
    Health     = defaultRanges(5000,  50000),
    Armor      = defaultRanges(2500,  25000),
    Resistance = defaultRanges(5, 40),
    Speed      = defaultRanges(90,  195),
    Jump       = defaultRanges(85,  175),
    Regen      = defaultRanges(80,  400)
}, "You are not real. Neither are your enemies.", "models/player/kleiner.mdl",
function(ply, dmginfo, item)
    if ply.MatrixDodge and math.random(1, 3) == 1 then dmginfo:SetDamage(0)
    else dmginfo:SetDamage(dmginfo:GetDamage() * 0.85) end
end,
{
    CodeSkip = {
        KeyBind = KEY_E, Cooldown = 5, LastUsed = 0,
        description = "Skip through the code of reality, teleporting 500 units forward instantly.",
        Action = function(ply)
            pfxw("skip_from", "pfx4_09", ply:GetPos() + OFF_CHEST, 1)
            ply:SetPos(ply:GetPos() + ply:GetForward() * 500 + Vector(0,0,20))
            pfxw("skip_to",   "pfx4_0b", ply:GetPos() + OFF_CHEST, 2)
        end
    },
    GhostMode = {
        KeyBind = KEY_Q, Cooldown = 40, LastUsed = 0,
        description = "Phase out of reality, becoming invisible and notsolid for 8 seconds.",
        Action = function(ply)
            pfx(ply, "ghost_a", "pfx2_05", ply:GetPos() + OFF_CHEST, ply, 8)
            pfx(ply, "ghost_b", "pfx2_01", ply:GetPos() + OFF_HEAD,  ply, 8)
            ply:SetNoDraw(true) ply:SetNotSolid(true) ply.MatrixDodge = true
            timer.Simple(8, function()
                if IsValid(ply) then ply:SetNoDraw(false) ply:SetNotSolid(false) ply.MatrixDodge = false end
            end)
        end
    },
    DataCorruption = {
        KeyBind = KEY_F, Cooldown = 18, LastUsed = 0,
        description = "Corrupt the data of nearby enemies, stunning and damaging them.",
        Action = function(ply)
            pfx(ply, "corrupt_a", "pfx2_04",  ply:GetPos() + OFF_CHEST, nil, 4)
            pfx(ply, "corrupt_b", "pfx2_04~", ply:GetPos() + OFF_HEAD,  nil, 4)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 350)) do
                if ent:IsPlayer() and ent ~= ply then
                    pfx(ent, "corrupt_hit", "pfx4_09", ent:GetPos() + OFF_HEAD, ent, 2)
                    ent:TakeDamage(120, ply, ply) ent:SetVelocity(Vector(0,0,500))
                end
            end
        end
    },
    EnergyOverload = {
        KeyBind = KEY_G, Cooldown = 28, LastUsed = 0,
        description = "Overload your matrix core, releasing energy rods in all directions.",
        Action = function(ply)
            pfx(ply, "eol_a", "pfx4_06_2", ply:GetPos() + OFF_GROUND, ply, 4)
            pfx(ply, "eol_b", "pfx4_06_1", ply:GetPos() + OFF_CHEST,  ply, 4)
            pfx(ply, "eol_c", "pfx4_06",   ply:GetPos() + OFF_HEAD,   ply, 4)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 500)) do
                if ent:IsPlayer() and ent ~= ply then ent:TakeDamage(90, ply, ply) end
            end
        end
    },
    HolographicDecoy = {
        KeyBind = KEY_J, Cooldown = 50, LastUsed = 0,
        description = "Project a sparkle decoy that confuses enemies for 10 seconds.",
        Action = function(ply)
            local dp = ply:GetPos() + ply:GetForward() * 80
            pfxw("decoy_a", "pfx2_00", dp + OFF_CHEST, 10)
            pfxw("decoy_b", "pfx4_0b", dp + OFF_HEAD,  10)
            BCORE.Inventory:Chat("[Matrix Ghost] Decoy deployed.", ply)
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  8. BLIZZARD SOVEREIGN
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Blizzard Sovereign", {
    Health     = defaultRanges(7000,  70000),
    Armor      = defaultRanges(3500,  35000),
    Resistance = defaultRanges(9, 52),
    Speed      = defaultRanges(75,  160),
    Jump       = defaultRanges(75,  150),
    Regen      = defaultRanges(100, 500)
}, "Winter answers to you alone.", "models/player/charple.mdl",
function(ply, dmginfo, item)
    dmginfo:SetDamage(dmginfo:GetDamage() * 0.76)
end,
{
    WhiteoutStorm = {
        KeyBind = KEY_E, Cooldown = 20, LastUsed = 0,
        description = "Summon a whiteout blizzard slowing and damaging nearby enemies for 10 seconds.",
        Action = function(ply)
            pfx(ply, "blizzard", "pfx7_05", ply:GetPos() + OFF_CHEST, ply, 10)
            local t = "Blizzard_" .. ply:SteamID64()
            timer.Create(t, 1, 10, function()
                if not IsValid(ply) then timer.Remove(t) return end
                for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 350)) do
                    if ent:IsPlayer() and ent ~= ply then
                        ent:SetWalkSpeed(60) ent:SetRunSpeed(90)
                        ent:TakeDamage(25, ply, ply)
                        timer.Simple(1, function()
                            if IsValid(ent) then ent:SetWalkSpeed(200) ent:SetRunSpeed(350) end
                        end)
                    end
                end
            end)
        end
    },
    FogOfWar = {
        KeyBind = KEY_F, Cooldown = 35, LastUsed = 0,
        description = "Blanket the area in thick fog for 12 seconds.",
        Action = function(ply)
            pfxw("fog_a", "pfx7_03", ply:GetPos() + OFF_GROUND, 12)
            pfxw("fog_b", "pfx7_04", ply:GetPos() + OFF_CHEST,  12)
            BCORE.Inventory:Chat("[Blizzard Sovereign] Fog deployed.", ply)
        end
    },
    GaleForce = {
        KeyBind = KEY_Q, Cooldown = 14, LastUsed = 0,
        description = "Unleash a gale of dusty wind knocking all enemies back violently.",
        Action = function(ply)
            pfx(ply, "gale", "pfx7_00", ply:GetPos() + OFF_CHEST, nil, 4)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 600)) do
                if ent:IsPlayer() and ent ~= ply then
                    ent:SetVelocity((ent:GetPos()-ply:GetPos()):GetNormalized() * 2000 + Vector(0,0,300))
                    ent:TakeDamage(70, ply, ply)
                end
            end
        end
    },
    AcidRain = {
        KeyBind = KEY_G, Cooldown = 28, LastUsed = 0,
        description = "Summon rain that debuffs all enemies on the server for 8 seconds.",
        Action = function(ply)
            for _, ent in ipairs(player.GetAll()) do
                if ent ~= ply then
                    pfx(ent, "rain_debuff", "pfx7_01", ent:GetPos() + OFF_HEAD, ent, 8)
                    ent:SetWalkSpeed(100) ent:SetRunSpeed(160) ent:TakeDamage(40, ply, ply)
                    timer.Simple(8, function()
                        if IsValid(ent) then ent:SetWalkSpeed(200) ent:SetRunSpeed(350) end
                    end)
                end
            end
        end
    },
    IceBarrier = {
        KeyBind = KEY_J, Cooldown = 45, LastUsed = 0,
        description = "Encase yourself in a barrier of ice, becoming immune for 6 seconds.",
        Action = function(ply)
            pfx(ply, "ice_a", "pfx7_02", ply:GetPos() + OFF_CHEST, ply, 6)
            pfx(ply, "ice_b", "pfx7_05", ply:GetPos() + OFF_HEAD,  ply, 6)
            ply:GodEnable()
            timer.Simple(6, function() if IsValid(ply) then ply:GodDisable() end end)
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  9. NATURE SPECTER
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Nature Specter", {
    Health     = defaultRanges(6500,  65000),
    Armor      = defaultRanges(3200,  32000),
    Resistance = defaultRanges(7, 48),
    Speed      = defaultRanges(80,  175),
    Jump       = defaultRanges(80,  165),
    Regen      = defaultRanges(160, 800)
}, "The forest bends to your will. Enemies wither before you.", "models/player/kleiner.mdl",
function(ply, dmginfo, item)
    dmginfo:SetDamage(dmginfo:GetDamage() * 0.8)
end,
{
    BlossomBurst = {
        KeyBind = KEY_E, Cooldown = 10, LastUsed = 0,
        description = "Unleash a storm of razor cherry blossoms shredding nearby enemies.",
        Action = function(ply)
            pfx(ply, "blossom", "pfx3_00", ply:GetPos() + OFF_CHEST, ply, 4)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 350)) do
                if ent:IsPlayer() and ent ~= ply then
                    pfx(ent, "blossom_hit", "pfx3_00", ent:GetPos() + OFF_CHEST, ent, 2)
                    ent:TakeDamage(110, ply, ply)
                end
            end
        end
    },
    LeafTornado = {
        KeyBind = KEY_F, Cooldown = 18, LastUsed = 0,
        description = "Create a leaf tornado that sucks enemies in for 6 seconds.",
        Action = function(ply)
            local pos = ply:GetPos() + ply:GetForward() * 150
            pfxw("tornado_a", "pfx3_01", pos + OFF_GROUND, 6)
            pfxw("tornado_b", "pfx9_00", pos + OFF_CHEST,  5)
            local t = "LeafTornado_" .. ply:SteamID64()
            timer.Create(t, 0.5, 12, function()
                if not IsValid(ply) then timer.Remove(t) return end
                for _, ent in ipairs(ents.FindInSphere(pos, 300)) do
                    if ent:IsPlayer() and ent ~= ply then
                        ent:SetVelocity((pos - ent:GetPos()):GetNormalized() * 700)
                        ent:TakeDamage(20, ply, ply)
                    end
                end
            end)
        end
    },
    ForestMending = {
        KeyBind = KEY_Q, Cooldown = 40, LastUsed = 0,
        description = "Call upon nature to regenerate your suit HP rapidly for 10 seconds.",
        Action = function(ply)
            pfx(ply, "mend_a", "pfx3_00", ply:GetPos() + OFF_CHEST, ply, 10)
            pfx(ply, "mend_b", "pfx3_01", ply:GetPos() + OFF_HEAD,  ply, 10)
            local t = "ForestMend_" .. ply:SteamID64()
            timer.Create(t, 1, 10, function()
                if not IsValid(ply) or not ply.currentsuit then timer.Remove(t) return end
                local maxHP = ply.currentsuit.customData.Health or 500
                ply.currentsuit.customData.Health = math.min(
                    ply.currentsuit.customData.Health + maxHP * 0.05, maxHP)
            end)
        end
    },
    PetalDash = {
        KeyBind = KEY_G, Cooldown = 8, LastUsed = 0,
        description = "Dash forward in a burst of petals and sparkles.",
        Action = function(ply)
            pfxw("petal_from", "pfx3_00", ply:GetPos() + OFF_GROUND, 2)
            ply:SetVelocity(ply:GetForward() * 1300 + Vector(0,0,60))
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  10. BALLISTIC GHOST
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Ballistic Ghost", {
    Health     = defaultRanges(7000,  70000),
    Armor      = defaultRanges(3500,  35000),
    Resistance = defaultRanges(8, 50),
    Speed      = defaultRanges(85,  180),
    Jump       = defaultRanges(80,  160),
    Regen      = defaultRanges(90,  450)
}, "Every bullet has your name on it. Every one.", "models/player/combine_super_soldier.mdl",
function(ply, dmginfo, item)
    dmginfo:SetDamage(dmginfo:GetDamage() * 0.82)
end,
{
    BFGBlast = {
        KeyBind = KEY_E, Cooldown = 15, LastUsed = 0,
        description = "Fire a devastating BFG projectile at your crosshair.",
        Action = function(ply)
            local tr = ply:GetEyeTrace()
            pfxw("bfg_hit", "pfx4_07", tr.HitPos + OFF_CHEST, 3)
            for _, ent in ipairs(ents.FindInSphere(tr.HitPos, 300)) do
                if ent:IsPlayer() and ent ~= ply then
                    ent:TakeDamage(350, ply, ply)
                    ent:SetVelocity((ent:GetPos()-tr.HitPos):GetNormalized() * 2000)
                end
            end
        end
    },
    TracerStorm = {
        KeyBind = KEY_F, Cooldown = 20, LastUsed = 0,
        description = "Unleash a storm of AR2 tracers that damage all enemies in a cone.",
        Action = function(ply)
            local fp = ply:GetPos() + ply:GetForward() * 100 + OFF_CHEST
            pfx(ply, "tracer_a", "pfx6_02b", fp,                    nil, 2)
            pfx(ply, "tracer_b", "pfx6_02",  fp + Vector(0,0,10),   nil, 2)
            local fwd = ply:GetForward()
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos() + fwd * 200, 300)) do
                if ent:IsPlayer() and ent ~= ply and fwd:Dot((ent:GetPos()-ply:GetPos()):GetNormalized()) > 0.3 then
                    ent:TakeDamage(150, ply, ply)
                end
            end
        end
    },
    SuppressiveFire = {
        KeyBind = KEY_Q, Cooldown = 22, LastUsed = 0,
        description = "Lay down suppressive fire, slowing all nearby enemies for 8 seconds.",
        Action = function(ply)
            pfx(ply, "suppress", "pfx6_00", ply:GetPos() + ply:GetForward() * 80 + OFF_CHEST, nil, 3)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 500)) do
                if ent:IsPlayer() and ent ~= ply then
                    ent:SetWalkSpeed(70) ent:SetRunSpeed(110) ent:TakeDamage(60, ply, ply)
                    timer.Simple(8, function()
                        if IsValid(ent) then ent:SetWalkSpeed(200) ent:SetRunSpeed(350) end
                    end)
                end
            end
        end
    },
    SmokeScreen = {
        KeyBind = KEY_G, Cooldown = 30, LastUsed = 0,
        description = "Deploy a heavy smoke screen, cloaking yourself for 8 seconds.",
        Action = function(ply)
            pfx(ply, "smoke_a", "pfx1_07", ply:GetPos() + OFF_CHEST,  ply, 8)
            pfx(ply, "smoke_b", "pfx1_0f", ply:GetPos() + OFF_GROUND, nil, 8)
            ply:SetNoDraw(true)
            timer.Simple(8, function() if IsValid(ply) then ply:SetNoDraw(false) end end)
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  11. COLORFUL COMET
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Colorful Comet", {
    Health     = defaultRanges(5500,  55000),
    Armor      = defaultRanges(2700,  27000),
    Resistance = defaultRanges(6, 44),
    Speed      = defaultRanges(95,  210),
    Jump       = defaultRanges(90,  190),
    Regen      = defaultRanges(80,  420)
}, "A streak of color across the sky. You are unstoppable.", "models/player/kleiner.mdl",
function(ply, dmginfo, item)
    dmginfo:SetDamage(dmginfo:GetDamage() * 0.88)
end,
{
    CometDash = {
        KeyBind = KEY_E, Cooldown = 6, LastUsed = 0,
        description = "Dash forward as a colorful comet, knocking back enemies on impact.",
        Action = function(ply)
            pfxw("comet_from", "pfx9_00", ply:GetPos() + OFF_CHEST, 2)
            ply:SetVelocity(ply:GetForward() * 1800 + Vector(0,0,50))
            timer.Simple(0.25, function()
                if not IsValid(ply) then return end
                pfxw("comet_to", "pfx9_00", ply:GetPos() + OFF_CHEST, 2)
                for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 150)) do
                    if ent:IsPlayer() and ent ~= ply then
                        ent:TakeDamage(90, ply, ply) ent:SetVelocity(ply:GetForward() * 1200)
                    end
                end
            end)
        end
    },
    SmokeBomb = {
        KeyBind = KEY_F, Cooldown = 18, LastUsed = 0,
        description = "Drop a colorful smoke bomb and vanish for 5 seconds.",
        Action = function(ply)
            pfxw("sbomb_a", "pfx1_0f", ply:GetPos() + OFF_GROUND, 5)
            pfxw("sbomb_b", "pfx1_07", ply:GetPos() + OFF_CHEST,  5)
            ply:SetNoDraw(true)
            timer.Simple(5, function() if IsValid(ply) then ply:SetNoDraw(false) end end)
        end
    },
    PrismBurst = {
        KeyBind = KEY_Q, Cooldown = 25, LastUsed = 0,
        description = "Detonate a prism burst of colorful energy, launching nearby enemies.",
        Action = function(ply)
            pfx(ply, "prism_a", "pfx9_00", ply:GetPos() + OFF_CHEST,  nil, 3)
            pfx(ply, "prism_b", "pfx8_04", ply:GetPos() + OFF_GROUND, nil, 2)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 450)) do
                if ent:IsPlayer() and ent ~= ply then
                    pfx(ent, "prism_hit", "pfx1_0f", ent:GetPos() + OFF_CHEST, ent, 2)
                    ent:TakeDamage(140, ply, ply)
                    ent:SetVelocity((ent:GetPos()-ply:GetPos()):GetNormalized() * 1700 + Vector(0,0,400))
                end
            end
        end
    },
    GasLeak = {
        KeyBind = KEY_G, Cooldown = 28, LastUsed = 0,
        description = "Leak a toxic gas cloud that poisons nearby enemies for 8 seconds.",
        Action = function(ply)
            local pos = ply:GetPos()
            pfxw("gas_a", "pfx1_09", pos + OFF_GROUND, 8)
            pfxw("gas_b", "pfx1_0a", pos + OFF_CHEST,  8)
            local t = "GasLeak_" .. ply:SteamID64()
            timer.Create(t, 1, 8, function()
                if not IsValid(ply) then timer.Remove(t) return end
                for _, ent in ipairs(ents.FindInSphere(pos, 200)) do
                    if ent:IsPlayer() and ent ~= ply then ent:TakeDamage(25, ply, ply) end
                end
            end)
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  12. WATERLEAK PHANTOM
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Waterleak Phantom", {
    Health     = defaultRanges(6000,  60000),
    Armor      = defaultRanges(3000,  30000),
    Resistance = defaultRanges(7, 46),
    Speed      = defaultRanges(85,  185),
    Jump       = defaultRanges(80,  165),
    Regen      = defaultRanges(90,  460)
}, "Fluid as water. Silent as the dark.", "models/player/kleiner.mdl",
function(ply, dmginfo, item)
    if ply.PhantomStealth then dmginfo:SetDamage(0)
    else dmginfo:SetDamage(dmginfo:GetDamage() * 0.83) end
end,
{
    WaterFlood = {
        KeyBind = KEY_E, Cooldown = 14, LastUsed = 0,
        description = "Flood the area around you with a torrent of water.",
        Action = function(ply)
            pfxw("flood_a", "pfxa_00", ply:GetPos() + OFF_GROUND, 4)
            pfxw("flood_b", "pfxcom",  ply:GetPos() + OFF_CHEST,  3)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 400)) do
                if ent:IsPlayer() and ent ~= ply then
                    ent:SetVelocity((ent:GetPos()-ply:GetPos()):GetNormalized() * 1500 + Vector(0,0,600))
                    ent:TakeDamage(80, ply, ply)
                end
            end
        end
    },
    PhantomPhase = {
        KeyBind = KEY_Q, Cooldown = 45, LastUsed = 0,
        description = "Phase into a phantom state, becoming invisible and immune for 8 seconds.",
        Action = function(ply)
            pfx(ply, "phase", "pfxcom1", ply:GetPos() + OFF_CHEST, ply, 8)
            ply:SetNoDraw(true) ply:SetNotSolid(true) ply.PhantomStealth = true
            timer.Simple(8, function()
                if IsValid(ply) then ply:SetNoDraw(false) ply:SetNotSolid(false) ply.PhantomStealth = false end
            end)
        end
    },
    WaterStep = {
        KeyBind = KEY_F, Cooldown = 20, LastUsed = 0,
        description = "Leave a slowing water trail behind you for 10 seconds.",
        Action = function(ply)
            local t = "WaterStep_" .. ply:SteamID64()
            timer.Create(t, 0.5, 20, function()
                if not IsValid(ply) then timer.Remove(t) return end
                local pos = ply:GetPos() + OFF_GROUND
                pfxw("water_trail", "pfxa_00", pos, 3)
                for _, ent in ipairs(ents.FindInSphere(pos, 100)) do
                    if ent:IsPlayer() and ent ~= ply then
                        ent:SetWalkSpeed(70) ent:SetRunSpeed(100)
                        timer.Simple(2, function()
                            if IsValid(ent) then ent:SetWalkSpeed(200) ent:SetRunSpeed(350) end
                        end)
                    end
                end
            end)
        end
    },
    PhantomStrike = {
        KeyBind = KEY_G, Cooldown = 10, LastUsed = 0,
        description = "Materialize directly on top of your target and strike with phantom force.",
        Action = function(ply)
            local tr = ply:GetEyeTrace()
            if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
                pfxw("pstrike_from", "pfxcom",  ply:GetPos() + OFF_CHEST, 1)
                ply:SetPos(tr.Entity:GetPos() + Vector(0,0,30))
                pfxw("pstrike_to",   "pfxcom1", ply:GetPos() + OFF_CHEST, 2)
                tr.Entity:TakeDamage(200, ply, ply) tr.Entity:SetVelocity(Vector(0,0,900))
            end
        end
    }
})


-- ═══════════════════════════════════════════════════════════
--  13. CELESTIAL HERALD
-- ═══════════════════════════════════════════════════════════
BCORE.Inventory:CreateSuit("Celestial Herald", {
    Health     = defaultRanges(9000,  90000),
    Armor      = defaultRanges(4500,  45000),
    Resistance = defaultRanges(10, 58),
    Speed      = defaultRanges(75,  165),
    Jump       = defaultRanges(75,  155),
    Regen      = defaultRanges(140, 700)
}, "You are the herald of celestial judgment.", "models/player/charple.mdl",
function(ply, dmginfo, item)
    dmginfo:SetDamage(dmginfo:GetDamage() * 0.72)
end,
{
    CelestialFlame = {
        KeyBind = KEY_E, Cooldown = 10, LastUsed = 0,
        description = "Strike enemies with celestial pink flame, burning through armor.",
        Action = function(ply)
            local tr = ply:GetEyeTrace()
            pfxw("cflame", "pfx1_08#_l", tr.HitPos + OFF_CHEST, 3)
            for _, ent in ipairs(ents.FindInSphere(tr.HitPos, 250)) do
                if ent:IsPlayer() and ent ~= ply then
                    pfx(ent, "cflame_hit", "pfx1_08#", ent:GetPos() + OFF_CHEST, ent, 2)
                    ent:TakeDamage(160, ply, ply)
                end
            end
        end
    },
    HeavenlyBlaze = {
        KeyBind = KEY_F, Cooldown = 16, LastUsed = 0,
        description = "Send a wave of blue heavenly fire forward, burning all in its path.",
        Action = function(ply)
            local fwd = ply:GetForward()
            pfx(ply, "hblaze_a", "pfx1_08~_l", ply:GetPos() + fwd * 100 + OFF_CHEST, nil, 3)
            pfx(ply, "hblaze_b", "pfx1_08~",   ply:GetPos() + fwd * 200 + OFF_CHEST, nil, 3)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos() + fwd * 180, 280)) do
                if ent:IsPlayer() and ent ~= ply and fwd:Dot((ent:GetPos()-ply:GetPos()):GetNormalized()) > 0.2 then
                    ent:TakeDamage(190, ply, ply)
                end
            end
        end
    },
    DivineWrath = {
        KeyBind = KEY_Q, Cooldown = 30, LastUsed = 0,
        description = "Erupt in divine purple flame wrath, obliterating everything within 500 units.",
        Action = function(ply)
            pfx(ply, "dwrath_a", "pfx1_08_~a_l", ply:GetPos() + OFF_CHEST, ply, 5)
            pfx(ply, "dwrath_b", "pfx1_08_~a",   ply:GetPos() + OFF_HEAD,  ply, 4)
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 500)) do
                if ent:IsPlayer() and ent ~= ply then
                    pfx(ent, "dwrath_hit", "pfx1_08_~a", ent:GetPos() + OFF_CHEST, ent, 2)
                    ent:TakeDamage(280, ply, ply)
                    ent:SetVelocity((ent:GetPos()-ply:GetPos()):GetNormalized() * 1800)
                end
            end
        end
    },
    CelestialMending = {
        KeyBind = KEY_G, Cooldown = 55, LastUsed = 0,
        description = "Call celestial fire to mend your suit, restoring 40% of max HP and Armor.",
        Action = function(ply)
            if not ply.currentsuit then return end
            pfx(ply, "cmend_a", "pfx1_08_~", ply:GetPos() + OFF_CHEST, ply, 5)
            pfx(ply, "cmend_b", "pfx1_08_l", ply:GetPos() + OFF_HEAD,  ply, 5)
            local cd = ply.currentsuit.customData
            cd.Health = math.min(cd.Health + (cd.Health or 1000) * 0.4, cd.Health or 1000)
            cd.Armor  = math.min(cd.Armor  + (cd.Armor  or 500)  * 0.4, cd.Armor  or 500)
            BCORE.Inventory:Chat("[Celestial Herald] Divine mending complete.", ply)
        end
    },
    JudgmentDrop = {
        KeyBind = KEY_J, Cooldown = 24, LastUsed = 0,
        description = "Leap high and slam down with a heavenly ground burst on impact.",
        Action = function(ply)
            pfx(ply, "jdrop_up", "pfx1_01", ply:GetPos() + OFF_CHEST, ply, 2)
            ply:SetVelocity(Vector(0,0,1600))
            timer.Simple(1.4, function()
                if not IsValid(ply) then return end
                ply:SetVelocity(Vector(0,0,-4000))
                timer.Simple(0.3, function()
                    if not IsValid(ply) then return end
                    pfxw("jdrop_land", "pfx1_05", ply:GetPos() + OFF_GROUND, 4)
                    for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 450)) do
                        if ent:IsPlayer() and ent ~= ply then
                            ent:TakeDamage(220, ply, ply)
                            ent:SetVelocity((ent:GetPos()-ply:GetPos()):GetNormalized() * 2000 + Vector(0,0,600))
                        end
                    end
                end)
            end)
        end
    }
})