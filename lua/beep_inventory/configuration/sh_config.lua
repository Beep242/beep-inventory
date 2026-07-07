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
    playtime = Color(0,247,589),
}

BCORE.Inventory.config.SkinRollCost = 50000000000

BCORE.Inventory.config.PricePerHpAndAp = 80


BCORE.Inventory.config.AdminWipePassword = "YDWU*aw87e23e12789318hasdhjdaw"


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




