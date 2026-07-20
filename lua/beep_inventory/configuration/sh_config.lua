BCORE.Inventory.config = BCORE.Inventory.config or {}

BCORE.Inventory.config.MaxSlots = 44 * 3

BCORE.Inventory.config.Rarities = {
    ['Common'] = {
        color = Color(255, 255, 255),
        weight = 1,
        multipliers = {
            Damage   = { min = 1.00, max = 1.05 },
            Accuracy = { min = 1.00, max = 1.05 },
            Recoil   = { min = 0.95, max = 1.00 },
            ClipSize = { min = 1.00, max = 1.05 },
            Spread   = { min = 0.95, max = 1.00 },
            RPM      = { min = 1.00, max = 1.05 },
            Shots    = { min = 1.00, max = 1.05 }
        },
        sockets = 1
    },

    ['Uncommon'] = {
        color = Color(0, 255, 0),
        weight = 2,
        multipliers = {
            Damage   = { min = 1.05, max = 1.10 },
            Accuracy = { min = 1.05, max = 1.10 },
            Recoil   = { min = 0.90, max = 0.95 },
            ClipSize = { min = 1.05, max = 1.10 },
            Spread   = { min = 0.90, max = 0.95 },
            RPM      = { min = 1.05, max = 1.10 },
            Shots    = { min = 1.05, max = 1.10 }
        },
        sockets = 2
    },

    ['Rare'] = {
        color = Color(0, 115, 255),
        weight = 3,
        multipliers = {
            Damage   = { min = 1.10, max = 1.15 },
            Accuracy = { min = 1.10, max = 1.15 },
            Recoil   = { min = 0.85, max = 0.90 },
            ClipSize = { min = 1.10, max = 1.15 },
            Spread   = { min = 0.85, max = 0.90 },
            RPM      = { min = 1.10, max = 1.15 },
            Shots    = { min = 1.10, max = 1.15 }
        },
        sockets = 3
    },

    ['Epic'] = {
        color = Color(175, 2, 255),
        weight = 4,
        multipliers = {
            Damage   = { min = 1.15, max = 1.20 },
            Accuracy = { min = 1.15, max = 1.20 },
            Recoil   = { min = 0.80, max = 0.85 },
            ClipSize = { min = 1.15, max = 1.20 },
            Spread   = { min = 0.80, max = 0.85 },
            RPM      = { min = 1.15, max = 1.20 },
            Shots    = { min = 1.15, max = 1.20 }
        },
        sockets = 4
    },

    ['Legendary'] = {
        color = Color(255, 208, 0),
        weight = 5,
        multipliers = {
            Damage   = { min = 1.20, max = 1.25 },
            Accuracy = { min = 1.20, max = 1.25 },
            Recoil   = { min = 0.75, max = 0.80 },
            ClipSize = { min = 1.20, max = 1.25 },
            Spread   = { min = 0.75, max = 0.80 },
            RPM      = { min = 1.20, max = 1.25 },
            Shots    = { min = 1.20, max = 1.25 }
        },
        sockets = 5
    },

    ['Celestial'] = {
        color = Color(255, 70, 70),
        weight = 6,
        multipliers = {
            Damage   = { min = 1.30, max = 1.40 },
            Accuracy = { min = 1.30, max = 1.40 },
            Recoil   = { min = 0.70, max = 0.75 },
            ClipSize = { min = 1.30, max = 1.40 },
            Spread   = { min = 0.70, max = 0.75 },
            RPM      = { min = 1.30, max = 1.40 },
            Shots    = { min = 1.30, max = 1.40 }
        },
        sockets = 5
    },

    ['God'] = {
        color = Color(255, 70, 70),
        weight = 7,
        multipliers = {
            Damage   = { min = 1.40, max = 1.50 },
            Accuracy = { min = 1.40, max = 1.50 },
            Recoil   = { min = 0.65, max = 0.70 },
            ClipSize = { min = 1.40, max = 1.50 },
            Spread   = { min = 0.65, max = 0.70 },
            RPM      = { min = 1.40, max = 1.50 },
            Shots    = { min = 1.40, max = 1.50 }
        },
        sockets = 6
    },

    ['Glitched'] = {
        color = "Rainbow",
        weight = 8,
        multipliers = {
            Damage   = { min = 1.50, max = 1.60 },
            Accuracy = { min = 1.50, max = 1.60 },
            Recoil   = { min = 0.60, max = 0.65 },
            ClipSize = { min = 1.50, max = 1.60 },
            Spread   = { min = 0.60, max = 0.65 },
            RPM      = { min = 1.50, max = 1.60 },
            Shots    = { min = 1.50, max = 1.60 }
        },
        sockets = 6
    },

    ['????????'] = {
        color = "Rainbow",
        weight = 9,
        multipliers = {
            Damage   = { min = 1.50, max = 1.60 },
            Accuracy = { min = 1.50, max = 1.60 },
            Recoil   = { min = 0.60, max = 0.65 },
            ClipSize = { min = 1.50, max = 1.60 },
            Spread   = { min = 0.60, max = 0.65 },
            RPM      = { min = 1.50, max = 1.60 },
            Shots    = { min = 1.50, max = 1.60 }
        },
        sockets = 6,
        _last = 0,
        _cached = "",
        animate = function(txt)
            local rarity = BCORE.Inventory.config.Rarities["????????"]
            if CurTime() - (rarity._last or 0) > 0.05 then
                local symbols = "@#&*^$%!?~"
                local out = ""
                for i = 1, #txt do
                    if math.random() < 0.5 then
                        out = out .. symbols[math.random(1, #symbols)]
                    else
                        out = out .. txt:sub(i, i)
                    end
                end
                rarity._cached = out
                rarity._last = CurTime()
            end
            return rarity._cached
        end
    }
}

BCORE.Inventory.Skins = {
    "models/skins/aquarium3",
    "models/skins/matt",
    "models/skins/collisions",
    "models/skins/cracked",
    "models/skins/dance",
    "models/skins/disco",
    "models/skins/doughnut",
    "models/skins/glitched",
    "models/skins/lightshow",
    "models/skins/liquid",
    "models/skins/pulse",
    "models/skins/potatoo3",
    "models/skins/rainbowdrops",
    "models/skins/rearranged",
    "models/skins/shaped",
    "models/skins/sketchy",
    "models/skins/smallone2",
    "models/skins/elite5",
    "models/skins/splotches",
    "models/skins/trippy",
    "models/skins/warped",
    "models/skins/waves",
    "models/skins/wobble",
    "models/skins/imking6",
    "models/skins/lethal5",
    "models/skins/quazy",
    "models/skins/simpking2",
    "models/skins/team",
    "models/skins/bomer5",
    "models/skins/nosharp3",
    "models/skins/artsy",
    "models/skins/bass",
    "skins/pepsiman",
}



BCORE.Inventory.config.Admins = {
    "superadmin",
    "admin",
}

BCORE.Inventory.colors = {
    bg = Color(28,28,28),
    accent = Color(40,39,44),
    light = Color(55,54,60),
    sec = Color(35,34,38),
    cwhite = Color(202,202,202),
    tert = Color(194,55,9),
    stert = Color(255,78,217),
    moneygreen = Color(255,206,31),
    online = Color(0,82,224),
    current = Color(254,89,12),
    playtime = Color(0,247,255), -- was Color(0,247,589) - 589 is out of the 0-255 range
}

BCORE.Inventory.config.SkinRollCost = 50000000000

BCORE.Inventory.config.PricePerHpAndAp = 80

-- AdminWipePassword used to be defined here but never actually referenced anywhere - the
-- real client-side wipe-confirmation gate in cl_admin.lua hardcoded a different (and
-- offensive) literal string instead of using it. That check is cosmetic client-side UX only
-- (the real authorization is the separate server-side IsAdmin check in sv_admin.lua), so both
-- the dead config value and the hardcoded literal have simply been removed - see cl_admin.lua.

-- Register with BCORE.Config (beep-framework), if present, so all of the above becomes
-- in-game editable/persisted instead of needing a file edit + restart. Every
-- BCORE.Inventory.* table stays exactly what every other file in this addon reads from
-- directly - this block just keeps them synced from BCORE.Config underneath.
--
-- Rarities is a special case: color and the "????????" rarity's animated-text scrambler
-- (`animate`/`_last`/`_cached`) can't survive being sent over the network or written to JSON
-- at all (functions aren't serializable, and "Rainbow" is a sentinel string rather than a
-- real Color for two tiers) - those stay hardcoded, cosmetic, code-level details. What IS
-- exposed and genuinely admin-tunable in-game: each rarity's weight (drop odds), socket
-- count, and all 7 stat multiplier ranges - the parts a server owner actually rebalances.
if BCORE and BCORE.RegisterConfig then
    local RarityCosmetics = {}
    for name, data in pairs(BCORE.Inventory.config.Rarities) do
        RarityCosmetics[name] = {
            color = data.color,
            animate = data.animate,
        }
    end

    local STAT_KEYS = { "Damage", "Accuracy", "Recoil", "ClipSize", "Spread", "RPM", "Shots" }

    local rarityFields = {
        { key = "rarity", label = "Rarity", type = "string", default = "" },
        { key = "weight", label = "Weight (drop odds)", type = "number", min = 0, decimals = 0, default = 1 },
        { key = "sockets", label = "Sockets", type = "number", min = 0, max = 10, decimals = 0, default = 1 },
    }
    for _, stat in ipairs(STAT_KEYS) do
        table.insert(rarityFields, { key = stat .. "Min", label = stat .. " Min", type = "number", decimals = 2, default = 1 })
        table.insert(rarityFields, { key = stat .. "Max", label = stat .. " Max", type = "number", decimals = 2, default = 1 })
    end

    local defaultRarityRecords = {}
    for name, data in pairs(BCORE.Inventory.config.Rarities) do
        local rec = { rarity = name, weight = data.weight, sockets = data.sockets }
        for _, stat in ipairs(STAT_KEYS) do
            local m = data.multipliers[stat] or { min = 1, max = 1 }
            rec[stat .. "Min"] = m.min
            rec[stat .. "Max"] = m.max
        end
        defaultRarityRecords[#defaultRarityRecords + 1] = rec
    end

    BCORE:RegisterConfig("beep_inventory", "Rarities", {
        label = "Rarities",
        category = "Rarities",
        description = "Weight, socket count, and stat multiplier ranges per rarity. Colors and special animated rarities aren't editable here.",
        type = "records",
        fields = rarityFields,
        default = defaultRarityRecords,
    })

    BCORE:RegisterConfig("beep_inventory", "MaxSlots", {
        label = "Max Inventory Slots", category = "General",
        type = "number", min = 1, max = 1000, decimals = 0,
        default = BCORE.Inventory.config.MaxSlots,
    })
    BCORE:RegisterConfig("beep_inventory", "SkinRollCost", {
        label = "Skin Roll Cost", category = "Economy",
        type = "number", min = 0, decimals = 0,
        default = BCORE.Inventory.config.SkinRollCost,
    })
    BCORE:RegisterConfig("beep_inventory", "PricePerHpAndAp", {
        label = "Price Per HP/AP (suit repair)", category = "Economy",
        type = "number", min = 0, decimals = 0,
        default = BCORE.Inventory.config.PricePerHpAndAp,
    })
    BCORE:RegisterConfig("beep_inventory", "Admins", {
        label = "Inventory Admin Groups", category = "Access Control",
        description = "Usergroups allowed to use the inventory admin panel (separate from the shared server-config admin gate).",
        type = "list",
        default = BCORE.Inventory.config.Admins,
    })
    BCORE:RegisterConfig("beep_inventory", "Skins", {
        label = "Weapon Skins", category = "Skins",
        type = "list",
        default = BCORE.Inventory.Skins,
    })

    local colorFields, defaultColors = {}, {}
    for key, col in pairs(BCORE.Inventory.colors) do
        colorFields[#colorFields + 1] = { key = key, label = key }
        defaultColors[key] = Color(col.r, col.g, col.b, col.a)
    end
    table.sort(colorFields, function(a, b) return a.key < b.key end)

    BCORE:RegisterConfig("beep_inventory", "colors", {
        label = "Inventory UI Colors", category = "Appearance",
        type = "colors",
        fields = colorFields,
        default = defaultColors,
    })

    local function SyncInventoryConfigMirror()
        local rarityRecords = BCORE:GetConfig("beep_inventory", "Rarities") or {}
        local rebuilt = {}
        for _, rec in ipairs(rarityRecords) do
            local name = rec.rarity
            if name and name ~= "" then
                local cosmetics = RarityCosmetics[name] or {}
                local multipliers = {}
                for _, stat in ipairs(STAT_KEYS) do
                    multipliers[stat] = { min = rec[stat .. "Min"] or 1, max = rec[stat .. "Max"] or 1 }
                end
                rebuilt[name] = {
                    color = cosmetics.color or Color(255, 255, 255),
                    weight = rec.weight or 1,
                    sockets = rec.sockets or 1,
                    multipliers = multipliers,
                    animate = cosmetics.animate,
                }
            end
        end
        if next(rebuilt) then
            BCORE.Inventory.config.Rarities = rebuilt
        end

        BCORE.Inventory.config.MaxSlots = BCORE:GetConfig("beep_inventory", "MaxSlots")
        BCORE.Inventory.config.SkinRollCost = BCORE:GetConfig("beep_inventory", "SkinRollCost")
        BCORE.Inventory.config.PricePerHpAndAp = BCORE:GetConfig("beep_inventory", "PricePerHpAndAp")

        local admins = BCORE:GetConfig("beep_inventory", "Admins")
        if admins and #admins > 0 then BCORE.Inventory.config.Admins = admins end

        local skins = BCORE:GetConfig("beep_inventory", "Skins")
        if skins and #skins > 0 then BCORE.Inventory.Skins = skins end

        local colors = BCORE:GetConfig("beep_inventory", "colors")
        if colors then
            for key, col in pairs(colors) do
                BCORE.Inventory.colors[key] = col
            end
        end
    end

    SyncInventoryConfigMirror()
    hook.Add("BCORE.Config.Synced", "BCORE.Inventory.ConfigSynced", SyncInventoryConfigMirror)
    hook.Add("BCORE.Config.ValueChanged", "BCORE.Inventory.ConfigChanged", function(addonId)
        if addonId == "beep_inventory" then SyncInventoryConfigMirror() end
    end)
end


//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//UNDER THIS IS FOR THE UPGRADING SYSTEM AND MODIFICATION SYSTEM//
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
//DO NOT TOUCH UNDER HERE UNLESS YOU KNOW WHAT YOU ARE DOING//
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////


function BCORE.Inventory:GetRarityColor(rarity)
    local clr = BCORE.Inventory.config.Rarities[rarity].color
    if clr == "Rainbow" then
        return HSVToColor(CurTime() * 10 % 360, 1, 1)
    else
        return clr
    end
end


function BCORE.Inventory:GetHighestRarity()
    local rarities = BCORE.Inventory.config.Rarities
    local highestRarity = nil
    local highestWeight = -math.huge

    for rarity, data in pairs(rarities) do
        if data.weight > highestWeight then
            highestWeight = data.weight
            highestRarity = rarity
        end
    end

    return highestRarity
end

function BCORE.Inventory:GetNextRarity(currentRarity)
    local rarities = BCORE.Inventory.config.Rarities
    local currentWeight = rarities[currentRarity] and rarities[currentRarity].weight

    if not currentWeight then
        return currentRarity 
    end

    for rarity, data in pairs(rarities) do
        if data.weight == currentWeight + 1 then
            return rarity 
        end
    end

    return currentRarity 
end


local function safeName(name)
    return string.gsub(string.lower(name or ""), "[^a-z0-9_]", "_")
end

function BCORE.Inventory:RegisterModifiers(modifiers)
    for k, t in pairs(modifiers) do
        local ENT = {}
        ENT.Base = "modifier_base"
        ENT.Type = "anim"
        ENT.PrintName = k or "Unknown Modifier"
        ENT.Category = "Beeps Modifiers"
        ENT.Spawnable = true
        ENT.AdminSpawnable = true
        ENT.customData = {
            Stats = t.stats or {},
            Description = t.description or "No description provided.",
        }

        local className = safeName(t.Name or k) .. "_modifier"
        if not scripted_ents.Get(className) then
            scripted_ents.Register(ENT, className)
        end
    end
end

function BCORE.Inventory:RegisterSuits(suits)
    for k, t in pairs(suits) do
        local ENT = {}
        ENT.Base = "suit_base"
        ENT.Type = "anim"
        ENT.PrintName = k or "Unknown Suit"
        ENT.Category = "Beeps Suits"
        ENT.Spawnable = true
        ENT.AdminSpawnable = true
        ENT.customData = {
            Stats = t.stats or {},
            Description = t.description or "No description provided.",
            model = t.model,
            ablities = t.ablities,
        }


        local className = safeName(t.Name or k) .. "_suit"
        if not scripted_ents.Get(className) then
            scripted_ents.Register(ENT, className)
        end
    end
end

   
if CLIENT then
net.Receive("Modifier_ent", function(len)
    local modifiers = net.ReadTable()
    BCORE.Inventory:RegisterModifiers(modifiers)
    LocalPlayer():ConCommand("spawnmenu_reload")
end)

BCORE.netstream.Hook("suit_ent", function(suits)
    BCORE.Inventory:RegisterSuits(suits)
    LocalPlayer():ConCommand("spawnmenu_reload")
end)
end




