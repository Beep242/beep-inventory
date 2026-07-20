
function defaultRanges(baseMin, baseMax)
    return {
        Common={min=baseMin,max=baseMax},
        Uncommon={min=baseMin*2,max=baseMax*2},
        Rare={min=baseMin*3,max=baseMax*3},
        Epic={min=baseMin*4,max=baseMax*4},
        Legendary={min=baseMin*5,max=baseMax*5},
        Celestial={min=baseMin*6,max=baseMax*6},
        God={min=baseMin*7,max=baseMax*7},
        Glitched={min=baseMin*8,max=baseMax*8},
        ["????????"]={min=baseMin*10,max=baseMax*12}
    }
end

function BCORE.Inventory:EquipSuit(ply, item)
    -- Was `not ply.currentsuit == "none"`, which parses as (not ply.currentsuit) == "none" -
    -- always false, since `not ply.currentsuit` is a boolean and can never equal a string.
    -- The "already equipped" guard below never actually fired.
    if ply.currentsuit and ply.currentsuit ~= "none" then
        BCORE.Inventory:Chat("You already have a suit equipped!", ply)
        return false
    end
    ply.suit_prev_model = ply:GetModel()
    ply.suit_prev_material = ply:GetMaterial()
    ply.suit_prev_jump = ply:GetJumpPower()
    ply.suit_prev_run = ply:GetRunSpeed()
    ply.suit_prev_walk = ply:GetWalkSpeed()
    ply.currentsuit = item
    ply:SetModel(ply.currentsuit.customData.model)
    ply:SetMaterial(ply.currentsuit.customData.Skin or "")
    ply:SetNW2Int("SuitHP", item.customData.Health)
    ply:SetNW2Int("SuitAP", item.customData.Armor)
    BCORE.Inventory:Chat("You equipped " .. item.name, ply)
    BCORE.Inventory:SyncSuit(ply)
    return true
end

function  BCORE.Inventory:DropSuit(ply)
    if ply.currentsuit == "none" then return end

    local item = ply.currentsuit
    ply:SetWalkSpeed(ply.suit_prev_walk)
    ply:SetRunSpeed(ply.suit_prev_run) 
    ply:SetJumpPower(ply.suit_prev_jump)
    ply:SetModel(ply.suit_prev_model or "models/player/kleiner.mdl")
    ply:SetMaterial(ply.suit_prev_material or "")

    local ent = item:SpawnItem(ply:GetPos() + Vector(0, 0, 20))
    ent.itemData = item
    ent.isSuit = true

    if ent.customData.Skin then
        ent:SetMaterial(ply.currentsuit.customData.Skin or "")
    end

    BCORE.Inventory:Chat("You dropped your suit.", ply)
    ply.currentsuit = "none"
    BCORE.Inventory:SyncSuit(ply)
    return ent
end


local suit = {}

suit.Drop = function(item, ply)
    local pos = ply:GetPos() + Vector(0, 0, 50) + ply:GetForward() * 60
    local ent  = item:SpawnItem(pos)
    ent.isSuit = true
    ent.itemData = item
    if ent.itemData.customData.Skin then
        ent:SetMaterial(ent.itemData.customData.Skin or "")
    end
    ply:RemoveItem(item)
end

suit.Destroy = function(item, ply)
    ply:RemoveItem(item)
end 

suit.Use = function(item, ply)
    BCORE.Inventory:Chat("Equiped: " .. item.name)
    local success = BCORE.Inventory:EquipSuit(ply, item)
    if not success then return end
    ply:RemoveItem(item)
end  


suit.Upgrade = function(item, ply)
    local currentRarity = item.rarity
    if currentRarity == BCORE.Inventory:GetHighestRarity() then 
        BCORE.Inventory:Chat("Your " .. item.name .. " is already at the highest rarity!", ply)
        return 
    end

    local nextRarity = BCORE.Inventory:GetNextRarity(currentRarity)
    if not nextRarity then 
        BCORE.Inventory:Chat("Error determining next rarity for " .. item.name .. "!", ply)
        return 
    end

    local suitDef = BCORE.Inventory.Suits[item.customData.Type]
    if not suitDef then
        BCORE.Inventory:Chat("No suits found for this item type!", ply)
        return
    end

    for statName, rarityTable in pairs(suitDef.stats) do
        local currentValue = item:GetProperty(statName) or 0
        local nextStatData = rarityTable[nextRarity]

        if nextStatData then
            local newValue = math.random(nextStatData.min, nextStatData.max)
            item:SetProperty(statName, newValue)
        else
            item:SetProperty(statName, math.ceil(currentValue * 1.05))
        end
    end
    item:SetProperty("maxap", item:GetProperty("Armor"))
    item:SetProperty("maxhp", item:GetProperty("Health"))

    item.rarity = nextRarity
    ply:UpdateItem(item)
    BCORE.Inventory:Chat("Your " .. item.name .. " has been upgraded to " .. nextRarity .. "!", ply)
    BCORE.Inventory.Admin:LogAction(ply, "upgrade", item.id)
end

suit.RollSkin = function(item, ply)
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

suit.Socket = function(item, ply)

end
util.AddNetworkString("RepairSuit")

-- Registered ONCE at file scope, never inside suit.Repair. The old version re-registered
-- net.Receive("RepairSuit", ...) on every single repair request, closing over that call's own
-- `item` local - since net.Receive only ever keeps the LAST-registered callback per message
-- name (globally, not per-player), a second repair request from anyone before the first one's
-- confirmation arrived would silently repair the WRONG item (even a different player's item)
-- using whichever `item`/`ply` the most recent registration happened to capture. The client
-- now echoes back the item id it was quoted a price for, so the server always looks the item
-- up fresh via the real owning player rather than trusting a stale closure. This also fixes a
-- second bug: no money was ever actually deducted here (unlike RollSkin, just above).
net.Receive("RepairSuit", function(len, ply)
    if not IsValid(ply) then return end
    local itemID = net.ReadUInt(32)

    local item = ply:GetItemByID and ply:GetItemByID(itemID)
    if not item or not item.customData or item.customData.Type == nil then return end
    if not BCORE.Inventory.Suits[item.customData.Type] then return end -- not actually a suit

    local maxHP = item.customData.maxhp or 0
    local maxAP = item.customData.maxap or 0
    local currentHP = item:GetProperty("Health") or 0
    local currentAP = item:GetProperty("Armor") or 0

    if currentHP >= maxHP and currentAP >= maxAP then
        BCORE.Inventory:Chat("Your " .. item.name .. " is already fully repaired!", ply)
        return
    end

    local cost = (maxHP + maxAP) * BCORE.Inventory.config.PricePerHpAndAp
    if not ply.getDarkRPVar or ply:getDarkRPVar("money") < cost then
        BCORE.Inventory:Chat("You don't have enough money to repair your " .. item.name .. "! Cost: " .. cost, ply)
        return
    end

    ply:addMoney(-cost)
    item:SetProperty("Health", maxHP)
    item:SetProperty("Armor", maxAP)
    ply:UpdateItem(item)
    BCORE.Inventory:Chat("Your " .. item.name .. " has been repaired!", ply)
end)

suit.Repair = function(item, ply)
    net.Start("RepairSuit")
    net.WriteFloat((item.customData.maxhp + item.customData.maxap) * BCORE.Inventory.config.PricePerHpAndAp)
    net.WriteUInt(item.id, 32)
    net.Send(ply)
end

BCORE.Inventory:RegisterType("Suit", suit)

local suits = BCORE.Inventory.Suits
SUIT = SUIT or {}



function BCORE.Inventory:CreateSuit(name, stats, description, model, onHitFunction, abilities,ongive,onremove)
    local suit = {
        stats = stats,
        description = description,
        OnHit = onHitFunction,
        model = model,
        abilities = abilities or {},
        Type = name,
        onremove = onremove,
        ongive = ongive,
    }
    local safeablities = {}
    for abilityName, abilityData in pairs(abilities or {}) do
        safeablities[abilityName] = {
            KeyBind = abilityData.KeyBind,
            Cooldown = abilityData.Cooldown,
            description = abilityData.description,
        }
    end
    suits[name] = {stats = stats, description = description,model = model, abilities = safeablities}
    SUIT[name] = suit
end

local function GetSuit(ply)
    return ply.currentsuit
end

local function SetSuit(ply,suit)
    ply.currentsuit = suit
end

hook.Add("Think", "BCORE_SuitSmoothRegen", function()
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() then continue end
        local item = ply.currentsuit
        if not item or not item.customData then continue end

        local cd = item.customData
        if not cd then continue end

        local hp = cd.Armor or 0
        local ap = cd.Health or 0
        local maxHP = hp
        local maxAP = ap
        local regen = cd.Regen or 0
        local ft = FrameTime()
        local regenAmount = regen * ft

        local newHP = math.min(hp + regenAmount, maxHP)
        local newAP = math.min(ap + regenAmount, maxAP)

        if math.floor(newHP) ~= math.floor(hp) then
            cd.hp = newHP
            ply:SetNW2Int("SuitHP", math.floor(newHP))
        end

        if math.floor(newAP) ~= math.floor(ap) then
            cd.ap = newAP
            ply:SetNW2Int("SuitAP", math.floor(newAP))
        end

        local speedMult = cd.Speed or 1
        local jumpMult = cd.Jump or 1
        ply:SetWalkSpeed(200 * speedMult)
        ply:SetRunSpeed(400 * speedMult)
        ply:SetJumpPower(200 * jumpMult)
    end
end)

hook.Add("EntityTakeDamage", "BCORE_SuitVirtualDamage", function(target, dmginfo)
    if not target:IsPlayer() then return end
    if not target.currentsuit then return end

    local item = target.currentsuit
    if not item or not item.customData then return end

    local cd = item.customData
    local resistance = cd.Resistance or 1
    local ap = cd.Armor or 0
    local hp = cd.Health or 0

    local damage = dmginfo:GetDamage() * resistance

    if ap > 0 then
        if damage <= ap then
            cd.Armor = ap - damage
            target:SetNW2Int("SuitAP", math.floor(cd.Armor))
            dmginfo:SetDamage(0)
            return
        else
            damage = damage - ap
            cd.Armor = 0
            target:SetNW2Int("SuitAP", 0)
        end
    end


    if hp > 0 then
        if damage <= hp then
            cd.Health = hp - damage
            target:SetNW2Int("SuitHP", math.floor(cd.Health))
            dmginfo:SetDamage(0)
            return
        else
            damage = damage - hp
            cd.Health = 0
            target:SetNW2Int("SuitHP", 0)
        end
    end

    dmginfo:SetDamage(damage)

    if item.OnHit then
        item.OnHit(target, dmginfo, item)
    end
end)

hook.Add("PlayerDeath", "BCORE_SuitDeathDrop", function(ply)
    if ply.currentsuit == "none" then return end
    local ent = BCORE.Inventory:DropSuit(ply)
    ent:Remove()
end)

concommand.Add("dropsuit", function(ply)
    if not IsValid(ply) then return end
    if ply.currentsuit == "none" then
        BCORE.Inventory:Chat("You are not wearing a suit.", ply)
        return
    end

    BCORE.Inventory:DropSuit(ply)
end)

util.AddNetworkString("BCORE_SuitAbilities")
hook.Add("PlayerButtonDown", "BCORE_SuitAbilities", function(ply, key)
    local item = GetSuit(ply)
    if item == "none" then return end
    local abilities = SUIT[item.customData.Type].abilities
    if not abilities then return end
    for name, ability in pairs(abilities) do
        if ability.KeyBind and key == ability.KeyBind then
            local curTime = CurTime()
            if curTime - (ability.LastUsed or 0) >= ability.Cooldown then
                ability.Action(ply)
                ability.LastUsed = curTime
                BCORE.Inventory:Chat("Activated " .. name .. "!", ply)
                net.Start("BCORE_SuitAbilities")
                net.WriteString(name)
                net.Send(ply)
            end
        end
    end
end)

function BCORE.Inventory:LoadSuits(ply)
    BCORE.Inventory:RegisterSuits(BCORE.Inventory.Suits)
    BCORE.netstream.Start(ply, "suit_ent", BCORE.Inventory.Suits)
end




