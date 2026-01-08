BCORE.Inventory.Admin = BCORE.Inventory.Admin or {}

local Inventory = BCORE.Inventory.Admin
Inventory.Logs = Inventory.Logs or {}
Inventory.AdminLogs = Inventory.AdminLogs or {}

function Inventory:IsAdmin(ply)
    for _, group in ipairs(BCORE.Inventory.config.Admins or {}) do
        if ply:IsUserGroup(group) then
            return true
        end
    end
    return false
end

function Inventory:Log(admin, action, targetSteamID, extra)
    if not Inventory:IsAdmin(admin) then return end

    local log = {
        time = os.time(),
        admin = IsValid(admin) and admin:Nick() or "Console",
        action = action,
        target = targetSteamID,
        extra = extra or ""
    }
    table.insert(self.AdminLogs, log)
    print(string.format("[InventoryAdmin] [%s] %s -> %s (%s)",
        os.date("%Y-%m-%d %H:%M:%S", log.time),
        log.admin, action, log.target
    ))
end

function Inventory:GetOnlineInventory(steamid64)
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == steamid64 then
            print("Found online player with SteamID64: " .. steamid64)
            return true, ply
        end
    end
    return BCORE.Inventory.DataBase:loadBySteamID64(steamid64)
end

function Inventory:DeleteItem(admin, targetSteamID64, itemTable)
    if not Inventory:IsAdmin(admin) then return end

    local isOnline, ply = Inventory:GetOnlineInventory(targetSteamID64)

    if isOnline and IsValid(ply) then
        ply:RemoveItem(itemTable)
    else
        local data = Inventory:GetInventory(targetSteamID64)
        if not data then return false end

        for k, v in pairs(data) do
            if v.id == itemID then
                data[k] = nil
                break
            end
        end

        BCORE.Inventory.DataBase:saveBySteamID64(targetSteamID64, data)
    end
    return true
end


function Inventory:GiveItem(admin, targetSteamID64, itemTable)
    if not Inventory:IsAdmin(admin) then return end

    local isOnline, ply = Inventory:GetOnlineInventory(targetSteamID64)
    local itemID = itemTable.id or "item_" .. math.random(100000, 999999)
    itemTable.id = itemID

    if isOnline and IsValid(ply) then
        ply:AddItem(itemTable)
    else
        local data = Inventory:GetInventory(targetSteamID64) or {}
        data[itemID] = itemTable
        BCORE.Inventory.DataBase:saveBySteamID64(targetSteamID64, data)
    end

    return true
end

function Inventory:EditItem(admin, targetSteamID64, itemID, newItemTable)
    if not Inventory:IsAdmin(admin) then return end

    local isOnline, ply = Inventory:GetOnlineInventory(targetSteamID64)
    newItemTable.id = itemID

    if isOnline and IsValid(ply) then
        ply:EditItem(newItemTable)
        ply:UpdateItem(newItemTable)
    else
        local data = Inventory:GetInventory(targetSteamID64)
        if not data then return false end

        for k, v in pairs(data) do
            if v.id == itemID then
                data[k] = newItemTable
                break
            end
        end

        BCORE.Inventory.DataBase:saveBySteamID64(targetSteamID64, data)
    end

    return true
end

function Inventory:WipeInventory(admin, targetSteamID64)
    if not Inventory:IsAdmin(admin) then return end

    local isOnline, ply = Inventory:GetOnlineInventory(targetSteamID64)

    if isOnline and IsValid(ply) then
        ply:ClearInventory()
    else
        local data = Inventory:GetInventory(targetSteamID64)
        if not data then return false end

        data = {}
        BCORE.Inventory.DataBase:saveBySteamID64(targetSteamID64, data)
    end

    return true
end



function Inventory:LogAction(player, action, itemID, extra)
    if not Inventory:IsAdmin(player) then return end

    local log = {
        time = os.time(),
        player = IsValid(player) and player:Nick() or "Unknown",
        steamid64 = IsValid(player) and player:SteamID64() or "unknown",
        action = action,
        item = itemID or "N/A",
        extra = extra or ""
    }

    table.insert(self.Logs, log)

    print(string.format(
        "[Inventory] [%s] %s (%s) - %s [%s] %s",
        os.date("%Y-%m-%d %H:%M:%S", log.time),
        log.player,
        log.steamid64,
        action,
        itemID or "N/A",
        extra or ""
    ))
end

function Inventory:GetAllPlayers()
    local query = "SELECT steamid64 FROM bcore_inventories;"
    local result = sql.Query(query)

    if not result or #result == 0 then
        print("[InventoryAdmin] No player inventories found.")
        return {}
    end

    local steamIDs = {}
    for _, row in ipairs(result) do
        table.insert(steamIDs, row.steamid64)
    end

    print("[InventoryAdmin] Found " .. #steamIDs .. " players in database.")
    return steamIDs
end

function Inventory:GetLogs()
    return self.AdminLogs
end

function Inventory:GetActionLogs()
    return self.Logs
end

local thread = BCORE.netstream

thread.Hook("BCORE.Inventory.Admin.RequestPlayers", function(ply)
    print("[InventoryAdmin] Requesting player list from " .. (IsValid(ply) and ply:Nick() or "Console"))
    local allPlayers = BCORE.Inventory.Admin:GetAllPlayers()
    thread.Start(ply, "BCORE.Inventory.Admin.SendPlayers", allPlayers)
end)

thread.Hook("BCORE.Inventory.Admin.RequestPlayerInventory", function(ply, steamid)
    print("[InventoryAdmin] Requesting player inventory from " .. (IsValid(ply) and ply:Nick() or "Console"))
    local inventory = BCORE.Inventory.Admin:GetInventory(steamid)
    if inventory then
        thread.Start(ply, "BCORE.Inventory.Admin.SendPlayerInventory", inventory)
    end
end)

thread.Hook("BCORE.Inventory.Admin.RequestAdminLogs", function(ply)
    print("[InventoryAdmin] Requesting admin logs from " .. (IsValid(ply) and ply:Nick() or "Console"))
    local adminLogs = BCORE.Inventory.Admin:GetLogs()
    PrintTable(adminLogs)
    thread.Start(ply, "BCORE.Inventory.Admin.SendAdminLogs", adminLogs)
end)

thread.Hook("BCORE.Inventory.Admin.RequestAdminActionLogs", function(ply)
    local actionLogs = BCORE.Inventory.Admin:GetActionLogs()
    thread.Start(ply, "BCORE.Inventory.Admin.SendAdminActionLogs", actionLogs)
end)

thread.Hook("BCORE.Inventory.Admin.RequestItemTypes", function(ply)
    print("[InventoryAdmin] Requesting item types from " .. (IsValid(ply) and ply:Nick() or "Console"))
    local itemTypes = BCORE.Inventory.actiontable or {}
    thread.Start(ply, "BCORE.Inventory.Admin.SendItemTypes", itemTypes)
end)

thread.Hook("BCORE.Inventory.Admin.RequestAction", function(ply, steamid, action, itemID, extra)
    print("[InventoryAdmin] Requesting action from " .. (IsValid(ply) and ply:Nick() or "Console"))
    print("[InventoryAdmin] Target player: " .. (steamid or "Unknown") .. ", Action: " .. action .. ", ItemID: " .. (itemID or "N/A"))

    if not BCORE.Inventory.Admin:IsAdmin(ply) then
        print("[InventoryAdmin] " .. (IsValid(ply) and ply:Nick() or "Console") .. " is not an admin.")
        return
    end

    if action == "delete" then
        BCORE.Inventory.Admin:DeleteItem(ply, steamid, extra)
        BCORE.Inventory.Admin:Log(ply or "Console", "DeleteItem", steamid, "ItemID: " .. extra.id)
    elseif action == "give" then
        local itemTable = extra
        itemTable.id = GenerateUniqueID()
        setmetatable(itemTable, BCORE.Inventory.Item)
        itemTable:setActions( BCORE.Inventory.actiontable[itemTable.itemType])
        BCORE.Inventory.Admin:GiveItem(ply, steamid, itemTable)
        BCORE.Inventory.Admin:Log(ply or "Console", "GiveItem", steamid, "ItemID: " .. itemTable.id)
    elseif action == "edit" then
        local newItemTable = extra
        BCORE.Inventory.Admin:EditItem(ply, steamid, itemID, newItemTable)
        BCORE.Inventory.Admin:Log(ply or "Console", "EditItem", steamid, "ItemID: " .. itemID)
    elseif action == "wipe" then
        BCORE.Inventory.Admin:WipeInventory(ply, steamid)
        BCORE.Inventory.Admin:Log(ply or "Console", "WipeInventory", steamid)
    elseif action == "duplicate" then
        local itemTable = extra
        itemTable.id = GenerateUniqueID()
        setmetatable(itemTable, BCORE.Inventory.Item)
        itemTable:setActions( BCORE.Inventory.actiontable[itemTable.itemType])
        BCORE.Inventory.Admin:GiveItem(ply, ply:SteamID64(), itemTable)
        BCORE.Inventory.Admin:Log(ply or "Console", "Duplicate", steamid, "ItemID: " .. itemTable.id)
    end
end)


function Inventory:CreateLogsTables()
    local adminQuery = [[
        CREATE TABLE IF NOT EXISTS inventory_admin_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time INTEGER NOT NULL,
            admin_name TEXT NOT NULL,
            action TEXT NOT NULL,
            target_steamid TEXT NOT NULL,
            extra TEXT
        );
    ]]
    local actionQuery = [[
        CREATE TABLE IF NOT EXISTS inventory_action_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time INTEGER NOT NULL,
            player_name TEXT NOT NULL,
            steamid64 TEXT NOT NULL,
            action TEXT NOT NULL,
            item_id TEXT,
            extra TEXT
        );
    ]]
    sql.Query(adminQuery)
    sql.Query(actionQuery)
end

function Inventory:LoadAdminLogs()
    local result = sql.Query("SELECT * FROM inventory_admin_logs ORDER BY time DESC;")
    self.AdminLogs = {}

    if not result then return end

    for _, row in ipairs(result) do
        table.insert(self.AdminLogs, {
            time = tonumber(row.time),
            admin = row.admin_name,
            action = row.action,
            target = row.target_steamid,
            extra = row.extra
        })
    end
end

function Inventory:LoadActionLogs()
    local result = sql.Query("SELECT * FROM inventory_action_logs ORDER BY time DESC;")
    self.Logs = {}
    if not result then return end
    for _, row in ipairs(result) do
        table.insert(self.Logs, {
            time = tonumber(row.time),
            player = row.player_name,
            steamid64 = row.steamid64,
            action = row.action,
            item = row.item_id,
            extra = row.extra
        })
    end
end

function Inventory:SaveAdminLogs()
    sql.Query("DELETE FROM inventory_admin_logs;")
    for _, log in ipairs(self.AdminLogs or {}) do
        local query = string.format([[
            INSERT INTO inventory_admin_logs (time, admin_name, action, target_steamid, extra)
            VALUES (%d, %s, %s, %s, %s);
        ]],
        log.time,
        sql.SQLStr(log.admin),
        sql.SQLStr(log.action),
        sql.SQLStr(log.target),
        sql.SQLStr(log.extra or "")
        )
        sql.Query(query)
    end
    print("SQL Last Error:", sql.LastError() or "No error")
end

function Inventory:SaveActionLogs()
    sql.Query("DELETE FROM inventory_action_logs;")
    for _, log in ipairs(self.Logs or {}) do
        local query = string.format([[
            INSERT INTO inventory_action_logs (time, player_name, steamid64, action, item_id, extra)
            VALUES (%d, %s, %s, %s, %s, %s);
        ]],
        log.time,
        sql.SQLStr(log.player),
        sql.SQLStr(log.steamid64),
        sql.SQLStr(log.action),
        sql.SQLStr(log.item or ""),
        sql.SQLStr(log.extra or "")
        )
        sql.Query(query)
    end
    print("SQL Last Error:", sql.LastError() or "No error")
end

Inventory:CreateLogsTables()

hook.Add("PlayerSay", "BCORE.Inventory.OpenAdminMenu", function(ply, text)
    if text == "!invadmin" and Inventory:IsAdmin(ply) then
            ply:ConCommand("beep_Inventory_admin_open")
        return ""
    end
end)