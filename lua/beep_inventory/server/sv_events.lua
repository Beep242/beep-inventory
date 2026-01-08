local Inventory = BCORE.Inventory

hook.Add("ShutDown", "BCORE_SaveAllInventories", function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:SaveInventory()
        end
    end
    BCORE.Inventory.Admin:SaveAdminLogs()
    BCORE.Inventory.Admin:SaveActionLogs()
end)

hook.Add( "InitPostEntity", "some_unique_name", function()
    BCORE.Inventory.Admin:LoadAdminLogs()
    BCORE.Inventory.Admin:LoadActionLogs()
    print("Loaded admin and action logs.")
end )

hook.Add("PlayerDisconnected", "BCORE_SavePlayerInventory", function(ply)
    ply:SaveInventory()
end)

local load_queue = {}

hook.Add( "PlayerInitialSpawn", "BCORE_Inventory_Load", function( ply )
	load_queue[ ply ] = true
end )

hook.Add( "StartCommand", "BCORE_Inventory_Load_special", function( ply, cmd )
	if load_queue[ ply ] and not cmd:IsForced() then
		load_queue[ ply ] = nil
		ply:LoadInventory()
        ply.currentsuit = "none"
        BCORE.Inventory:LoadModifiers(ply)
        BCORE.Inventory:LoadSuits(ply)

        
	end
end )

util.AddNetworkString("ApplyWeaponSkin")
hook.Add("PlayerUse", "BCORE_CrouchPickup", function(ply, ent)
    if ply:Crouching() then
        ply:PickUp()
        return false
    end
        if ent.itemType == "Suit" then
            if ply.currentsuit and not ply.currentsuit == "none" then
                BCORE.Inventory:Chat("You already have a suit equipped!", ply)
                return false
        end
        local success = BCORE.Inventory:EquipSuit(ply, ent.itemData)
        if not success then return false end
            ent:Remove()
            return true
        end

    if ent.isitem and (ent.itemType == "weapon" or ent.itemType == "UpgradableWeapon") then
        local weaponClass = ent.className
        if ply:HasWeapon(weaponClass) then
            BCORE.Inventory:Chat("You already have this weapon equipped!", ply)
            return false
        end

        ply:Give(weaponClass)
        local weapon = ply:GetWeapon(weaponClass)
        if not IsValid(weapon) then return false end

        weapon.id = ent.id
        weapon.className = ent.className
        weapon.name = ent.name
        weapon.model = ent.model
        weapon.rarity = ent.rarity
        weapon.itemType = ent.itemType
        weapon.customData = ent.customData or {}
        weapon.onAction = {}
        weapon.isitem = ent.isitem


        if ent.itemType == "UpgradableWeapon" then
            weapon:SetNWInt("Damage", ent.customData.Damage or 100)
            weapon:SetNWFloat("Recoil", ent.customData.Recoil or 1)
            weapon:SetNWInt("ClipSize", ent.customData.ClipSize or 30)
            weapon:SetNWFloat("Spread", ent.customData.Spread or 0.5)
            weapon:SetNWInt("RPM", ent.customData.RPM or 100)

            weapon.Primary.Damage = weapon:GetNWInt("Damage")
            weapon.Primary.Recoil = weapon:GetNWFloat("Recoil")
            weapon.Primary.ClipSize = weapon:GetNWInt("ClipSize")
            weapon.Primary.Spread = weapon:GetNWFloat("Spread")
            weapon.Primary.RPM = weapon:GetNWInt("RPM")
        end
        
        if weapon.customData.Skin and weapon.customData.Skin ~= "" then
            timer.Simple(0.1, function()
                if not IsValid(ply) or not ply:HasWeapon(weaponClass) then return end
                local wep = ply:GetWeapon(weaponClass)
                if not IsValid(wep) then return end
                net.Start("ApplyWeaponSkin")
                net.WriteEntity(weapon)
                net.WriteString(weapon.customData.Skin)
                net.Send(ply)
            end)
            ply:ChatPrint("Applied skin to " .. weapon:GetClass())
        end


        timer.Simple(0, function()
            if IsValid(ply) and ply:HasWeapon(weaponClass) then
                ply:SelectWeapon(weaponClass)
            end
        end)
            if not IsValid(ent) then return end


        

        BCORE.Inventory:Chat("You picked up a " .. ent.name, ply)
        ent:Remove()
        BCORE.Inventory.Admin:LogAction(ply, "pick_up", ent.id)

        return false
    end
end)







hook.Add("PlayerSay", "INVENTORY_COMMANDS", function(ply, text)
    local textLower = string.lower(text)

    if textLower == "/invholster" then
        ply:Holster()
        return ""
    elseif textLower == "/drop" then
        local weapon = ply:GetActiveWeapon()
        
        if not IsValid(weapon) then return "" end

        if weapon.isitem then
    
            local item = BCORE.Inventory.Item:new(
                weapon.className,  
                weapon.name,      
                weapon:GetWeaponWorldModel(), 
                weapon.rarity,     
                weapon.itemType,        
                weapon.customData)
            
            if  weapon.itemType == "weapon" then
                item:setActions(Inventory.actiontable.weapon)
            else
                item:setActions(Inventory.actiontable.UpgradableWeapon)

            end

            local pos = ply:GetPos() + ply:GetForward() * 50 + Vector(0, 0, 50)

            local ent = item:SpawnItem(pos)
            if weapon.customData.Skin then
                ent:SetMaterial(weapon.customData.Skin)
                ply:ChatPrint("Dropped weapon with skin applied.")
            end

            ply:StripWeapon(weapon:GetClass())
            BCORE.Inventory:Chat("You dropped " .. weapon.name .. ".",ply)
            BCORE.Inventory.Admin:LogAction(ply, "drop", weapon.id)
        end
        
        return ""  
    end
end)

hook.Add("PlayerCanPickupWeapon", "DisableAutoPickupWeapons", function(ply, weapon)
    if weapon.isitem then
        return false
    else
        return true
    end
end)


