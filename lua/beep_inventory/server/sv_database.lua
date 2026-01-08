BCORE.Inventory.DataBase = BCORE.Inventory.DataBase or {}

local function createTables()
    local query = [[
        CREATE TABLE IF NOT EXISTS bcore_inventories (
            steamid64 TEXT PRIMARY KEY,
            inventory_data TEXT
        );
    ]]
    local result = sql.Query(query)
    if result == false then
        print("Error " .. (sql.LastError() or "Who the hell knows?"))
    end
end

local function saveInventory(steamID64, inventoryTable)
    local safe = sql.SQLStr(util.TableToJSON(inventoryTable or {}))

    local query = string.format(
        "INSERT INTO bcore_inventories (steamid64, inventory_data) VALUES (%s, %s) " ..
        "ON CONFLICT(steamid64) DO UPDATE SET inventory_data = %s;",
        sql.SQLStr(steamID64), safe, safe
    )

    local result = sql.Query(query)
    if result == false then
        print("Error saving inventory for " .. steamID64 .. " - " .. (sql.LastError() or "Unknown error"))
    else
        print("Inventory saved for " .. steamID64)
    end
end

function BCORE.Inventory.DataBase:save(player)
    if not IsValid(player) then return end
    local steamID64 = player:SteamID64()
    local inventory = player:GetInventory()
    saveInventory(steamID64, inventory)
end

function BCORE.Inventory.DataBase:saveBySteamID64(steamID64, inventoryTable)
    saveInventory(steamID64, inventoryTable)
end

function BCORE.Inventory.DataBase:load(player)
    if not IsValid(player) then return end
    return self:loadBySteamID64(player:SteamID64(), player)
end

function BCORE.Inventory.DataBase:loadBySteamID64(steamID64, optionalPlayer)
    local query = string.format(
        "SELECT inventory_data FROM bcore_inventories WHERE steamid64 = %s;",
        sql.SQLStr(steamID64)
    )
    local result = sql.Query(query)

    if result and result[1] then
        local inventoryData = util.JSONToTable(result[1].inventory_data or "{}")
        if inventoryData then
            if optionalPlayer and IsValid(optionalPlayer) then
                print("Inventory loaded for: " .. optionalPlayer:Nick())
            else
                print("Inventory loaded for offline player: " .. steamID64)
            end
            return inventoryData
        else
            print("Error decoding inventory for " .. steamID64)
        end
    else
        print("No inventory found for " .. steamID64)
    end
end

createTables()
