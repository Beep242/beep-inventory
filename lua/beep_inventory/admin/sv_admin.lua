BCORE.Inventory.Admin = BCORE.Inventory.Admin or {}

local Inventory = BCORE.Inventory.Admin
Inventory.Logs      = Inventory.Logs      or {}
Inventory.AdminLogs = Inventory.AdminLogs or {}

function Inventory:IsAdmin(ply)
    for _, group in ipairs(BCORE.Inventory.config.Admins or {}) do
        if ply:IsUserGroup(group) then return true end
    end
    return false
end

function Inventory:Log(admin, action, targetSteamID, extra)
    if not Inventory:IsAdmin(admin) then return end
    local log = {
        time   = os.time(),
        admin  = IsValid(admin) and admin:Nick() or "Console",
        action = action,
        target = targetSteamID,
        extra  = extra or ""
    }
    table.insert(self.AdminLogs, log)

end

function Inventory:LogAction(player, action, itemID, extra)
    if not Inventory:IsAdmin(player) then return end
    local log = {
        time      = os.time(),
        player    = IsValid(player) and player:Nick() or "Unknown",
        steamid64 = IsValid(player) and player:SteamID64() or "unknown",
        action    = action,
        item      = itemID or "N/A",
        extra     = extra or ""
    }
    table.insert(self.Logs, log)
end

function Inventory:GetLogs()       return self.AdminLogs end
function Inventory:GetActionLogs() return self.Logs       end

function Inventory:GetOnlineInventory(steamid64)
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == steamid64 then
            return true, ply
        end
    end
    return BCORE.Inventory.DataBase:loadBySteamID64(steamid64)
end

local function packageArray(rawArray)
    local items = {}
    for index, item in ipairs(rawArray or {}) do
        if type(item) == "table" then
            if getmetatable(item) ~= BCORE.Inventory.Item then
                setmetatable(item, BCORE.Inventory.Item)
            end
            local packaged = item.Package and item:Package() or item
            packaged.slot = item.slot or index
            table.insert(items, packaged)
        end
    end
    return items
end

function Inventory:GetInventory(steamid64)
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == steamid64 then
            return packageArray(ply.BCORE_Inventory)
        end
    end
    local ok, data = BCORE.Inventory.DataBase:loadBySteamID64(steamid64)
    data = (ok and data) or data or {}
    for index, item in ipairs(data) do
        if type(item) == "table" and not item.slot then
            item.slot = index
        end
    end
    return data
end


local function EnsureItemMeta(itemTable)
    if type(itemTable) == "table" and getmetatable(itemTable) ~= BCORE.Inventory.Item then
        setmetatable(itemTable, BCORE.Inventory.Item)
        if itemTable.itemType and BCORE.Inventory.actiontable[itemTable.itemType] then
            itemTable:setActions(BCORE.Inventory.actiontable[itemTable.itemType])
        end
    end
    return itemTable
end

function Inventory:DeleteItem(admin, targetSteamID64, itemTable)
    if not Inventory:IsAdmin(admin) then return false end
    local isOnline, ply = Inventory:GetOnlineInventory(targetSteamID64)
    if isOnline and IsValid(ply) then
        ply:RemoveItem(EnsureItemMeta(itemTable))
    else
        local data = Inventory:GetInventory(targetSteamID64)
        if not data then return false end
        for i, v in ipairs(data) do
            if v.id == itemTable.id then table.remove(data, i) break end
        end
        BCORE.Inventory.DataBase:saveBySteamID64(targetSteamID64, data)
    end
    return true
end

function Inventory:GiveItem(admin, targetSteamID64, itemTable)
    if not Inventory:IsAdmin(admin) then return false end
    local isOnline, ply = Inventory:GetOnlineInventory(targetSteamID64)
    itemTable.id = itemTable.id or "item_" .. math.random(100000, 999999)
    if isOnline and IsValid(ply) then
        ply:AddItem(EnsureItemMeta(itemTable))
    else
        local data = Inventory:GetInventory(targetSteamID64) or {}
        table.insert(data, itemTable)
        BCORE.Inventory.DataBase:saveBySteamID64(targetSteamID64, data)
    end
    return true
end

function Inventory:EditItem(admin, targetSteamID64, itemID, newItemTable)
    if not Inventory:IsAdmin(admin) then return false end
    local isOnline, ply = Inventory:GetOnlineInventory(targetSteamID64)
    newItemTable.id = itemID
    if isOnline and IsValid(ply) then
        ply:EditItem(EnsureItemMeta(newItemTable))
    else
        local data = Inventory:GetInventory(targetSteamID64)
        if not data then return false end
        for i, v in ipairs(data) do
            if v.id == itemID then data[i] = newItemTable break end
        end
        BCORE.Inventory.DataBase:saveBySteamID64(targetSteamID64, data)
    end
    return true
end

function Inventory:WipeInventory(admin, targetSteamID64)
    if not Inventory:IsAdmin(admin) then return false end
    local isOnline, ply = Inventory:GetOnlineInventory(targetSteamID64)
    if isOnline and IsValid(ply) then
        ply:ClearInventory()
    else
        BCORE.Inventory.DataBase:saveBySteamID64(targetSteamID64, {})
    end
    return true
end

function Inventory:DuplicateItem(admin, targetSteamID64, itemTable)
    if not Inventory:IsAdmin(admin) then return false end
    local newItem = table.Copy(itemTable)
    newItem.id = GenerateUniqueID()
    setmetatable(newItem, BCORE.Inventory.Item)
    newItem:setActions(BCORE.Inventory.actiontable[newItem.itemType])
    return Inventory:GiveItem(admin, targetSteamID64, newItem), newItem
end

function Inventory:GetAllPlayers()
    local result = sql.Query("SELECT steamid64 FROM bcore_inventories;")
    if not result or #result == 0 then

        return {}
    end
    local steamIDs = {}
    for _, row in ipairs(result) do table.insert(steamIDs, row.steamid64) end

    return steamIDs
end

local thread = BCORE.netstream

thread.Hook("BCORE.Inventory.Admin.RequestPlayers", function(ply)
    if not Inventory:IsAdmin(ply) then return end
    thread.Start(ply, "BCORE.Inventory.Admin.SendPlayers", Inventory:GetAllPlayers())
end)

thread.Hook("BCORE.Inventory.Admin.RequestPlayerInventory", function(ply, steamid, isModifiers)
    if not Inventory:IsAdmin(ply) then return end


    local inventory = Inventory:GetInventory(steamid)
    if not inventory then return end

    local normalInventory = {}
    local modifierInventory = {}

    local assignedSlots = {}
    local assignedModifierSlots = {}

    for _, item in ipairs(inventory) do
        if item.itemType == "Modifier" then
            local slot = 1

            while assignedModifierSlots[slot] do
                slot = slot + 1
            end

            item.slot = slot
            assignedModifierSlots[slot] = true

            table.insert(modifierInventory, item)
        else
            local slot = 1

            while assignedSlots[slot] do
                slot = slot + 1
            end

            item.slot = slot
            assignedSlots[slot] = true

            table.insert(normalInventory, item)
        end
    end

    thread.Start(
        ply,
        "BCORE.Inventory.Admin.SendPlayerInventory",
        isModifiers and modifierInventory or normalInventory,
        isModifiers == true
    )
end)
thread.Hook("BCORE.Inventory.Admin.RequestAdminLogs", function(ply)
    if not Inventory:IsAdmin(ply) then return end
    thread.Start(ply, "BCORE.Inventory.Admin.SendAdminLogs", Inventory:GetLogs())
end)

thread.Hook("BCORE.Inventory.Admin.RequestAdminActionLogs", function(ply)
    if not Inventory:IsAdmin(ply) then return end
    thread.Start(ply, "BCORE.Inventory.Admin.SendAdminActionLogs", Inventory:GetActionLogs())
end)

thread.Hook("BCORE.Inventory.Admin.RequestItemTypes", function(ply)
    if not Inventory:IsAdmin(ply) then return end
    thread.Start(ply, "BCORE.Inventory.Admin.SendItemTypes", BCORE.Inventory.actiontable or {})
end)

thread.Hook("BCORE.Inventory.Admin.RequestAction", function(ply, steamid, action, itemID, extra)
    if not Inventory:IsAdmin(ply) then
        return
    end

    local ok = false

    if action == "delete" then
        ok = Inventory:DeleteItem(ply, steamid, extra)
        if ok then Inventory:Log(ply, "DeleteItem", steamid, "ItemID: " .. tostring(extra and extra.id or itemID)) end
    elseif action == "give" then
        local itemTable = extra
        itemTable.id = GenerateUniqueID()
        setmetatable(itemTable, BCORE.Inventory.Item)
        itemTable:setActions(BCORE.Inventory.actiontable[itemTable.itemType])
        ok = Inventory:GiveItem(ply, steamid, itemTable)
        if ok then Inventory:Log(ply, "GiveItem", steamid, "ItemID: " .. itemTable.id) end
    elseif action == "edit" then
        ok = Inventory:EditItem(ply, steamid, itemID, extra)
        if ok then Inventory:Log(ply, "EditItem", steamid, "ItemID: " .. tostring(itemID)) end
    elseif action == "wipe" then
        ok = Inventory:WipeInventory(ply, steamid)
        if ok then Inventory:Log(ply, "WipeInventory", steamid) end
    elseif action == "duplicate" then
        ok = Inventory:DuplicateItem(ply, steamid, extra)
        if ok then Inventory:Log(ply, "Duplicate", steamid, "Source ItemID: " .. tostring(extra and extra.id)) end
    end

    if ok then
        local updatedInventory = Inventory:GetInventory(steamid)
        if updatedInventory then
            thread.Start(ply, "BCORE.Inventory.Admin.SendPlayerInventory", updatedInventory)
        end
    end
end)

function Inventory:CreateLogsTables()
    sql.Query([[CREATE TABLE IF NOT EXISTS inventory_admin_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        time INTEGER NOT NULL, admin_name TEXT NOT NULL,
        action TEXT NOT NULL, target_steamid TEXT NOT NULL, extra TEXT);]])
    sql.Query([[CREATE TABLE IF NOT EXISTS inventory_action_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        time INTEGER NOT NULL, player_name TEXT NOT NULL, steamid64 TEXT NOT NULL,
        action TEXT NOT NULL, item_id TEXT, extra TEXT);]])
end

function Inventory:LoadAdminLogs()
    local result = sql.Query("SELECT * FROM inventory_admin_logs ORDER BY time DESC;")
    self.AdminLogs = {}
    if not result then return end
    for _, row in ipairs(result) do
        table.insert(self.AdminLogs, {
            time=tonumber(row.time), admin=row.admin_name,
            action=row.action, target=row.target_steamid, extra=row.extra })
    end
end

function Inventory:LoadActionLogs()
    local result = sql.Query("SELECT * FROM inventory_action_logs ORDER BY time DESC;")
    self.Logs = {}
    if not result then return end
    for _, row in ipairs(result) do
        table.insert(self.Logs, {
            time=tonumber(row.time), player=row.player_name, steamid64=row.steamid64,
            action=row.action, item=row.item_id, extra=row.extra })
    end
end

function Inventory:SaveAdminLogs()
    sql.Query("DELETE FROM inventory_admin_logs;")
    for _, log in ipairs(self.AdminLogs or {}) do
        sql.Query(string.format(
            "INSERT INTO inventory_admin_logs (time,admin_name,action,target_steamid,extra) VALUES (%d,%s,%s,%s,%s);",
            log.time, sql.SQLStr(log.admin), sql.SQLStr(log.action),
            sql.SQLStr(log.target), sql.SQLStr(log.extra or "")))
    end
end

function Inventory:SaveActionLogs()
    sql.Query("DELETE FROM inventory_action_logs;")
    for _, log in ipairs(self.Logs or {}) do
        sql.Query(string.format(
            "INSERT INTO inventory_action_logs (time,player_name,steamid64,action,item_id,extra) VALUES (%d,%s,%s,%s,%s,%s);",
            log.time, sql.SQLStr(log.player), sql.SQLStr(log.steamid64),
            sql.SQLStr(log.action), sql.SQLStr(log.item or ""), sql.SQLStr(log.extra or "")))
    end
end

Inventory:CreateLogsTables()

hook.Add("PlayerSay", "BCORE.Inventory.OpenAdminMenu", function(ply, text)
    if text == "!invadmin" and Inventory:IsAdmin(ply) then
        ply:ConCommand("beep_Inventory_admin_open")
        return ""
    end
end)