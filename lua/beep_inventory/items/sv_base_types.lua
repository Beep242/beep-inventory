local Inventory = BCORE.Inventory

Inventory.actiontable = Inventory.actiontable or {}

function Inventory:RegisterType(type,actions)
    self.actiontable[type] = actions
end

local weapon = {}

weapon.Equip = function(item, ply)
    if  ply:HasWeapon(item.className) then BCORE.Inventory:Chat("You already have this weapon equiped",ply) return end
    item:GiveWeapon(ply)
    ply:RemoveItem(item)
end

weapon.Drop = function(item, ply)
    local pos = ply:GetPos() + Vector(0, 0, 50) + ply:GetForward() * 60
    item:SpawnItem(pos)
    ply:RemoveItem(item)
end

weapon.Destroy = function(item,ply)
    ply:RemoveItem(item)
end
Inventory:RegisterType("weapon",weapon)

local entity = {}

entity.Drop = function(item, ply)
        local pos = ply:GetPos() + Vector(0, 0, 50) + ply:GetForward() * 60
        item:SpawnItem(pos)
        ply:RemoveItem(item)
    end

entity.Destroy = function(item, ply)
    ply:RemoveItem(item)
end

-- Was a redundant second Inventory:RegisterType("weapon", weapon) - the `entity` actions
-- table above was fully defined but never actually registered under its own type at all.
Inventory:RegisterType("entity", entity)