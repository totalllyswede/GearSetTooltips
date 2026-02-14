-- ItemSetTooltip: Shows which ItemRack/Outfitter sets an item belongs to

ItemSetTooltip = {}

-- Cache of set item IDs for performance
ItemSetTooltip.SetItems = {}

-- Initialization flag
ItemSetTooltip.Initialized = false

-- Initialize addon
function ItemSetTooltip:Initialize()
    -- Wait for ItemRack or Outfitter to load
    self:RegisterEvents()
end

-- Register events
function ItemSetTooltip:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    
    frame:SetScript("OnEvent", function()
        if not ItemSetTooltip.Initialized then
            if IsAddOnLoaded("ItemRack") or IsAddOnLoaded("Outfitter") then
                ItemSetTooltip:OnAddonsLoaded()
            end
        end
    end)
end

function ItemSetTooltip:OnAddonsLoaded()
    -- Prevent multiple initializations
    if self.Initialized then
        return
    end
    self.Initialized = true
    
    -- Update set items cache
    self:UpdateSetItems()
    
    -- Hook ItemRack functions to update cache
    if ItemRack and ItemRack.SaveSet then
        self:HookFunction(ItemRack, "SaveSet")
    end
    if ItemRack and ItemRack.DeleteSet then
        self:HookFunction(ItemRack, "DeleteSet")
    end
    
    -- Hook tooltips
    self:HookTooltips()
    
    -- Delay the load message to ensure chat frame is ready
    local msgFrame = CreateFrame("Frame")
    local elapsed = 0
    msgFrame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= 0.5 then
            local msg = "ItemSetTooltip loaded"
            if IsAddOnLoaded("ItemRack") and IsAddOnLoaded("Outfitter") then
                msg = msg .. " - Tracking ItemRack and Outfitter sets"
            elseif IsAddOnLoaded("ItemRack") then
                msg = msg .. " - Tracking ItemRack sets"
            elseif IsAddOnLoaded("Outfitter") then
                msg = msg .. " - Tracking Outfitter sets"
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. msg .. "|r")
            msgFrame:SetScript("OnUpdate", nil)
        end
    end)
    
    -- Schedule a delayed update
    self:ScheduleUpdate(2)
end

-- Simple function hooking
function ItemSetTooltip:HookFunction(table, funcName)
    if not table or not table[funcName] then return end
    
    local original = table[funcName]
    table[funcName] = function(...)
        local result = original(unpack(arg))
        ItemSetTooltip:UpdateSetItems()
        return result
    end
end

-- Schedule a delayed update
function ItemSetTooltip:ScheduleUpdate(delay)
    local frame = CreateFrame("Frame")
    local elapsed = 0
    
    frame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= delay then
            ItemSetTooltip:UpdateSetItems()
            frame:SetScript("OnUpdate", nil)
        end
    end)
end

-- Build cache of all items in ItemRack and Outfitter sets
function ItemSetTooltip:UpdateSetItems()
    local success, errorMsg = pcall(function()
        local oldCount = 0
        for _ in pairs(ItemSetTooltip.SetItems) do
            oldCount = oldCount + 1
        end
        
        ItemSetTooltip.SetItems = {}
        
        local count = 0
        
        -- Read ItemRack sets
        if IsAddOnLoaded("ItemRack") then
            local userData = Rack_User or ItemRack_Users
            
            if userData then
                local user = UnitName("player") .. " of " .. GetCVar("realmName")
                
                if userData[user] and userData[user].Sets then
                    for setName, setData in pairs(userData[user].Sets) do
                        if not string.find(setName, "^ItemRack%-") and not string.find(setName, "^Rack%-") then
                            for slot = 0, 19 do
                                local itemData = setData[slot]
                                if itemData and type(itemData) == "table" then
                                    local itemID = itemData.id
                                    
                                    if itemID and itemID ~= 0 then
                                        if type(itemID) == "string" then
                                            local _, _, extractedID = string.find(itemID, "^(%d+)")
                                            itemID = tonumber(extractedID)
                                        end
                                        
                                        if itemID and itemID > 0 then
                                            if not ItemSetTooltip.SetItems[itemID] then
                                                count = count + 1
                                            end
                                            ItemSetTooltip.SetItems[itemID] = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Read Outfitter sets
        if IsAddOnLoaded("Outfitter") and gOutfitter_Settings and gOutfitter_Settings.Outfits then
            for cat, outfits in pairs(gOutfitter_Settings.Outfits) do
                if table.getn(outfits) > 0 then
                    for _, outfit in ipairs(outfits) do
                        if outfit.Items then
                            for slot, item in pairs(outfit.Items) do
                                local itemID = tonumber(item.Code)
                                
                                if itemID and itemID > 0 then
                                    if not ItemSetTooltip.SetItems[itemID] then
                                        count = count + 1
                                    end
                                    ItemSetTooltip.SetItems[itemID] = true
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Show message if count changed
        if count ~= oldCount then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Item Set Change Detected - Tooltips Updated|r")
        end
    end)
    
    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000ItemSetTooltip: Error updating cache - " .. tostring(errorMsg) .. "|r")
    end
end

-- Get which sets an item belongs to (from both ItemRack and Outfitter)
function ItemSetTooltip:GetItemSets(itemID)
    if not itemID then return nil end
    
    -- Only process if item is in our cache
    if not self.SetItems[itemID] then return nil end
    
    local sets = {}
    
    -- Check ItemRack sets
    if IsAddOnLoaded("ItemRack") then
        local userData = Rack_User or ItemRack_Users
        
        if userData then
            local user = UnitName("player") .. " of " .. GetCVar("realmName")
            
            if userData[user] and userData[user].Sets then
                for setName, setData in pairs(userData[user].Sets) do
                    if not string.find(setName, "^ItemRack%-") and not string.find(setName, "^Rack%-") then
                        for slot = 0, 19 do
                            local itemData = setData[slot]
                            if itemData and type(itemData) == "table" then
                                local slotItemID = itemData.id
                                
                                if slotItemID and slotItemID ~= 0 then
                                    if type(slotItemID) == "string" then
                                        local _, _, extractedID = string.find(slotItemID, "^(%d+)")
                                        slotItemID = tonumber(extractedID)
                                    end
                                    
                                    if slotItemID and slotItemID == itemID then
                                        table.insert(sets, setName)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Check Outfitter sets
    if IsAddOnLoaded("Outfitter") and gOutfitter_Settings and gOutfitter_Settings.Outfits then
        for cat, outfits in pairs(gOutfitter_Settings.Outfits) do
            if table.getn(outfits) > 0 then
                for _, outfit in ipairs(outfits) do
                    if outfit.Items and outfit.Name then
                        for slot, item in pairs(outfit.Items) do
                            local outfitItemID = tonumber(item.Code)
                            
                            if outfitItemID and outfitItemID == itemID then
                                table.insert(sets, outfit.Name)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    
    if table.getn(sets) > 0 then
        return sets
    else
        return nil
    end
end

-- Hook all tooltip events
function ItemSetTooltip:HookTooltips()
    -- Store a reference to the last item we added info for to prevent duplicates
    self.lastItemProcessed = nil
    
    -- Hook GameTooltip SetBagItem for bag items only
    local orig_SetBagItem = GameTooltip.SetBagItem
    GameTooltip.SetBagItem = function(this, bag, slot)
        orig_SetBagItem(this, bag, slot)
        local itemLink = GetContainerItemLink(bag, slot)
        if itemLink then
            ItemSetTooltip:AddSetsToTooltip(this, itemLink)
        end
    end
    
    -- Hook OnHide to clear the last processed item
    local orig_OnHide = GameTooltip:GetScript("OnHide")
    GameTooltip:SetScript("OnHide", function()
        if orig_OnHide then
            orig_OnHide()
        end
        ItemSetTooltip.lastItemProcessed = nil
    end)
end

-- Add set information directly to the game tooltip
function ItemSetTooltip:AddSetsToTooltip(tooltip, itemLink)
    if not itemLink then
        return
    end
    
    -- Prevent adding the same item multiple times
    if self.lastItemProcessed == itemLink then
        return
    end
    self.lastItemProcessed = itemLink
    
    local _, _, itemID = string.find(itemLink, "item:(%d+)")
    itemID = tonumber(itemID)
    
    if not itemID then
        return
    end
    
    local sets = self:GetItemSets(itemID)
    if sets then
        -- Limit to 5 sets
        local totalSets = table.getn(sets)
        local displayCount = math.min(5, totalSets)
        
        -- Build the set names string
        local setString = ""
        for i = 1, displayCount do
            if i > 1 then
                setString = setString .. ", "
            end
            setString = setString .. sets[i]
        end
        
        -- If there are more than 5, add count
        if totalSets > 5 then
            setString = setString .. " (+" .. (totalSets - 5) .. " more)"
        end
        
        -- Add the line in blue text (RGB: 0.5, 0.5, 1.0 for a nice blue)
        tooltip:AddLine("Sets: " .. setString, 0.5, 0.5, 1.0)
    end
end

-- Slash commands
SLASH_ITEMSETTOOLTIP1 = "/itemsettooltip"
SLASH_ITEMSETTOOLTIP2 = "/ist"
SlashCmdList["ITEMSETTOOLTIP"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "update" or msg == "refresh" then
        ItemSetTooltip:UpdateSetItems()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00ItemSetTooltip commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("/ist update - Refresh set items cache")
    end
end

-- Initialize on load
ItemSetTooltip:Initialize()
