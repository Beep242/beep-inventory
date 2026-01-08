for i = 1, 45 do
    BUi:CreateFont("BCORE.Inventory." .. i, "Montserrat", i, 500)
    BUi:CreateFont("BCORE.Inventorys." .. i, "Montserrat", i, 600)
    BUi:CreateFont("BCORE.Inventoryb." .. i, "Montserrat", i, 1024)
end

local allPlayers = {}
local filteredPlayers = {}
local currentplayer = nil

local logs = {}

local currentinventory = {}
local itemTypes = {}

local currentMenu = nil

BCORE.netstream.Hook("BCORE.Inventory.Admin.SendPlayers", function(receivedPlayers)
    allPlayers = receivedPlayers or {}
    filteredPlayers = allPlayers
    BCORE.Inventory:BuildPlayerPanels(filteredPlayers)
end)

BCORE.netstream.Hook("BCORE.Inventory.Admin.SendAdminLogs", function(adminLogs)
    print("[InventoryAdmin] Received admin logs from server.")
    adminlogs = adminLogs or {}
    filteredAdminLogs = adminlogs
    BCORE.Inventory:AdminLogs(filteredAdminLogs)
end)

BCORE.netstream.Hook("BCORE.Inventory.Admin.SendAdminActionLogs", function(actionLogs)
    actionlogs = actionLogs or {}
    filteredActionLogs = actionlogs
    print("[InventoryAdmin] Received admin action logs from server.")
    BCORE.Inventory:AdminActionLogs(filteredActionLogs)
end)

BCORE.netstream.Hook("BCORE.Inventory.Admin.SendPlayerInventory", function(receivedInventory)
    currentinventory = receivedInventory or {}
    if IsValid(BCORE.Inventory.playerinv) then
        BCORE.Inventory.playerinv:Load(currentinventory)
    end
end)

BCORE.netstream.Hook("BCORE.Inventory.Admin.SendItemTypes", function(a, b)
    local receivedItemTypes = b
    if type(a) == "table" and b == nil then receivedItemTypes = a end
    itemTypes = receivedItemTypes or {}
    local keys = {}
    for k, _ in pairs(itemTypes) do table.insert(keys, k) end
    print("[InventoryAdmin] Received item types from server.")
    print("[InventoryAdmin] Available item types: " .. table.concat(keys, ", "))
end)

function BCORE.Inventory:AdminSetCurrentPlayer(steamid)
    currentplayer = steamid
end

function BCORE.Inventory:AdminGetCurrentPlayer()
    return currentplayer
end

function BCORE.Inventory:AdminGetPlayers()
    BCORE.netstream.Start("BCORE.Inventory.Admin.RequestPlayers")
end

function BCORE.Inventory:AdminGetAdminlogs()
    print("[InventoryAdmin] Requesting admin logs from server.")
    BCORE.netstream.Start("BCORE.Inventory.Admin.RequestAdminLogs")
end

function BCORE.Inventory:AdminGetAdminActionLogs()
    BCORE.netstream.Start("BCORE.Inventory.Admin.RequestAdminActionLogs")
end

local function FilterTable(searchText, tbl)
    local filtered = {}
    searchText = (searchText or ""):lower()
    local visited = {}

    local function toSearchableString(v)
        local t = type(v)

        if t == "string" or t == "number" or t == "boolean" then
            return tostring(v)
        elseif t == "function" then
            local info = debug.getinfo(v, "n")
            return info and info.name or "[function]"
        elseif t == "userdata" then
            return tostring(v)
        elseif t == "table" then
            if visited[v] then return "" end
            visited[v] = true

            for _, key in ipairs({"Nick", "GetName", "Name"}) do
                if type(v[key]) == "function" then
                    local ok, res = pcall(v[key], v)
                    if ok and type(res) == "string" then
                        return res
                    end
                end
            end
            for _, key in ipairs({"nick", "name"}) do
                if v[key] then
                    return tostring(v[key])
                end
            end

            local str = ""
            for k, val in pairs(v) do
                str = str .. " " .. toSearchableString(k)
                str = str .. " " .. toSearchableString(val)
            end
            return str
        else
            return tostring(v)
        end
    end

    for _, v in ipairs(tbl or {}) do
        local str = toSearchableString(v):lower()
        if str:find(searchText, 1, true) then
            table.insert(filtered, v)
        end
    end

    return filtered
end




function BCORE.Inventory:OpenAdmin()
    if IsValid(BCORE.Inventory.frame) then
        BCORE.Inventory.frame:Remove()
    end
    BCORE.Inventory:AdminGetPlayers()

    BCORE.Inventory.frame = BUi.Create("EditablePanel")
    BCORE.Inventory.frame:FadeIn(.5)
    BCORE.Inventory.frame:SetSize(BUi:Scale(800), BUi:Scale(850))
    BCORE.Inventory.frame:Center()
    BCORE.Inventory.frame:MakePopup()
    BCORE.Inventory.frame:ClearPaint():Shadow(255):Background(BCORE.Inventory.colors.light, 16)
    BCORE.Inventory.frame:On("Paint", function(s, w, h)
        draw.RoundedBox(16, 1, 1, w - 2, h - 2, BCORE.Inventory.colors.bg)
    end)
    BCORE.Inventory.frame:DockPadding(10, 10, 10, 10)

    function BCORE.Inventory.frame:OnKeyCodePressed(key)
        if BCORE.Inventory.frame:IsVisible() and key == KEY_Inventory then
            BCORE.Inventory.frame:AlphaTo(0, 0.2)
            timer.Simple(0.2, function()
                if IsValid(BCORE.Inventory.frame) then
                    BCORE.Inventory.frame:SetVisible(false)
                end
            end)
        end
    end

    BCORE.Inventory.topbar = BUi.Create("DPanel", BCORE.Inventory.frame)
    BCORE.Inventory.topbar:Stick(TOP, nil, nil, nil, nil, 10)
    BCORE.Inventory.topbar:SetTall(BCORE.Inventory.frame:GetTall() * .08)
    BCORE.Inventory.topbar:ClearPaint():Background(BCORE.Inventory.colors.light, 14):On("Paint", function(s, w, h)
        draw.RoundedBox(14, 1, 1, w - 2, h - 2, BCORE.Inventory.colors.sec)
    end)

    local exit = BUi.Create("DButton", BCORE.Inventory.topbar)
    exit:Stick(RIGHT)
    exit:DockMargin(10, 10, 10, 10)
    exit:SetWide(50)
    exit:SetText("")
    exit:BUi():ClearPaint():Background(Color(56, 56, 56,200), 5):FadeIn(0.5):On("Paint", function(s, w, h)
        draw.RoundedBox(5, 1, 1, w - 2, h - 2,  BCORE.Inventory.colors.accent)
        BUi.DrawImgur(0,0,w,h, "https://invisibalfan-ui.github.io/bui_images/images/0cjxwbc.png",color_white)
    end):FadeHover(Color(100,0,0,90),6,8)
    exit:On("DoClick", function() if IsValid(BCORE.Inventory.frame) then BCORE.Inventory.frame:Remove() end end)

    BCORE.Inventory.actionlogs = BUi.Create("DButton", BCORE.Inventory.topbar)
    BCORE.Inventory.actionlogs:Stick(RIGHT, 10)
    BCORE.Inventory.actionlogs:SetWide(BCORE.Inventory.topbar:GetTall() * 2)
    BCORE.Inventory.actionlogs:SetText("")
    BCORE.Inventory.actionlogs:FadeHover(Color(BCORE.Inventory.colors.light.r, BCORE.Inventory.colors.light.g, BCORE.Inventory.colors.light.b, 90),6,8)
    BCORE.Inventory.actionlogs:On("DoClick", function(s)
        BCORE.Inventory:AdminGetAdminActionLogs()
    end)
    BCORE.Inventory.actionlogs:ClearPaint():Background(BCORE.Inventory.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, BCORE.Inventory.colors.sec)
        draw.SimpleText("Action Logs", "BCORE.Inventorys.24", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)

    BCORE.Inventory.Adminlogs = BUi.Create("DButton", BCORE.Inventory.topbar)
    BCORE.Inventory.Adminlogs:Stick(RIGHT, 10)
    BCORE.Inventory.Adminlogs:SetWide(BCORE.Inventory.topbar:GetTall() * 2)
    BCORE.Inventory.Adminlogs:SetText("")
    BCORE.Inventory.Adminlogs:FadeHover(Color(BCORE.Inventory.colors.light.r, BCORE.Inventory.colors.light.g, BCORE.Inventory.colors.light.b, 90),6,8)
    BCORE.Inventory.Adminlogs:ClearPaint():Background(BCORE.Inventory.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, BCORE.Inventory.colors.sec)
        draw.SimpleText("Admin Logs", "BCORE.Inventorys.24", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)
    BCORE.Inventory.Adminlogs:On("DoClick", function(s)
        BCORE.Inventory:AdminGetAdminlogs()
    end)

    local searchhold = BUi.Create("DPanel", BCORE.Inventory.topbar)
    searchhold:Stick(LEFT, 14)
    searchhold:SetWide( BCORE.Inventory.topbar:GetWide() * .28)
    searchhold:ClearPaint():Background(BCORE.Inventory.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, BCORE.Inventory.colors.accent)
        BUi.DrawImgur(h * .15, h * .15, h * .7, h * .7, "https://invisibalfan-ui.github.io/bui_images/images/mkp8lur.png", color_white)
    end)
    searchhold:DockPadding(40, 0, 0, 0)

    BCORE.Inventory.search = BUi.Create("DTextEntry", searchhold)
    BCORE.Inventory.search:Stick(FILL)
    BCORE.Inventory.search:ReadyTextbox()
    BCORE.Inventory.search:SetPlaceholderText("SteamID/Name...")
    BCORE.Inventory.search:SetFont("BCORE.Inventoryb.22")
    BCORE.Inventory.search:SetTextColor(BCORE.Inventory.colors.cwhite)
    BCORE.Inventory.search:SetCursorColor(BCORE.Inventory.colors.cwhite)

    BCORE.Inventory.search.OnChange = function()

    local text = BCORE.Inventory.search:GetText():lower()
        filteredPlayers = FilterTable(text, allPlayers)
        BCORE.Inventory:BuildPlayerPanels(filteredPlayers)
    end

    BCORE.Inventory.GridHolder = BUi.Create("BUi.Scroll", BCORE.Inventory.frame)
    BCORE.Inventory.GridHolder:Stick(FILL, 0, 10, 0, 10)
end

function BCORE.Inventory:BuildPlayerPanels(playerList)
    if not IsValid(self.GridHolder) then return end
    self.GridHolder:Clear()

    for _, steamid in ipairs(playerList) do
        local ply = player.GetBySteamID64(steamid)

        local panel = BUi.Create("DPanel", self.GridHolder)
        panel:Stick(TOP, 0, 0, 0, 0, 10)
        panel:SetTall(BUi:Scale(60))
        panel:ClearPaint():Background(self.colors.light, 8):On("Paint", function(s, w, h)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colors.sec)
            draw.SimpleText(ply and ply:Nick():gsub("^%l", string.upper) or steamid, "BCORE.Inventorys.24", h * 0.9, h / 3, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(ply and "Online" or "Offline", "BCORE.Inventorys.22", h * 0.96, h / 1.5, ply and Color(0,255,0) or Color(255,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end)

        local avatar = BUi.Create("AvatarMaterial", panel)
        avatar:Stick(LEFT, 10)
        avatar:SetWide(avatar:GetTall()) 
        avatar:CircleAvatar()
        avatar:SetSteamID64(steamid)

        local openInvBtn = BUi.Create("DButton", panel)
        openInvBtn:Stick(RIGHT, 10)
        openInvBtn:SetWide(panel:GetTall() * 3)
        openInvBtn:Text("")
        openInvBtn:ClearPaint():Background(self.colors.light, 8):On("Paint", function(s, w, h)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colors.sec)
            draw.SimpleText("View Inventory", "BCORE.Inventorys.24", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end)
        openInvBtn:FadeHover(Color(BCORE.Inventory.colors.light.r, BCORE.Inventory.colors.light.g, BCORE.Inventory.colors.light.b, 90),6,8)
        openInvBtn.DoClick = function()
            BCORE.Inventory:OpenPlayerInventory(steamid)
            BCORE.Inventory:AdminSetCurrentPlayer(steamid)
            BCORE.Inventory.actionlogs:SetVisible(false)
            BCORE.Inventory.Adminlogs:SetVisible(false)
        end
    end
end

local function OverrideRightClick(panels)
    for i = 1, BCORE.Inventory.config.MaxSlots do
        local panel = panels[i]
        local itemPanel = panel and panel.itemPanel

        if panel.HasItem and IsValid(itemPanel) and IsValid(itemPanel.ModelPanel) then
            itemPanel.ModelPanel.DoRightClick = function()
                if IsValid(currentMenu) then
                    currentMenu:Close()
                end

                local menu = BUi.Create("BUi.DMenu", itemPanel.ModelPanel)
                currentMenu = menu  
                menu:SetSize(110)

                menu:AddOption("Duplicate", function() 
                    local targetSteamID = BCORE.Inventory:AdminGetCurrentPlayer()
                    if targetSteamID then
                        BCORE.netstream.Start("BCORE.Inventory.Admin.RequestAction", targetSteamID, "duplicate", itemPanel.Item.id, itemPanel.Item)
                        BCORE.Inventory.playerinv:Load(currentinventory)
                        OverrideRightClick(BCORE.Inventory.playerinv.slotPanels)
                    end
                end)

                menu:AddOption("Delete", function() 
                    local targetSteamID = BCORE.Inventory:AdminGetCurrentPlayer()
                    if targetSteamID then
                        BCORE.netstream.Start("BCORE.Inventory.Admin.RequestAction", targetSteamID, "delete", itemPanel.Item.id, itemPanel.Item)
                        BCORE.Inventory.playerinv:Load(currentinventory)
                        OverrideRightClick(BCORE.Inventory.playerinv.slotPanels)
                    end
                end)

                menu:AddOption("Edit", function() 
                    BCORE.Inventory:AdminEditItem(itemPanel.Item)
                end)

                menu:Open()
            end
        end
    end
end

function BCORE.Inventory:AdminEditItem(itemData)
    local targetSteamID = BCORE.Inventory:AdminGetCurrentPlayer()
    if not targetSteamID then
        return
    end

    local frame = BUi.Create("EditablePanel")
    frame:SetSize(BUi:Scale(400), BUi:Scale(500))
    frame:Center()
    frame:FadeIn(.5)
    frame:MakePopup()
    frame:ClearPaint():Shadow(50):Background(BCORE.Inventory.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colors.bg)
    end)

    local topbar = BUi.Create("EditablePanel", frame)
    topbar:Stick(TOP, nil, 10, 10, 10, 10)
    topbar:SetTall(frame:GetTall() * .1)
    topbar:ClearPaint():Background(BCORE.Inventory.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, BCORE.Inventory.colors.sec)
        draw.SimpleText("Edit Item " .. BUi.Truncate(itemData.name,10), "BCORE.Inventorys.24", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end)

    local exit = BUi.Create("DButton",topbar)
    exit:Stick(RIGHT)
    exit:DockMargin(5,5, 5, 5)
    exit:SetWide(40)
    exit:SetText("")
    exit:BUi():ClearPaint():Background(Color(56, 56, 56,200), 5):FadeIn(0.5):On("Paint", function(s, w, h)
        draw.RoundedBox(5, 1, 1, w - 2, h - 2,  BCORE.Inventory.colors.accent)
        BUi.DrawImgur(0,0,w,h, "https://invisibalfan-ui.github.io/bui_images/images/0cjxwbc.png",color_white)
    end):FadeHover(Color(100,0,0,90),6,8)
    exit:On("DoClick", function() frame:Remove() end)

    local scroll = BUi.Create("BUi.Scroll", frame)
    scroll:Stick(FILL,0,10,0,10,10)

    local entries = {}

    for key, value in pairs(itemData.customData or {}) do
        local label = BUi.Create("DLabel", scroll)
        label:SetText(key)
        label:SetFont("BCORE.Inventoryb.22")
        label:SetTextColor(color_white)
        label:Dock(TOP)
        label:DockMargin(0, 10, 0, 0)

        local searchhold = BUi.Create("DPanel", scroll)
        searchhold:Stick(TOP)
        searchhold:SetTall(frame:GetTall() * .08)
        searchhold:ClearPaint():Background(BCORE.Inventory.colors.light, 8):On("Paint", function(s, w, h)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, BCORE.Inventory.colors.accent)
            BUi.DrawImgur(h * .15, h * .15, h * .7, h * .7, "https://invisibalfan-ui.github.io/bui_images/images/mkp8lur.png", color_white)
        end)

        local entry = BUi.Create("DTextEntry", searchhold)
        entry:Stick(FILL,nil,40)
        entry:ReadyTextbox()
        entry:SetTall(30)
        entry:SetText(tostring(value or ""))
        entry:SetFont("BCORE.Inventoryb.22")
        entry:SetTextColor(BCORE.Inventory.colors.cwhite)
        entry:SetCursorColor(BCORE.Inventory.colors.cwhite)
        entry:SetPlaceholderText("Enter " .. key .. " value...")

        entries[key] = entry
    end

    local saveBtn = BUi.Create("DButton", frame)
    saveBtn:SetSize(460, 40)
    saveBtn:Stick(BOTTOM,nil,10,nil,10,10)
    saveBtn:SetText("")
    saveBtn:ClearPaint():Shadow(50):Background(BCORE.Inventory.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colors.bg)
        draw.SimpleText("Save Changes", "BCORE.Inventorys.24", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end):FadeHover(Color(7,80,12,90),6,8)
    
    saveBtn.DoClick = function()
        local updatedCustomData = {}
        for key, entry in pairs(entries) do
            local val = entry:GetValue()
            if val:match("^-?%d*%.?%d+$") then
                updatedCustomData[key] = tonumber(val)
            else
                updatedCustomData[key] = val
            end
        end

        local updatedData = table.Copy(itemData)
        updatedData.customData = updatedCustomData

        BCORE.netstream.Start("BCORE.Inventory.Admin.RequestAction", targetSteamID, "edit", itemData.id, updatedData)
        frame:Remove()
        if IsValid(BCORE.Inventory.playerinv) then
            BCORE.Inventory.playerinv:Load(currentinventory)
            OverrideRightClick(BCORE.Inventory.playerinv.slotPanels)
        end
    end
end

function BCORE.Inventory:RenderLogs(logs)
    if not IsValid(self.GridHolder) then return end
    if IsValid(BCORE.Inventory.back) then BCORE.Inventory.back:Remove() end
    BCORE.Inventory.back = BUi.Create("DButton", BCORE.Inventory.topbar)
    BCORE.Inventory.back:Stick(RIGHT, 10)
    BCORE.Inventory.back:SetWide(BCORE.Inventory.topbar:GetTall() * 2)
    BCORE.Inventory.back:SetText("")
    BCORE.Inventory.back:FadeHover(Color(BCORE.Inventory.colors.light.r, BCORE.Inventory.colors.light.g, BCORE.Inventory.colors.light.b, 90),6,8)
    BCORE.Inventory.back:On("DoClick", function(s)
        BCORE.Inventory:OpenAdmin()
        BCORE.Inventory:BuildPlayerPanels(filteredPlayers)
    end)
    BCORE.Inventory.back:ClearPaint():Background(self.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colors.sec)
        draw.SimpleText("Back", "BCORE.Inventorys.24", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)

    for _, log in ipairs(logs or {}) do
        local ply = player.GetBySteamID64(log.steamid64)

        local panel = BUi.Create("DPanel", self.GridHolder)
        panel:Stick(TOP, 0, 0, 0, 0, 10)
        panel:SetTall(BUi:Scale(60))
        panel:ClearPaint():Background(self.colors.light, 8):On("Paint", function(s, w, h)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colors.sec)
            draw.SimpleText(log.admin and log.admin:gsub("^%l", string.upper) or (ply and ply:Nick() or log.steamid64), "BCORE.Inventorys.24", h * 0.9, h / 3, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(string.format("%s -> %s %s",os.date("%Y-%m-%d %H:%M:%S", log.time or os.time()),tostring(log.action or "Unknown"),tostring(log.target or "")), "BCORE.Inventorys.22", h * 0.96, h / 1.5,BCORE.Inventory.colors.cwhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end)

        local avatar = BUi.Create("AvatarMaterial", panel)
        avatar:Stick(LEFT, 10)
        avatar:SetWide(avatar:GetTall()) 
        avatar:CircleAvatar()
        avatar:SetSteamID64(log.target)

        local copyBtn = BUi.Create("DButton", panel)
        copyBtn:Stick(RIGHT, 10)
        copyBtn:SetWide(panel:GetTall() * 3)
        copyBtn:SetText("")
        copyBtn:ClearPaint():Background(self.colors.light, 8):On("Paint", function(s, w, h)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colors.sec)
            draw.SimpleText("Copy Log", "BCORE.Inventorys.24", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end)
        copyBtn:FadeHover(Color(BCORE.Inventory.colors.light.r, BCORE.Inventory.colors.light.g, BCORE.Inventory.colors.light.b, 90),6,8)
        copyBtn.DoClick = function()
            SetClipboardText(string.format("[%s] %s -> %s (%s)",
                os.date("%Y-%m-%d %H:%M:%S", log.time or os.time()),
                tostring(log.admin or "Unknown"),
                tostring(log.action or "Unknown"),
                tostring(log.target or "Unknown")
            ))
        end

    end

end

function BCORE.Inventory:AdminLogs(logs)
    self.GridHolder:Clear()
    logs = logs or adminlogs or {}
    self:RenderLogs(logs)
    BCORE.Inventory.search.OnChange = function()
           self.GridHolder:Clear()
        local text = BCORE.Inventory.search:GetText():lower()
        BCORE.Inventory:RenderLogs(FilterTable(text, logs))
    end
end

function BCORE.Inventory:AdminActionLogs(logs)
    self.GridHolder:Clear()
    logs = logs or actionlogs or {}
    self:RenderLogs(logs)
    BCORE.Inventory.search.OnChange = function()
        self.GridHolder:Clear()
        local text = BCORE.Inventory.search:GetText():lower()
        BCORE.Inventory:RenderLogs(FilterTable(text, logs))
    end
end

function BCORE.Inventory:OpenPlayerInventory(steamid)
    if IsValid(BCORE.Inventory.GridHolder) then BCORE.Inventory.GridHolder:Remove() end
    BCORE.Inventory.playerinv = BUi.Create("[BCORE][UI][INVENTORY_GRID]", BCORE.Inventory.frame)
    BCORE.Inventory.playerinv:Stick(FILL, 0, 10, 0, 10)

    local modifiers = BUi.Create("DButton", BCORE.Inventory.topbar)
    modifiers:Stick(RIGHT, 10)
    modifiers:SetWide(BCORE.Inventory.topbar:GetTall() * 2)
    modifiers:SetText("")
    modifiers.IsModifierMode = false 

    modifiers:FadeHover(Color(BCORE.Inventory.colors.light.r, BCORE.Inventory.colors.light.g, BCORE.Inventory.colors.light.b, 90), 6, 8)

    modifiers:On("DoClick", function(s)
        s.IsModifierMode = not s.IsModifierMode

        local ply = player.GetBySteamID64(steamid)
        local inventory = {}

        if ply then
            if s.IsModifierMode then
                inventory = ply.BCORE_Inventory_Modifiers or {}
            else
                inventory = ply.BCORE_Inventory or {}
            end

            BCORE.Inventory.playerinv:Load(inventory)
            OverrideRightClick(BCORE.Inventory.playerinv.slotPanels)
        else
            BCORE.netstream.Start("BCORE.Inventory.Admin.RequestPlayerInventory", steamid)
        end
    end)

    modifiers:ClearPaint():Background(self.colors.light, 8):On("Paint", function(s, w, h)   
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colors.sec)
        local label = s.IsModifierMode and "Upgrades" or "Modifiers"
        draw.SimpleText(label, "BCORE.Inventorys.24", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)

    local wipe = BUi.Create("DButton", BCORE.Inventory.topbar)
    wipe:Stick(RIGHT, 10)
    wipe:SetWide(BCORE.Inventory.topbar:GetTall() * 2)
    wipe:SetText("")
    wipe:FadeHover(Color(100,0,0,90),6,8)
    wipe:On("DoClick", function(s)
        BCORE.netstream.Start("BCORE.Inventory.Admin.RequestAction",  steamid, "wipe", nil, nil)
        if IsValid(BCORE.Inventory.playerinv) then
            BCORE.Inventory.playerinv:Load(currentinventory)
            OverrideRightClick(BCORE.Inventory.playerinv.slotPanels)
        end
    end)
    wipe:ClearPaint():Background(self.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colors.sec)
        draw.SimpleText("Wipe", "BCORE.Inventorys.24", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)

    local back = BUi.Create("DButton", BCORE.Inventory.topbar)
    back:Stick(RIGHT, 10)
    back:SetWide(BCORE.Inventory.topbar:GetTall() * 2)
    back:SetText("")
    back:FadeHover(Color(BCORE.Inventory.colors.light.r, BCORE.Inventory.colors.light.g, BCORE.Inventory.colors.light.b, 90),6,8)
    back:On("DoClick", function(s)
         BCORE.Inventory:OpenAdmin()
    end)
    back:ClearPaint():Background(self.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colors.sec)
        draw.SimpleText("Back", "BCORE.Inventorys.24", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)

    if player.GetBySteamID64(steamid) then
       BCORE.Inventory.playerinv:Load(player.GetBySteamID64(steamid).BCORE_Inventory or {})
    else
        BCORE.netstream.Start("BCORE.Inventory.Admin.RequestPlayerInventory", steamid)
    end
    OverrideRightClick(BCORE.Inventory.playerinv.slotPanels)
end

function BCORE.Inventory:AdminGetItemTypes()
    BCORE.netstream.Start("BCORE.Inventory.Admin.RequestItemTypes")
end

function BCORE.Inventory:GiveItem(steamid)
    if not IsValid(self.frame) then
        return
    end

    local itemTable = {}
    local itemName = ""

    local giveItemFrame = BUi.Create("EditablePanel")
    giveItemFrame:FadeIn(.5)
    giveItemFrame:SetSize(BUi:Scale(400), BUi:Scale(300))
    giveItemFrame:Center()
    giveItemFrame:MakePopup()
    giveItemFrame:ClearPaint():Shadow(50):Background(BCORE.Inventory.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colors.bg)
    end)

    giveItemFrame:DockPadding(10, 10, 10, 10)

    local topbar = BUi.Create("DPanel", giveItemFrame)
    topbar:Stick(TOP, nil, nil, nil, nil, 10)
    topbar:SetTall(giveItemFrame:GetTall() * .15)
    topbar:ClearPaint():Background(BCORE.Inventory.colors.light, 8):On("Paint", function(s, w, h)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, BCORE.Inventory.colors.sec)
         draw.SimpleText("Give Item to " .. (player.GetBySteamID64(steamid) and BUi.Truncate(player.GetBySteamID64(steamid):Nick(),10) or BUi.Truncate(steamid,10)), "BCORE.Inventorys.24", 10, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end)

    local exit = BUi.Create("DButton",topbar)
    exit:Stick(RIGHT)
    exit:DockMargin(5,5, 5, 5)
    exit:SetWide(40)
    exit:SetText("")
    exit:BUi():ClearPaint():Background(Color(56, 56, 56,200), 5):FadeIn(0.5):On("Paint", function(s, w, h)
        draw.RoundedBox(5, 1, 1, w - 2, h - 2,  BCORE.Inventory.colors.accent)
        BUi.DrawImgur(0,0,w,h, "https://invisibalfan-ui.github.io/bui_images/images/0cjxwbc.png",color_white)
    end):FadeHover(Color(100,0,0,90),6,8)
    exit:On("DoClick", function() giveItemFrame:Remove() end)

    local itemcombo = BUi.Create("BUi.Combo", giveItemFrame)
    itemcombo:Stick(TOP, nil, nil, nil, nil, 10)
    itemcombo:SetTall(giveItemFrame:GetTall() * .15)
    for k, items in pairs(weapons.GetList()) do
        itemcombo:AddChoice(items.PrintName, items)
    end
    itemcombo:Dock(TOP)
    itemcombo:DockMargin(0, 0, 0, 10)
end         

concommand.Add("beep_Inventory_admin_open", function(ply)
    if IsValid(BCORE.Inventory.frame) then
        BCORE.Inventory.frame:Remove()
    else
        BCORE.Inventory:OpenAdmin()
    end
end)
