AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR )

end

local function formatPrintName(str)
    return string.gsub(str, "[^%w]+", " "):gsub("(%a)([%w]*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end
    local ent = ents.Create(ClassName)
    if not IsValid(ent) then return end

    ent:SetPos(tr.HitPos + tr.HitNormal)
    ent:SetAngles(Angle(0, ply:EyeAngles().y + 90, 0))
    ent:Spawn()
    ent:Activate()
    ent:SetModel("models/props_phx2/garbage_metalcan001a.mdl")
    ent:SetNoDraw(true)
    ent:SetNotSolid(true)

    timer.Simple(0, function()
        if not IsValid(ent) then return end
        local rarity = "Common"
        local statsTable = {}

        local defaultStats = ent.customData and ent.customData.Stats or {}
        for statName, statValues in pairs(defaultStats) do
            if type(statValues) == "table" and statValues[rarity] then
                local min = statValues[rarity].min or 1
                local max = statValues[rarity].max or 10
                statsTable[statName] = math.random(min, max)
            else
                statsTable[statName] = statValues
            end
        end
        statsTable.Type = ent.PrintName or "Unknown"
        statsTable.Description = ent.customData and ent.customData.Description or "No description provided."

        local item = BCORE.Inventory.Item:new(
            "modifier_base",
            formatPrintName(ent.PrintName) .. " Modifier",
            "models/props_phx2/garbage_metalcan001a.mdl",
            rarity,
            "Modifier",
            statsTable
        )

        item:setActions({"Drop"})
        item:SpawnItem(ply:GetPos() + Vector(0, 0, 20))
        ent:Remove()
    end)

    return ent
end

