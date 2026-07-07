local thread = BCORE.netstream

util.AddNetworkString("BCORE.Inventory.Chat")

function BCORE.Inventory:Chat(message,ply)
    net.Start("BCORE.Inventory.Chat")
    net.WriteString(message)
    
    if ply then
        net.Send(ply) 
    else
        net.Broadcast()
    end
end

function BCORE.Inventory:SyncInventory(ply)
    if not IsValid(ply) then return end

    local inventory = ply:PackageInventory()
    if not inventory then
        print("[ERROR] Inventory is nil for player " .. ply:Nick())
        return
    end

    thread.Start(ply, "InventorySync", inventory)
end

thread.Hook("BCORE.Inventory.RequestAction", function(ply, itemID, action)
    local inventory = ply:GetInventory()
    if not inventory or not itemID or not action then return end
    for k, item in ipairs(inventory) do
        if item.id == itemID then
            if item.onAction and item.onAction[action] then
                local success = item:PerformAction(action, ply)
                BCORE.Inventory:SyncInventory(ply)
            else
                ply:ChatPrint("This action is not available for this item.")
            end
        end
    end


end)

thread.Hook("BCORE.Inventory.MassDelete", function(ply, deleteTbl)
    if not istable(deleteTbl) then return end


    local inventory = ply:GetInventory()
    if not istable(inventory) then return end

    local lookup = {}

    for id, enabled in pairs(deleteTbl) do
        if enabled then
            lookup[id] = true
        end
    end

    local snapshot = {}
    for i, item in pairs(inventory) do
        snapshot[i] = item
    end

    for _, item in pairs(snapshot) do
        if item and item.id and lookup[item.id] then
            ply:RemoveItem(item)
        end
    end
end)

function BCORE.Inventory:SyncSuit(ply)
    if not IsValid(ply) or not ply.currentsuit  then return end
    if ply.currentsuit == "none" then thread.Start(ply, "SuitSync", "none") return end
    local suit = ply.currentsuit
    suit["onAction"] = nil
    if suit.customData then
        suit.customData.abilities = BCORE.Inventory.Suits[suit.customData.Type].abilities -- Remove action functions before sending over network
    end
    if not suit then
        print("[ERROR] Suit is nil for player " .. ply:Nick())
        return
    end

    thread.Start(ply, "SuitSync", suit)
end
