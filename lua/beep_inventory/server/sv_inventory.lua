////////////////////////////////////////////////////
//////////// BCORE Inventory System ////////////////
////////////////////////////////////////////////////
/////////////Player MetaTable Functions/////////////
////////////////////////////////////////////////////

local PLAYER = FindMetaTable("Player")
local Inventory = BCORE.Inventory


function PLAYER:Initialize()
    if not self.BCORE_Inventory then
        self.BCORE_Inventory = {}
    end
end

function PLAYER:LoadInventory()
    self:Initialize()
    self.BCORE_Inventory = BCORE.Inventory.DataBase:load(self) or {}

    for i, item in ipairs(self.BCORE_Inventory) do
        setmetatable(item, BCORE.Inventory.Item)
        item:setActions(Inventory.actiontable[item.itemType])
    end

    BCORE.Inventory:SyncInventory(self)
end


function PLAYER:PackageInventory()
    self:Initialize()
    local items = {}

    for _, item in ipairs(self:GetInventory()) do
        if getmetatable(item) ~= BCORE.Inventory.Item then
            setmetatable(item, BCORE.Inventory.Item) 
        end

        if item.Package then  
            table.insert(items, item:Package())
        end
    end
    
    return items
end

function PLAYER:SaveInventory()
    self:Initialize()
    BCORE.Inventory.DataBase:save(self)
end

function PLAYER:GetInventory()
    self:Initialize()
    return self.BCORE_Inventory
end

function PLAYER:AddItem(item)
    self:Initialize()
    table.insert(self.BCORE_Inventory, item)
    BCORE.Inventory:SyncInventory(self)
end

function PLAYER:RemoveItem(item)
    self:Initialize()
    for i, invItem in ipairs(self.BCORE_Inventory) do
        if invItem.id == item.id then
            table.remove(self.BCORE_Inventory, i)
            BCORE.Inventory:SyncInventory(self)
            return
        end
    end
end

function PLAYER:UpdateItem(item)
    self:Initialize()
    for i, invItem in ipairs(self.BCORE_Inventory) do
        if invItem.id == item.id then
            BCORE.Inventory:SyncInventory(self)
            return
        end
    end
end

function PLAYER:GetItemByID(itemID)
    self:Initialize()
    for _, invItem in ipairs(self.BCORE_Inventory) do
        if invItem.id == itemID then
            return invItem
        end
    end
    return nil
end

function PLAYER:RemoveItemByID(itemID)
    self:Initialize()
    for i, invItem in ipairs(self.BCORE_Inventory) do
        if invItem.id == itemID then
            table.remove(self.BCORE_Inventory, i)
        end
    end
    return nil
end

function PLAYER:HasItem(itemID)
    self:Initialize()
    for _, invItem in ipairs(self.BCORE_Inventory) do
        if invItem.id == itemID then
            return true
        end
    end
    return false
end

function PLAYER:ClearInventory()
    self:Initialize()
    self.BCORE_Inventory = {}
    self:SaveInventory()
    BCORE.Inventory:SyncInventory(self)
end


function PLAYER:PickUp()
    local ent = self:GetEyeTrace().Entity

    if not IsValid(ent) then return end

    if ent.isitem then
        local item = BCORE.Inventory.Item:new(ent.className, ent.name, ent:GetModel(), ent.rarity, ent.itemType, ent.customData)
        item:setActions(Inventory.actiontable[item.itemType])
        self:AddItem(item)
        ent:Remove()
        BCORE.Inventory:Chat("You picked up a " .. ent.name,self)

    else
        BCORE.Inventory:Chat("This is not a valid item!",self)
    end
end

function PLAYER:EditItem(item)
    self:Initialize()
    for i, invItem in ipairs(self.BCORE_Inventory) do
        if invItem.id == item.id then
            self.BCORE_Inventory[i] = item

            setmetatable(self.BCORE_Inventory[i], BCORE.Inventory.Item)
            item:setActions(Inventory.actiontable[item.itemType])

            BCORE.Inventory:SyncInventory(self)
            return true
        end
    end
    return false 
end

local function randomizeStat(baseValue)
    return math.Round(baseValue * math.Rand(1, 2),0)
end

local DefaultWeapons = {
    "keys", "pocket", "weapon_physgun", "weapon_physcannon", "gmod_tool",
    "weapon_keypadchecker", "weaponchecker", "arrest_stick", "unarrest_stick",
    "stunstick", "door_ram", "med_kit", "weapon_fists", "gmod_camera",

    "weapon_pistol", "weapon_357", "weapon_smg1", "weapon_ar2", "weapon_shotgun",
    "weapon_crossbow", "weapon_frag", "weapon_crowbar", "weapon_rpg",
    "weapon_slam", "weapon_bugbait"
}

local DefaultWeaponSet = {}
for _, wep in ipairs(DefaultWeapons) do
    DefaultWeaponSet[wep] = true
end

for _, job in pairs(team.GetAllTeams()) do
    if istable(job.weapons) then
        for _, wep in ipairs(job.weapons) do
            DefaultWeaponSet[wep] = true
        end
    end
end

local function IsJobWeapon(class, ply)
    local job = ply:getJobTable()
    if not job or not istable(job.weapons) then return false end
    for _, wep in ipairs(job.weapons) do
        if wep == class then return true end
    end
    return false
end


function PLAYER:Holster()
    local weapon = self:GetActiveWeapon()
    if not IsValid(weapon) then return end

    local class = weapon:GetClass()

    if DefaultWeaponSet[class] or IsJobWeapon(class, self) then
        self:ChatPrint("This weapon is restricted")
        return
    end

    local function generateStat(statName, baseValue, rarity)
        local rarityConfig = BCORE.Inventory.config.Rarities[rarity]
        if rarityConfig and rarityConfig.multipliers[statName] then
            local minVal = rarityConfig.multipliers[statName].min
            local maxVal = rarityConfig.multipliers[statName].max
            return math.ceil(baseValue * math.Rand(minVal, maxVal))
        else
            return math.ceil(baseValue * math.Rand(1, 2))
        end
    end

    local rarity = "Common"

    if weapon.isitem then
        local item = BCORE.Inventory.Item:new(
            weapon.className,
            weapon.name,
            weapon:GetWeaponWorldModel(),
            weapon.rarity,
            weapon.itemType,
            weapon.customData
        )
        item:setActions(Inventory.actiontable[item.itemType])
        self:AddItem(item)
        self:StripWeapon(class)
        BCORE.Inventory:Chat("You holstered a " .. weapon.name, self)
    else
        local wep_base = weapons.Get(class)
        if not wep_base then return end

        local wapon = BCORE.Inventory.Item:new(
            wep_base.ClassName,
            wep_base.PrintName,
            wep_base.WorldModel or "models/props_c17/pulleywheels_large01.mdl",
            rarity,
            "UpgradableWeapon",
            {
                Damage    = wep_base.Primary and generateStat("Damage", wep_base.Primary.Damage or 50, rarity),
                Recoil    = wep_base.Primary and generateStat("Recoil", wep_base.Primary.Recoil or wep_base.Primary.KickUp or 1.2, rarity),
                ClipSize  = wep_base.Primary and generateStat("ClipSize", wep_base.Primary.ClipSize or 30, rarity),
                Spread    = wep_base.Primary and generateStat("Spread", wep_base.Primary.Spread or 0.05, rarity),
                RPM       = wep_base.Primary and generateStat("RPM", wep_base.Primary.RPM or 600, rarity),
            }
        )

        wapon:setActions(Inventory.actiontable[wapon.itemType])
        self:AddItem(wapon)
        self:StripWeapon(class)
        BCORE.Inventory.Admin:LogAction(self, "inv_holster", wapon.id)
    end
end


////////////////////////////////////////////////////////////////////////////////////////////////////////

function BCORE.Inventory:GetRarityMultiplier(tbl, rarityName, stat)
    local rarity = tbl[rarityName]
    if not rarity then return 1 end

    local data = rarity.multipliers[stat]
    if not data then return 1 end

    if data.min and data.max then
        return math.Rand(data.min, data.max)
    end

    return data
end
