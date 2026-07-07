-- ============================================================
--  sv_modifiers.lua  —  Fixed
--  Bugs fixed:
--   1. modifiereffect: pcall around ents.Create/Spawn; timer
--      no longer wipes a newer entity when it fires late
--   2. void: "if not ent == attacker" precedence bug fixed → ent ~= attacker
--   3. shadow_step: teleported receiver (victim); now teleports attacker
--      with a trace to avoid landing inside walls
--   4. Socket hook: ipairs(modData.stats) skipped all keys → pairs()
--   5. Upgrade: crash when item.customData is nil → nil guard added
--   6. disarm: DropWeapon wrapped in pcall
-- ============================================================

-- ── Effect entity cache ───────────────────────────────────────
local activeEffects = {}

-- Safely spawn a server-side particle/effect entity.
-- Wrapped in pcall so a broken entity class can't bring down the server.
-- Timer guard prevents a late-firing callback from wiping a newer entity.
local function modifiereffect(class, pos, target)
    if IsValid(activeEffects[class]) then
        activeEffects[class]:Remove()
    end

    local ok, e = pcall(function()
        local ent = ents.Create(class)
        if not IsValid(ent) then return nil end
        ent:SetPos(pos)
        ent:Spawn()
        if IsValid(target) then
            ent:SetParent(target)
        end
        return ent
    end)

    if not ok then
        -- entity class doesn't exist or Spawn() errored — fail silently
        return
    end

    if not IsValid(e) then return end

    activeEffects[class] = e

    -- Only remove THIS specific entity when the timer fires.
    -- If modifiereffect is called again for the same class before the
    -- timer fires, activeEffects[class] will already point to the
    -- new entity, so we only clear the slot when it still matches.
    timer.Simple(3, function()
        if IsValid(e) then e:Remove() end
        if activeEffects[class] == e then
            activeEffects[class] = nil
        end
    end)
end

-- ── Item action handlers (Drop / Destroy / Upgrade) ───────────
local modifier = {}

modifier.Drop = function(item, ply)
    local pos = ply:GetPos() + Vector(0, 0, 50) + ply:GetForward() * 60
    item:SpawnItem(pos)
    ply:RemoveItem(item)
end

modifier.Destroy = function(item, ply)
    ply:RemoveItem(item)
end

modifier.Upgrade = function(item, ply)
    -- Guard: customData may be nil on freshly-created items
    if not item.customData or not item.customData.Type then
        BCORE.Inventory:Chat("This item has no modifier type set.", ply)
        return
    end

    local currentRarity = item.rarity

    if currentRarity == BCORE.Inventory:GetHighestRarity() then
        BCORE.Inventory:Chat("Your " .. item.name .. " is already at the highest rarity!", ply)
        return
    end

    local nextRarity = BCORE.Inventory:GetNextRarity(currentRarity)
    if not nextRarity then
        BCORE.Inventory:Chat("Error determining next rarity for " .. item.name .. "!", ply)
        return
    end

    local modifierDef = BCORE.Inventory.Modifiers[item.customData.Type]
    if not modifierDef then
        BCORE.Inventory:Chat("No modifiers found for this item type!", ply)
        return
    end

    for statName, rarityTable in pairs(modifierDef.stats) do
        local currentValue  = item:GetProperty(statName) or 0
        local nextStatData  = rarityTable[nextRarity]

        if nextStatData then
            local scale     = 1000
            local minScaled = math.floor(nextStatData.min * scale)
            local maxScaled = math.floor(nextStatData.max * scale)
            local newValue  = math.random(minScaled, maxScaled) / scale
            item:SetProperty(statName, newValue)
        else
            item:SetProperty(statName, math.ceil(currentValue * 1.05))
        end
    end

    item.rarity = nextRarity
    ply:UpdateItem(item)
    BCORE.Inventory:Chat("Your " .. item.name .. " has been upgraded to " .. nextRarity .. "!", ply)
    BCORE.Inventory.Admin:LogAction(ply, "upgrade", item.id)
end

BCORE.Inventory:RegisterType("Modifier", modifier)

local modifiers    = BCORE.Inventory.Modifiers
local servertable  = {}

local function createModifier(name, stats, description, onHitFunction, modifyFunction)
    local mod         = {}
    mod.stats         = stats
    mod.description   = description
    mod.OnHit         = onHitFunction
    mod.Modify        = modifyFunction
    mod.Type          = name
    modifiers[name]   = { stats = stats, description = description }
    servertable[name] = mod
end

-- ══════════════════════════════════════════════════════════════
--  BASE MODIFIERS
-- ══════════════════════════════════════════════════════════════

createModifier("fire", {
    Chance = {
        Common = {min=0.10,max=0.20}, Uncommon = {min=0.20,max=0.35}, Rare = {min=0.35,max=0.50},
        Epic = {min=0.50,max=0.65}, Legendary = {min=0.65,max=0.80}, Celestial = {min=0.80,max=0.95},
        God = {min=0.95,max=1.10}, Glitched = {min=1.10,max=1.25}, ["????????"] = {min=1.25,max=1.40}
    },
    Resistance = {
        Common = {min=0.90,max=1.00}, Uncommon = {min=0.80,max=0.90}, Rare = {min=0.70,max=0.80},
        Epic = {min=0.60,max=0.70}, Legendary = {min=0.50,max=0.60}, Celestial = {min=0.40,max=0.50},
        God = {min=0.30,max=0.40}, Glitched = {min=0.20,max=0.30}, ["????????"] = {min=0.10,max=0.20}
    },
    Length = {
        Common = {min=1,max=2}, Uncommon = {min=2,max=3}, Rare = {min=3,max=4},
        Epic = {min=4,max=5}, Legendary = {min=5,max=6}, Celestial = {min=6,max=7},
        God = {min=7,max=8}, Glitched = {min=8,max=9}, ["????????"] = {min=9,max=10}
    }
}, "Ignites the target on hit, burning them for a duration.", function(attacker, receiver, item)
    if not IsValid(receiver) then return end
    local chance     = item:GetProperty("Chance")     or math.random()
    local resistance = item:GetProperty("Resistance") or 1
    local length     = item:GetProperty("Length")     or 3
    if math.random() < chance / resistance then
        receiver:Ignite(length, 0)
        modifiereffect("pfx1_08_", receiver:GetPos(), receiver)
    end
end)

createModifier("freeze", {
    Chance = {
        Common = {min=0.10,max=0.20}, Uncommon = {min=0.20,max=0.35}, Rare = {min=0.35,max=0.50},
        Epic = {min=0.50,max=0.65}, Legendary = {min=0.65,max=0.80}, Celestial = {min=0.80,max=0.95},
        God = {min=0.95,max=1.10}, Glitched = {min=1.10,max=1.25}, ["????????"] = {min=1.25,max=1.40}
    },
    Resistance = {
        Common = {min=0.90,max=1.00}, Uncommon = {min=0.80,max=0.90}, Rare = {min=0.70,max=0.80},
        Epic = {min=0.60,max=0.70}, Legendary = {min=0.50,max=0.60}, Celestial = {min=0.40,max=0.50},
        God = {min=0.30,max=0.40}, Glitched = {min=0.20,max=0.30}, ["????????"] = {min=0.10,max=0.20}
    },
    Length = {
        Common = {min=1,max=2}, Uncommon = {min=2,max=3}, Rare = {min=3,max=4},
        Epic = {min=4,max=5}, Legendary = {min=5,max=6}, Celestial = {min=6,max=7},
        God = {min=7,max=8}, Glitched = {min=8,max=9}, ["????????"] = {min=9,max=10}
    }
}, "Freezes the target in place, preventing movement.", function(attacker, receiver, item)
    if not IsValid(receiver) then return end
    local chance     = item:GetProperty("Chance")     or math.random()
    local resistance = item:GetProperty("Resistance") or 1
    local length     = item:GetProperty("Length")     or 3
    if math.random() < chance / resistance then
        local wspeed = receiver:GetWalkSpeed()
        local rspeed = receiver:GetRunSpeed()
        receiver:SetWalkSpeed(0)
        receiver:SetRunSpeed(0)
        modifiereffect("pfx8_07", receiver:GetPos(), receiver)
        timer.Simple(length, function()
            if IsValid(receiver) then
                receiver:SetWalkSpeed(wspeed)
                receiver:SetRunSpeed(rspeed)
            end
        end)
    end
end)

createModifier("poison", {
    Chance = {
        Common = {min=0.05,max=0.10}, Uncommon = {min=0.10,max=0.20}, Rare = {min=0.20,max=0.35},
        Epic = {min=0.35,max=0.50}, Legendary = {min=0.50,max=0.65}, Celestial = {min=0.65,max=0.80},
        God = {min=0.80,max=0.95}, Glitched = {min=0.95,max=1.10}, ["????????"] = {min=1.10,max=1.25}
    },
    Resistance = {
        Common = {min=0.90,max=1.00}, Uncommon = {min=0.80,max=0.90}, Rare = {min=0.70,max=0.80},
        Epic = {min=0.60,max=0.70}, Legendary = {min=0.50,max=0.60}, Celestial = {min=0.40,max=0.50},
        God = {min=0.30,max=0.40}, Glitched = {min=0.20,max=0.30}, ["????????"] = {min=0.10,max=0.20}
    },
    Damage = {
        Common = {min=1,max=2}, Uncommon = {min=2,max=3}, Rare = {min=3,max=5},
        Epic = {min=5,max=7}, Legendary = {min=7,max=9}, Celestial = {min=9,max=12},
        God = {min=12,max=15}, Glitched = {min=15,max=18}, ["????????"] = {min=18,max=22}
    },
    Duration = {
        Common = {min=1,max=2}, Uncommon = {min=2,max=3}, Rare = {min=3,max=5},
        Epic = {min=5,max=6}, Legendary = {min=6,max=7}, Celestial = {min=7,max=8},
        God = {min=8,max=9}, Glitched = {min=9,max=10}, ["????????"] = {min=10,max=12}
    }
}, "Poisons the target, dealing damage over time.", function(attacker, receiver, item)
    if not IsValid(receiver) then return end
    local chance     = item:GetProperty("Chance")     or math.random()
    local resistance = item:GetProperty("Resistance") or 1
    local damage     = item:GetProperty("Damage")     or 1
    local duration   = item:GetProperty("Duration")   or 3
    if math.random() < chance / resistance then
        modifiereffect("pfx1_09", receiver:GetPos(), receiver)
        for i = 1, duration do
            timer.Simple(i, function()
                if IsValid(receiver) then
                    receiver:TakeDamage(damage, attacker, nil)
                end
            end)
        end
    end
end)

createModifier("electrocute", {
    Chance = {
        Common = {min=0.05,max=0.15}, Uncommon = {min=0.15,max=0.30}, Rare = {min=0.30,max=0.50},
        Epic = {min=0.50,max=0.65}, Legendary = {min=0.65,max=0.80}, Celestial = {min=0.80,max=0.95},
        God = {min=0.95,max=1.10}, Glitched = {min=1.10,max=1.25}, ["????????"] = {min=1.25,max=1.40}
    },
    Resistance = {
        Common = {min=0.90,max=1.00}, Uncommon = {min=0.80,max=0.90}, Rare = {min=0.70,max=0.80},
        Epic = {min=0.60,max=0.70}, Legendary = {min=0.50,max=0.60}, Celestial = {min=0.40,max=0.50},
        God = {min=0.30,max=0.40}, Glitched = {min=0.20,max=0.30}, ["????????"] = {min=0.10,max=0.20}
    },
    StunDuration = {
        Common = {min=1,max=2}, Uncommon = {min=2,max=3}, Rare = {min=3,max=4},
        Epic = {min=4,max=5}, Legendary = {min=5,max=6}, Celestial = {min=6,max=7},
        God = {min=7,max=8}, Glitched = {min=8,max=9}, ["????????"] = {min=9,max=10}
    }
}, "Electrocutes the target, stunning them for a short time.", function(attacker, receiver, item)
    if not IsValid(receiver) then return end
    local chance   = item:GetProperty("Chance")       or math.random()
    local resistance = item:GetProperty("Resistance") or 1
    local duration = item:GetProperty("StunDuration") or 2
    if math.random() < chance / resistance then
        receiver:Freeze(true)
        modifiereffect("pfx4_05", receiver:GetPos(), receiver)
        modifiereffect("pfx4_08", receiver:GetPos(), nil)
        timer.Simple(duration, function()
            if IsValid(receiver) then receiver:Freeze(false) end
        end)
    end
end)

createModifier("doubletap", {
    Chance = {
        Common = {min=0.05,max=0.10}, Uncommon = {min=0.10,max=0.20}, Rare = {min=0.20,max=0.30},
        Epic = {min=0.30,max=0.40}, Legendary = {min=0.40,max=0.50}, Celestial = {min=0.50,max=0.60},
        God = {min=0.60,max=0.70}, Glitched = {min=0.70,max=0.80}, ["????????"] = {min=0.80,max=0.90}
    }
}, "Gives a chance to fire an extra shot.", function(attacker, _, item)
    local chance = item:GetProperty("Chance") or math.random()
    if math.random() < chance then
        modifiereffect("pfx4_06_2", attacker:GetPos(), attacker)
        return 2
    end
    return 1
end)

createModifier("explosive", {
    Chance = {
        Common = {min=0.05,max=0.10}, Uncommon = {min=0.10,max=0.20}, Rare = {min=0.20,max=0.30},
        Epic = {min=0.30,max=0.40}, Legendary = {min=0.40,max=0.50}, Celestial = {min=0.50,max=0.60},
        God = {min=0.60,max=0.70}, Glitched = {min=0.70,max=0.80}, ["????????"] = {min=0.80,max=0.90}
    },
    Radius = {
        Common = {min=100,max=150}, Uncommon = {min=150,max=180}, Rare = {min=180,max=210},
        Epic = {min=210,max=240}, Legendary = {min=240,max=270}, Celestial = {min=270,max=300},
        God = {min=300,max=330}, Glitched = {min=330,max=360}, ["????????"] = {min=360,max=400}
    },
    Damage = {
        Common = {min=10,max=20}, Uncommon = {min=20,max=35}, Rare = {min=35,max=50},
        Epic = {min=50,max=65}, Legendary = {min=65,max=80}, Celestial = {min=80,max=95},
        God = {min=95,max=110}, Glitched = {min=110,max=130}, ["????????"] = {min=130,max=150}
    }
}, "Causes an explosion on hit, dealing area damage.", function(attacker, receiver, item)
    if not IsValid(receiver) then return end
    local chance = item:GetProperty("Chance") or math.random()
    local damage = item:GetProperty("Damage") or 20
    if math.random() < chance then
        receiver:TakeDamage(damage, attacker, attacker)
        modifiereffect("pfx1_05", receiver:GetPos(), nil)
        modifiereffect("pfx1_03", receiver:GetPos(), nil)
    end
end)

createModifier("lifesteal", {
    Chance = {
        Common = {min=0.05,max=0.10}, Uncommon = {min=0.10,max=0.20}, Rare = {min=0.20,max=0.30},
        Epic = {min=0.30,max=0.40}, Legendary = {min=0.40,max=0.50}, Celestial = {min=0.50,max=0.60},
        God = {min=0.60,max=0.70}, Glitched = {min=0.70,max=0.80}, ["????????"] = {min=0.80,max=0.90}
    },
    HealPercent = {
        Common = {min=0.05,max=0.10}, Uncommon = {min=0.10,max=0.15}, Rare = {min=0.15,max=0.20},
        Epic = {min=0.20,max=0.25}, Legendary = {min=0.25,max=0.30}, Celestial = {min=0.30,max=0.35},
        God = {min=0.35,max=0.40}, Glitched = {min=0.40,max=0.45}, ["????????"] = {min=0.45,max=0.50}
    }
}, "Chance to heal the attacker for a percent of damage dealt.", function(attacker, receiver, item)
    if not IsValid(attacker) or not IsValid(receiver) then return end
    local chance = item:GetProperty("Chance")      or math.random()
    local heal   = item:GetProperty("HealPercent") or 0.2
    if math.random() < chance then
        attacker:SetHealth(math.min(
            attacker:Health() + math.ceil(receiver:Health() * heal),
            attacker:GetMaxHealth()
        ))
        modifiereffect("pfx2_00", attacker:GetPos(), attacker)
    end
end)

createModifier("damage", {
    Damage = {
        Common = {min=1,max=2}, Uncommon = {min=2,max=3}, Rare = {min=3,max=4},
        Epic = {min=4,max=5}, Legendary = {min=5,max=6}, Celestial = {min=6,max=7},
        God = {min=7,max=8}, Glitched = {min=8,max=9}, ["????????"] = {min=9,max=10}
    }
}, "Increases weapon damage.", nil, function(item, weapon)
    local statData = BCORE.Inventory.Modifiers["damage"].stats.Damage[item.rarity]
    if statData then
        local scale = 1000
        weapon:SetProperty("Damage",
            math.ceil(math.random(math.floor(statData.min*scale), math.floor(statData.max*scale)) / scale))
    end
end)

createModifier("accuracy", {
    Accuracy = {
        Common = {min=1.00,max=1.05}, Uncommon = {min=1.05,max=1.10}, Rare = {min=1.10,max=1.15},
        Epic = {min=1.15,max=1.20}, Legendary = {min=1.20,max=1.25}, Celestial = {min=1.30,max=1.40},
        God = {min=1.40,max=1.50}, Glitched = {min=1.50,max=1.60}, ["????????"] = {min=1.50,max=1.60}
    }
}, "Increases weapon accuracy.", nil, function(item, weapon)
    local statData = BCORE.Inventory.Modifiers["accuracy"].stats.Accuracy[item.rarity]
    if statData then
        local scale = 1000
        weapon:SetProperty("Spread",
            math.ceil(math.random(math.floor(statData.min*scale), math.floor(statData.max*scale)) / scale * 100) / 100)
    end
end)

createModifier("recoil", {
    Recoil = {
        Common = {min=0.95,max=1.00}, Uncommon = {min=0.90,max=0.95}, Rare = {min=0.85,max=0.90},
        Epic = {min=0.80,max=0.85}, Legendary = {min=0.75,max=0.80}, Celestial = {min=0.70,max=0.75},
        God = {min=0.65,max=0.70}, Glitched = {min=0.60,max=0.65}, ["????????"] = {min=0.60,max=0.65}
    }
}, "Reduces weapon recoil.", nil, function(item, weapon)
    local statData = BCORE.Inventory.Modifiers["recoil"].stats.Recoil[item.rarity]
    if statData then
        local scale = 1000
        weapon:SetProperty("Recoil",
            math.ceil(math.random(math.floor(statData.min*scale), math.floor(statData.max*scale)) / scale * 100) / 100)
    end
end)

createModifier("infinite", {
    ClipSize = {
        Common = {min=1.00,max=1.05}, Uncommon = {min=1.05,max=1.10}, Rare = {min=1.10,max=1.15},
        Epic = {min=1.15,max=1.20}, Legendary = {min=1.20,max=1.25}, Celestial = {min=1.30,max=1.40},
        God = {min=1.40,max=1.50}, Glitched = {min=1.50,max=1.60}, ["????????"] = {min=1.50,max=1.60}
    }
}, "Increases weapon clip size.", nil, function(item, weapon)
    local statData = BCORE.Inventory.Modifiers["infinite"].stats.ClipSize[item.rarity]
    if statData then
        local scale = 1000
        weapon:SetProperty("ClipSize",
            math.ceil(math.random(math.floor(statData.min*scale), math.floor(statData.max*scale)) / scale))
    end
end)

createModifier("overload", {
    Damage   = { Common={min=1,max=1.05}, Uncommon={min=1.05,max=1.1}, Rare={min=1.1,max=1.15}, Epic={min=1.15,max=1.2}, Legendary={min=1.2,max=1.25}, Celestial={min=1.3,max=1.4}, God={min=1.4,max=1.5}, Glitched={min=1.5,max=1.6}, ["????????"]={min=1.6,max=1.7} },
    Recoil   = { Common={min=0.95,max=1}, Uncommon={min=0.9,max=0.95}, Rare={min=0.85,max=0.9}, Epic={min=0.8,max=0.85}, Legendary={min=0.75,max=0.8}, Celestial={min=0.7,max=0.75}, God={min=0.65,max=0.7}, Glitched={min=0.6,max=0.65}, ["????????"]={min=0.55,max=0.6} },
    ClipSize = { Common={min=1,max=1.05}, Uncommon={min=1.05,max=1.1}, Rare={min=1.1,max=1.15}, Epic={min=1.15,max=1.2}, Legendary={min=1.2,max=1.25}, Celestial={min=1.3,max=1.4}, God={min=1.4,max=1.5}, Glitched={min=1.5,max=1.6}, ["????????"]={min=1.6,max=1.7} },
    Spread   = { Common={min=0.95,max=1}, Uncommon={min=0.9,max=0.95}, Rare={min=0.85,max=0.9}, Epic={min=0.8,max=0.85}, Legendary={min=0.75,max=0.8}, Celestial={min=0.7,max=0.75}, God={min=0.65,max=0.7}, Glitched={min=0.6,max=0.65}, ["????????"]={min=0.55,max=0.6} },
    RPM      = { Common={min=1,max=1.05}, Uncommon={min=1.05,max=1.1}, Rare={min=1.1,max=1.15}, Epic={min=1.15,max=1.2}, Legendary={min=1.2,max=1.25}, Celestial={min=1.3,max=1.4}, God={min=1.4,max=1.5}, Glitched={min=1.5,max=1.6}, ["????????"]={min=1.6,max=1.7} },
}, "Upgrades all weapon stats according to rarity.", nil, function(item, weapon)
    local rarity = item.rarity
    for stat, rarities in pairs(item.stats or {}) do
        local data = rarities[rarity]
        if data then
            local scale = 1000
            local value = math.ceil(math.random(math.floor(data.min*scale), math.floor(data.max*scale)) / scale * 100) / 100
            weapon:SetProperty(stat, value)
        end
    end
end)

createModifier("void", {
    Chance = {
        Common = {min=0.05,max=0.10}, Uncommon = {min=0.10,max=0.20}, Rare = {min=0.20,max=0.30},
        Epic = {min=0.30,max=0.40}, Legendary = {min=0.40,max=0.50}, Celestial = {min=0.50,max=0.60},
        God = {min=0.60,max=0.70}, Glitched = {min=0.70,max=0.80}, ["????????"] = {min=0.80,max=0.90}
    },
    Radius = {
        Common = {min=100,max=150}, Uncommon = {min=150,max=200}, Rare = {min=200,max=250},
        Epic = {min=250,max=300}, Legendary = {min=300,max=350}, Celestial = {min=350,max=400},
        God = {min=400,max=450}, Glitched = {min=450,max=500}, ["????????"] = {min=500,max=600}
    },
    Force = {
        Common = {min=500,max=700}, Uncommon = {min=700,max=900}, Rare = {min=900,max=1100},
        Epic = {min=1100,max=1300}, Legendary = {min=1300,max=1500}, Celestial = {min=1500,max=1700},
        God = {min=1700,max=1900}, Glitched = {min=1900,max=2100}, ["????????"] = {min=2100,max=2300}
    }
}, "Pulls nearby enemies toward the impact location.", function(attacker, receiver, item)
    if not IsValid(receiver) then return end
    local chance = item:GetProperty("Chance") or math.random()
    local radius = item:GetProperty("Radius") or 200
    local force  = item:GetProperty("Force")  or 1000
    if math.random() < chance then
        local pos = receiver:GetPos()
        modifiereffect("pfx5_00_ss", pos, nil)
        for _, ent in pairs(ents.FindInSphere(pos, radius)) do
            -- BUG FIX: was "if not ent == attacker" (operator precedence: always false)
            if IsValid(ent) and ent:IsPlayer() and ent ~= attacker then
                local dir = (pos - ent:GetPos()):GetNormalized()
                ent:SetVelocity(dir * force)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  EXTENDED MODIFIERS
-- ══════════════════════════════════════════════════════════════

createModifier("bleed", {
    Chance = {
        Common = {min=0.05,max=0.10}, Uncommon = {min=0.10,max=0.20}, Rare = {min=0.20,max=0.30},
        Epic = {min=0.30,max=0.40}, Legendary = {min=0.40,max=0.50}, Celestial = {min=0.50,max=0.60},
        God = {min=0.60,max=0.70}, Glitched = {min=0.70,max=0.80}, ["????????"] = {min=0.80,max=0.90}
    },
    Damage = {
        Common = {min=1,max=2}, Uncommon = {min=2,max=3}, Rare = {min=3,max=4},
        Epic = {min=4,max=5}, Legendary = {min=5,max=6}, Celestial = {min=6,max=7},
        God = {min=7,max=8}, Glitched = {min=8,max=9}, ["????????"] = {min=9,max=10}
    },
    Duration = {
        Common = {min=1,max=2}, Uncommon = {min=2,max=3}, Rare = {min=3,max=4},
        Epic = {min=4,max=5}, Legendary = {min=5,max=6}, Celestial = {min=6,max=7},
        God = {min=7,max=8}, Glitched = {min=8,max=9}, ["????????"] = {min=9,max=10}
    }
}, "Inflicts bleeding, causing periodic damage.", function(attacker, receiver, item)
    if not IsValid(receiver) then return end
    local chance   = item:GetProperty("Chance")   or math.random()
    local damage   = item:GetProperty("Damage")   or 2
    local duration = item:GetProperty("Duration") or 2
    if math.random() < chance then
        modifiereffect("pfx2_06",    receiver:GetPos(), receiver)
        modifiereffect("pfx2_02_s",  receiver:GetPos(), nil)
        for i = 1, duration do
            timer.Simple(i, function()
                if IsValid(receiver) then
                    receiver:TakeDamage(damage, attacker, nil)
                end
            end)
        end
    end
end)

createModifier("ricochet", {
    Chance = {
        Common = {min=0.05,max=0.10}, Uncommon = {min=0.10,max=0.20}, Rare = {min=0.20,max=0.30},
        Epic = {min=0.30,max=0.40}, Legendary = {min=0.40,max=0.50}, Celestial = {min=0.50,max=0.60},
        God = {min=0.60,max=0.70}, Glitched = {min=0.70,max=0.80}, ["????????"] = {min=0.80,max=0.90}
    }
}, "Chance for bullets to ricochet to another target.", function(attacker, receiver, item)
    if not IsValid(receiver) then return end
    local chance = item:GetProperty("Chance") or math.random()
    if math.random() < chance then
        for _, ent in pairs(ents.FindInSphere(receiver:GetPos(), 400)) do
            if IsValid(ent) and ent ~= receiver and ent:IsPlayer() then
                local dmg = DamageInfo()
                dmg:SetDamage(10)
                dmg:SetAttacker(attacker)
                dmg:SetInflictor(attacker:GetActiveWeapon())
                dmg:SetDamageType(DMG_BULLET)
                ent:TakeDamageInfo(dmg)
                modifiereffect("pfx6_02b", ent:GetPos(), nil)
                break
            end
        end
    end
end)

createModifier("disarm", {
    Chance = {
        Common = {min=0.05,max=0.10}, Uncommon = {min=0.10,max=0.20}, Rare = {min=0.20,max=0.30},
        Epic = {min=0.30,max=0.40}, Legendary = {min=0.40,max=0.50}, Celestial = {min=0.50,max=0.60},
        God = {min=0.60,max=0.70}, Glitched = {min=0.70,max=0.80}, ["????????"] = {min=0.80,max=0.90}
    }
}, "Chance to force the target to switch their weapon.", function(attacker, receiver, item)
    if not IsValid(receiver) then return end
    local chance = item:GetProperty("Chance") or math.random()
    local wep    = receiver:GetActiveWeapon()
    if math.random() < chance and IsValid(wep) then
        -- pcall: DropWeapon can error on some weapon bases
        pcall(function() receiver:DropWeapon(wep) end)
        modifiereffect("pfx4_05", receiver:GetPos(), receiver)
    end
end)

createModifier("time_warp", {
    Chance = {
        Common = {min=0.05,max=0.10}, Uncommon = {min=0.10,max=0.20}, Rare = {min=0.20,max=0.30},
        Epic = {min=0.30,max=0.40}, Legendary = {min=0.40,max=0.50}, Celestial = {min=0.50,max=0.60},
        God = {min=0.60,max=0.70}, Glitched = {min=0.70,max=0.80}, ["????????"] = {min=0.80,max=0.90}
    },
    Duration = {
        Common = {min=1,max=2}, Uncommon = {min=2,max=3}, Rare = {min=3,max=4},
        Epic = {min=4,max=5}, Legendary = {min=5,max=6}, Celestial = {min=6,max=7},
        God = {min=7,max=8}, Glitched = {min=8,max=9}, ["????????"] = {min=9,max=10}
    }
}, "Slows the target's movement speed temporarily.", function(attacker, receiver, item)
    if not IsValid(receiver) then return end
    local chance   = item:GetProperty("Chance")   or math.random()
    local duration = item:GetProperty("Duration") or 2
    if math.random() < chance then
        receiver:SetLaggedMovementValue(0.5)
        modifiereffect("pfx7_02", receiver:GetPos(), receiver)
        timer.Simple(duration, function()
            if IsValid(receiver) then receiver:SetLaggedMovementValue(1) end
        end)
    end
end)

createModifier("speed", {
    RPM = {
        Common = {min=1.00,max=1.05}, Uncommon = {min=1.05,max=1.10}, Rare = {min=1.10,max=1.15},
        Epic = {min=1.15,max=1.20}, Legendary = {min=1.20,max=1.25}, Celestial = {min=1.30,max=1.40},
        God = {min=1.40,max=1.50}, Glitched = {min=1.50,max=1.60}, ["????????"] = {min=1.50,max=1.60}
    }
}, "Increases weapon fire rate (RPM).", nil, function(item, weapon)
    local statData = BCORE.Inventory.Modifiers["speed"].stats.RPM[item.rarity]
    if statData then
        local scale = 1000
        weapon:SetProperty("RPM",
            math.ceil(math.random(math.floor(statData.min*scale), math.floor(statData.max*scale)) / scale * 100) / 100)
    end
end)

createModifier("shadow_step", {
    Chance = {
        Common = {min=0.05,max=0.10}, Uncommon = {min=0.10,max=0.20}, Rare = {min=0.20,max=0.30},
        Epic = {min=0.30,max=0.40}, Legendary = {min=0.40,max=0.50}, Celestial = {min=0.50,max=0.60},
        God = {min=0.60,max=0.70}, Glitched = {min=0.70,max=0.80}, ["????????"] = {min=0.80,max=0.90}
    },
    TeleportDistance = {
        Common = {min=100,max=150}, Uncommon = {min=150,max=200}, Rare = {min=200,max=250},
        Epic = {min=250,max=300}, Legendary = {min=300,max=350}, Celestial = {min=350,max=400},
        God = {min=400,max=450}, Glitched = {min=450,max=500}, ["????????"] = {min=500,max=600}
    }
-- BUG FIX: description says "teleports the USER" but original code teleported receiver.
-- Now teleports attacker (the one using the weapon).
-- A trace is done to avoid landing inside solid geometry.
}, "Instantly teleports the user a short distance forward.", function(attacker, receiver, item)
    if not IsValid(attacker) then return end
    local chance   = item:GetProperty("Chance")            or math.random()
    local distance = item:GetProperty("TeleportDistance")  or 150
    if math.random() < chance then
        local startPos  = attacker:GetPos() + Vector(0, 0, 32)
        local targetPos = startPos + attacker:GetForward() * distance

        -- Trace to make sure we don't teleport into a wall
        local tr = util.TraceLine({
            start  = startPos,
            endpos = targetPos,
            filter = attacker,
            mask   = MASK_PLAYERSOLID,
        })

        -- Land just before any hit surface, or at the full distance if clear
        local safePos = tr.Hit
            and (tr.HitPos - attacker:GetForward() * 16)
            or  targetPos

        modifiereffect("pfx2_05", attacker:GetPos(), nil)
        attacker:SetPos(safePos - Vector(0, 0, 32))
        modifiereffect("pfx2_05", safePos, nil)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  NETWORKING & HOOKS
-- ══════════════════════════════════════════════════════════════

local thread = BCORE.netstream

thread.Hook("BCORE.Inventory.Socket", function(ply, itemID, modifierID)
    if not IsValid(ply) then return end

    local item     = ply:GetItemByID(itemID)
    local modifier = ply:GetItemByID(modifierID)
    if not item or not modifier then return end

    item.customData             = item.customData             or {}
    item.customData.Modifiers   = item.customData.Modifiers   or {}

    local modType = modifier.customData and modifier.customData.Type
    if not modType or not BCORE.Inventory.Modifiers[modType] then
        BCORE.Inventory:Chat("Invalid modifier type.", ply)
        return
    end

    -- Check for duplicate (Modifiers is a sequential array — ipairs is correct here)
    for _, m in ipairs(item.customData.Modifiers) do
        if m.customData and m.customData.Type == modType then
            BCORE.Inventory:Chat("Modifier '" .. modType .. "' is already socketed on this item.", ply)
            return
        end
    end

    local modData = BCORE.Inventory.Modifiers[modType]
    if modData.Modify then
        item.customData.baseStats = item.customData.baseStats or {}

        -- BUG FIX: modData.stats is a key→table hash, not a sequential array.
        -- ipairs() would iterate nothing. Use pairs() to walk stat names.
        for stat, _ in pairs(modData.stats) do
            if not item.customData.baseStats[stat] then
                item.customData.baseStats[stat] = item:GetProperty(stat) or 0
            end
        end

        ply:Kill()
        modData.Modify(modifier, item)
        modifier.customData              = modifier.customData or {}
        modifier.customData.doesmodify   = true
    end

    table.insert(item.customData.Modifiers, modifier)
    ply:RemoveItem(modifier)
    ply:UpdateItem(item)
    BCORE.Inventory:Chat("Socketed modifier '" .. (modType or "unknown") .. "' into " .. item.name .. ".", ply)
end)

thread.Hook("BCORE.Inventory.UnSocket", function(ply, itemID, modifier)
    if not IsValid(ply) then return end

    local item = ply:GetItemByID(itemID)
    if not item or not item.customData or not item.customData.Modifiers then return end

    local removed = false
    for k, v in ipairs(item.customData.Modifiers) do
        if v.id == modifier.id then
            table.remove(item.customData.Modifiers, k)
            removed = true
            break
        end
    end

    if not removed then return end

    local baseStats = item.customData.baseStats or {}
    local modType   = modifier.customData and modifier.customData.Type
    local modData   = modType and BCORE.Inventory.Modifiers[modType]

    if modData and modData.stats then
        for statName, _ in pairs(modData.stats) do
            if baseStats[statName] ~= nil then
                item:SetProperty(statName, baseStats[statName])
                baseStats[statName] = nil
            end
        end
    end

    item.customData.baseStats = baseStats
    ply:UpdateItem(item)

    setmetatable(modifier, BCORE.Inventory.Item)
    modifier:setActions(BCORE.Inventory.actiontable[modifier.itemType])
    ply:AddItem(modifier)

    BCORE.Inventory:Chat("Unsocketed modifier '" .. (modType or "unknown") .. "' from " .. item.name .. ".", ply)
end)

-- Networking modifiers to client
util.AddNetworkString("Modifier_ent")
function BCORE.Inventory:LoadModifiers(ply)
    BCORE.Inventory:RegisterModifiers(BCORE.Inventory.Modifiers)
    net.Start("Modifier_ent")
        net.WriteTable(BCORE.Inventory.Modifiers)
    net.Send(ply)
end

-- Apply modifiers on hit
hook.Add("EntityTakeDamage", "Weapon_ApplyModifiers", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end

    local weapon = attacker:GetActiveWeapon()
    if not IsValid(weapon) or not weapon.isitem then return end

    if weapon.customData and weapon.customData.Modifiers then
        for _, mod in ipairs(weapon.customData.Modifiers) do
            local modType = mod.customData and mod.customData.Type
            local modData = servertable[modType]
            if modData and modData.OnHit then
                -- pcall so a broken modifier doesn't kill the hook for others
                local ok, err = pcall(modData.OnHit, attacker, target, mod, dmginfo)
                if not ok then
                    print("[Modifier] OnHit error (" .. tostring(modType) .. "): " .. tostring(err))
                end
            end
        end
    end
end)