local Transmog = _G.Transmog

-- XorWoW: the character window keeps the equipped item's own icon (the client would show the
-- transmog's, read from the visible-item fields) and names the transmog in the item tooltip.

local lastStatusRequest = 0

-- Returns the equipped item's own id and icon; the link always describes the real item.
local function EquippedItem(slot)
    local link = GetInventoryItemLink("player", slot)
    if not link then
        return nil
    end
    local itemId = tonumber(string.match(link, "item:(%d+)"))
    local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(link)
    return itemId, icon
end

-- Returns the appearance the slot is shown with, or nil when it shows the item itself.
local function SlotAppearance(slot)
    local itemId, icon = EquippedItem(slot)
    if not itemId then
        return nil
    end

    local fakeId = Transmog.transmogStatusFromServer[slot]
    if fakeId == Transmog.HIDDEN_ITEM_ID then
        return fakeId
    end

    local shownIcon = GetInventoryItemTexture("player", slot)
    if fakeId and fakeId ~= 0 then
        -- The server ignores a stored look the current item cannot wear; the shown icon tells.
        local _, _, _, _, _, _, _, _, _, fakeIcon = GetItemInfo(fakeId)
        if not fakeIcon then
            Transmog:cacheItem(fakeId)
        end
        if fakeIcon == nil or shownIcon == fakeIcon then
            return fakeId
        end
        return nil
    end

    -- Transmogged through the Warpweaver's gossip menu since the last status: ask again.
    if shownIcon and icon and shownIcon ~= icon and GetTime() - lastStatusRequest > 5 then
        lastStatusRequest = GetTime()
        Transmog:aSend("GetTransmogStatus")
    end
    return nil
end

hooksecurefunc("PaperDollItemSlotButton_Update", function(self)
    local _, icon = EquippedItem(self:GetID())
    if icon then
        SetItemButtonTexture(self, icon)
    end
end)

hooksecurefunc(GameTooltip, "SetInventoryItem", function(self, unit, slot)
    if unit ~= "player" or not slot then
        return
    end

    local fakeId = SlotAppearance(slot)
    if not fakeId then
        return
    end

    local name
    if fakeId == Transmog.HIDDEN_ITEM_ID then
        name = "(Hidden)"
    else
        local fakeName, _, quality = GetItemInfo(fakeId)
        if not fakeName then
            return
        end
        local _, _, _, color = GetItemQualityColor(quality)
        name = color .. fakeName .. "|r"
    end

    self:AddLine("|cfff471f5Transmogrified to:|r " .. name)
    self:Show()
end)
