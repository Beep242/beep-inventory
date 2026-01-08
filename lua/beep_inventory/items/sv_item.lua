BCORE.Inventory.Item = {}
local Item = BCORE.Inventory.Item

Item.__index = Item

local usedIDs = {}
local nextItemID = 1

if not sql.TableExists("bcore_unique_ids") then
    sql.Query("CREATE TABLE IF NOT EXISTS bcore_unique_ids (id INTEGER PRIMARY KEY AUTOINCREMENT)")
end

do
    local result = sql.Query("SELECT MAX(id) AS max_id FROM bcore_unique_ids")
    if istable(result) and result[1] and tonumber(result[1].max_id) then
        nextItemID = tonumber(result[1].max_id) + 1
    else
        nextItemID = 1
    end
end

function GenerateUniqueID()
    local success = sql.Query("INSERT INTO bcore_unique_ids DEFAULT VALUES")

    if success == false then
        error("[BCORE] SQLite insert failed: " .. (sql.LastError() or "unknown error"))
    end

    local id = sql.QueryValue("SELECT last_insert_rowid()")
    id = tonumber(id)

    usedIDs[id] = true
    if id >= nextItemID then
        nextItemID = id + 1
    end

    return id
end


function Item:new(className, name, model, rarity, itemType, customData)
    local obj = setmetatable({}, self)
    obj.id = obj.id or GenerateUniqueID()
    obj.className = className or "default"
    obj.name = name or "Unknown Item"
    obj.model = model or "models/props_junk/cardboard_box001a.mdl"
    obj.rarity = rarity or "Common"
    obj.itemType = itemType or "generic"
    obj.customData = customData or {}
    obj.onAction = {} 
    obj.isitem = true
    return obj
end

function Item:setActions(actions)
    self.onAction = actions
end

function Item:PerformAction(action, ply)
    if self.onAction and self.onAction[action] then
        return self.onAction[action](self, ply)
    end
end

function Item:SpawnItem(pos, ang)
    if not pos then return end

    local ent = ents.Create(self.className)
    

    if not IsValid(ent) then return end
    ent:SetModel(self.model)
    ent:SetPos(pos)
    if ang then ent:SetAngles(ang) end

    ent:Spawn()

    ent.className = self.className
    ent.name = self.name
    ent.rarity = self.rarity
    ent.itemType = self.itemType
    ent.customData = self.customData
    ent.isitem = true

    ent:SetNWString("ItemName", self.name)
    ent:SetNWString("ItemId", self.id)
    ent:SetNWString("ItemModel", self.model)
    ent:SetNWString("ItemRarity", self.rarity)
    ent:SetNWBool("IsItem", true)

if self.customData then 
    local i = 1 
    local modIndex = 1 

    

    for key, value in pairs(self.customData) do
        if self.customData.baseStats then continue end
        if key == "abilities" or key == "Type" or key == "Description" or key == "model" then continue end
        if key == "Modifiers" and istable(value) then
            for _, modTable in pairs(value) do
                if modTable.name then
                    ent:SetNWString("Modifier_" .. modIndex .. "_Name", modTable.name)
                end
                if modTable.rarity then
                    ent:SetNWString("Modifier_" .. modIndex .. "_Rarity", modTable.rarity)
                end

                if istable(modTable.customData) then
                    local modDataIndex = 1
                    for dataKey, dataValue in pairs(modTable.customData) do
                        if dataKey == "Description" then continue end
                        ent:SetNWString("Modifier_" .. modIndex .. "_" .. modDataIndex, dataKey .. ": " .. tostring(dataValue))
                        modDataIndex = modDataIndex + 1
                    end
                end

                modIndex = modIndex + 1
            end
        else
            ent:SetNWString("Custom_" .. i, key .. ": " .. tostring(value))
    
            i = i + 1
        end
    end
end

    return ent
end

function Item:GiveWeapon(ply)
    ply:Give(self.className)
    ply:SelectWeapon(self.className)
    local wep = ply:GetWeapon(self.className)
    if IsValid(wep) then
        self:ApplyCustomizations(wep)
        wep.className = self.className
        wep.name = self.name
        wep.rarity = self.rarity
        wep.itemType = self.itemType
        wep.customData = self.customData
        wep.isitem = true 
    end
    return ent
end

function Item:SetProperty(key, value)
    self.customData[key] = value
end

function Item:GetProperty(key)
    return self.customData[key]
end

function Item:Package()
    local safeData = {
        id = self.id,
        className = self.className,
        name = self.name,
        model = self.model,
        rarity = self.rarity,
        itemType = self.itemType,
        customData = table.Copy(self.customData)
    }
    
    if self.onAction then
        local actionKeys = {}
        for key, _ in pairs(self.onAction) do
            table.insert(actionKeys, key)
        end
        safeData.onAction = actionKeys
    end


    if safeData.customData["Modifiers"] then
        for _, modifier in ipairs(safeData.customData["Modifiers"]) do
            if modifier.onAction then
                local modActionKeys = {}
                for key, _ in pairs(modifier.onAction) do
                    table.insert(modActionKeys, key)
                end
                modifier.onAction = modActionKeys
            end
        end
    end

    return safeData
end



