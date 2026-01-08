util.AddNetworkString("ApplyWeaponSkin")

local upgradeablewep = {}

upgradeablewep.Equip = function(item, ply)
    if item.isitem and item.itemType == "UpgradableWeapon" then
        local weaponClass = item.className
        if not ply:HasWeapon(weaponClass) then 
            ply:Give(weaponClass)
            local weapon = ply:GetWeapon(weaponClass)

            if IsValid(weapon) then
                weapon.className = item.className
                weapon.id = item.id
                weapon.name = item.name
                weapon.model = item.model
                weapon.rarity = item.rarity
                weapon.itemType = item.itemType
                weapon.customData = item.customData
                weapon.isitem = item.isitem 

                weapon:SetNWInt("Damage", item:GetProperty("Damage") or 100)
                weapon:SetNWFloat("Recoil", item:GetProperty("Recoil") or 1)
                weapon:SetNWInt("ClipSize", item:GetProperty("ClipSize") or 30)
                weapon:SetNWFloat("Spread", item:GetProperty("Spread") or 0.5)
                weapon:SetNWInt("RPM", item:GetProperty("RPM") or 100)

                weapon.Primary.Damage = weapon:GetNWInt("Damage")
                weapon.Primary.Recoil = weapon:GetNWFloat("Recoil")
                weapon.Primary.ClipSize = weapon:GetNWInt("ClipSize")
                weapon.Primary.Spread = weapon:GetNWFloat("Spread")
                weapon.Primary.RPM = weapon:GetNWInt("RPM")

                timer.Simple(0.1, function()
                if item.customData.Skin then
                    local gay = ply:GetWeapon(item.className)
                    if IsValid(gay) then
                        net.Start("ApplyWeaponSkin")
                            net.WriteEntity(gay)
                            net.WriteString(item.customData.Skin)
                        net.Send(ply)
                        ply:ChatPrint("Applied skin to " .. gay:GetClass())
                    end
                end
            end)
            end 

            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(weaponClass) then
                    ply:SelectWeapon(weaponClass)
                end
            end)

            BCORE.Inventory:Chat("You equipped a " .. item.name, ply)

            ply:RemoveItem(item)
        else
            BCORE.Inventory:Chat("You already have this weapon equipped!", ply)
        end
    end
end

upgradeablewep.Drop = function(item, ply)
    local pos = ply:GetPos() + Vector(0, 0, 50) + ply:GetForward() * 60
    local ent = item:SpawnItem(pos)
    if item.customData.Skin then
        ent:SetMaterial(item.customData.Skin)
        ent.customData.Skin = item.customData.Skin
    end
    ply:RemoveItem(item)
end

upgradeablewep.Destroy = function(item, ply)
    ply:RemoveItem(item)
end  

upgradeablewep.Upgrade = function(item, ply)
    local wep_base = weapons.Get(item.className)
    if not wep_base then
        print("[ERROR] " .. item.className .. " not found in weapons.Get!")
        return
    end

    local rarities = BCORE.Inventory.config.Rarities
    local currentRarity = item.rarity
    if currentRarity == BCORE.Inventory:GetHighestRarity() then return end

    local nextRarity = BCORE.Inventory:GetNextRarity(currentRarity)
    local multipliers = rarities[currentRarity] and rarities[currentRarity].multipliers or {}

    local function randMultiplier(stat)
        local data = multipliers[stat]
        if not data then return 1 end
        return math.Rand(data.min, data.max)
    end

    local function applyStat(statName, baseValue, roundUp)
        local value = baseValue * randMultiplier(statName)
        if roundUp then
            return math.ceil(value)
        else
            return value
        end
    end

    item:SetProperty("Damage",   applyStat("Damage",   item:GetProperty("Damage")   or wep_base.Primary.Damage, true))
    item:SetProperty("Recoil",   applyStat("Recoil",   item:GetProperty("Recoil")   or wep_base.Primary.Recoil, true))
    item:SetProperty("ClipSize", applyStat("ClipSize", item:GetProperty("ClipSize") or wep_base.Primary.ClipSize, true))
    item:SetProperty("Spread",   applyStat("Spread",   item:GetProperty("Spread")   or wep_base.Primary.Spread, true))
    item:SetProperty("RPM",      applyStat("RPM",      item:GetProperty("RPM")      or wep_base.Primary.RPM, true))


    item.rarity = nextRarity
    ply:UpdateItem(item)
    BCORE.Inventory:Chat("Your " .. item.name .. " has been upgraded to " .. nextRarity .. "!", ply)
    BCORE.Inventory.Admin:LogAction(ply, "upgrade", item.id)
end



upgradeablewep.Socket = function(item, ply)

end

upgradeablewep.RollSkin = function(item, ply)
    if ply:getDarkRPVar("money") >= BCORE.Inventory.config.SkinRollCost then
            ply:addMoney(-BCORE.Inventory.config.SkinRollCost)
            item.customData.Skin = table.Random(BCORE.Inventory.Skins)
            ply:UpdateItem(item)
            BCORE.Inventory:Chat("You rolled a new skin for your " .. item.name .. "! \n Cost: " .. BCORE.Inventory.config.SkinRollCost, ply)
        else
            BCORE.Inventory:Chat("You don't have enough money to roll a skin! Cost: " .. BCORE.Inventory.config.SkinRollCost, ply)
        return
    end
end

BCORE.Inventory:RegisterType("UpgradableWeapon", upgradeablewep)
