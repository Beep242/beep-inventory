local PANEL = {}

AccessorFunc(PANEL, "gridSpaceX", "GridSpaceX", FORCE_NUMBER)
AccessorFunc(PANEL, "gridSpaceY", "GridSpaceY", FORCE_NUMBER)
AccessorFunc(PANEL, "gridDock", "GridDock", FORCE_STRING)

function PANEL:Init()
    self.scrollpanel = vgui.Create("BUi.Scroll", self)
    self.inventoryGrid = vgui.Create("DIconLayout", self.scrollpanel)
    self.inventoryGrid:Dock(FILL)

    self:SetGridSpaceX(5)
    self:SetGridSpaceY(5)
    self:SetGridDock(FILL)
    self:BUi():ClearPaint()

    self.slotPanels = self.slotPanels or {}
    self:Load()
end

function PANEL:UpdateGrid()
    self.inventoryGrid:SetSpaceX(self:GetGridSpaceX())
    self.inventoryGrid:SetSpaceY(self:GetGridSpaceY())
    self.scrollpanel:Dock(self:GetGridDock())
end

function PANEL:PerformLayout()
    self:UpdateGrid()
end

function PANEL:Load(inventoryTable)
    self.inventoryGrid:Clear()

    local function SwapItems(slot1, slot2)
        local item1 = slot1:GetChildren()[1]
        local item2 = slot2:GetChildren()[1]

        if item1 then
            item1:SetParent(slot2)
            item1:Dock(FILL)
        end

        if item2 then
            item2:SetParent(slot1)
            item2:Dock(FILL)
        end

        self:SaveItemPositions(inventoryTable)
    end

    for i = 1, BCORE.Inventory.config.MaxSlots do
        local slot = self.inventoryGrid:Add("DPanel")

        slot:SetSize(BUi:Scale(70), BUi:Scale(70))
        slot:BUi():ClearPaint():On("Paint", function(s, width, height)
            draw.RoundedBox(6, 0, 0, width, height, BCORE.Inventory.colors.light)
            draw.RoundedBox(6, 1, 1, width - 2, height - 2, BCORE.Inventory.colors.sec)
        end)

        self.slotPanels[i] = {
            slot = slot,
            HasItem = false
        }

        slot:Receiver("[BCORE][UI][ITEM]", function(receiver, droppedPanels, dropped)
            if dropped then
                if receiver:GetChildren()[1] then
                    SwapItems(receiver, droppedPanels[1]:GetParent())
                else
                    droppedPanels[1]:SetParent(receiver)
                    droppedPanels[1]:Dock(FILL)
                    if droppedPanels[1]:GetItem().itemType == "Modifier" and droppedPanels[1].slotparent != nil then
                        BCORE.netstream.Start("BCORE.Inventory.UnSocket", droppedPanels[1].slotparent.id,droppedPanels[1]:GetItem())
                    end
                    self:SaveItemPositions(inventoryTable)
                end
            end
        end)
    end


    local itemsToLoad = inventoryTable or LocalPlayer().BCORE_Inventory
    for _, itemData in ipairs(itemsToLoad) do
        local slotIndex = itemData.slot
        
    if slotIndex and self.slotPanels[slotIndex] and self.slotPanels[slotIndex].slot then
        local itemPanel = BUi.Create("[BCORE][UI][ITEM_PANEL]", self.slotPanels[slotIndex].slot)
        itemPanel:Dock(FILL)
        itemPanel:SetItem(itemData)
        itemPanel:Text("")
        itemPanel:Droppable("[BCORE][UI][ITEM]")

        self.slotPanels[slotIndex].HasItem = true
        self.slotPanels[slotIndex].itemPanel = itemPanel
    end

    end
end

function PANEL:SaveItemPositions(inventoryTable)
    inventoryTable = inventoryTable or LocalPlayer().BCORE_Inventory
    local inv = inventoryTable or {}


    for index, panel in ipairs(self.slotPanels) do
        local children = panel.slot:GetChildren()
        if children and #children > 0 then
            local item = children[1]
            local data = item:GetItem()

            if data and data.id then

                for _, invItem in ipairs(inv) do
                    if invItem.id == data.id then
                        invItem.slot = index
                        break
                    end
                end
            end
        end
    end

end

vgui.Register("[BCORE][UI][INVENTORY_GRID]", PANEL, "DPanel")
