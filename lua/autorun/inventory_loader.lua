BCORE.Inventory = BCORE.Inventory or {}
BCORE.Inventory.Modifiers =  BCORE.Inventory.Modifiers  or {}
BCORE.Inventory.Suits = BCORE.Inventory.Suits or {}

if BCORE then
    BCORE:LoadAddon("beep_inventory",{"sv_item.lua"},"[BEEPS][Inventory]")
else
    error("BCORE is not installed! Be sure to install BCORE first!")
end
