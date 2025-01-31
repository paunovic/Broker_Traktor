local name, addon = ...
local tooltip = addon:NewModule("Tooltip")

-- localise global variables
local _G = _G
local MINIMAP_TRACKING_NONE = _G.MINIMAP_TRACKING_NONE

local LibQTip = LibStub("LibQTip-1.0")

function tooltip:OnEnable()
    addon:Subscribe("MOUSE_ENTER", self, "Show")
    addon:Subscribe("TRACKING_CHANGED", self, "OnTrackingChanged")
    addon:Subscribe("ZONE_CHANGED_NEW_AREA", self, "OnZoneChangedNewArea")
end

function tooltip:OnDisable()
    self:Hide()
    addon:Unsubscribe("ZONE_CHANGED_NEW_AREA", self, "OnZoneChangedNewArea")
    addon:Unsubscribe("MOUSE_ENTER", self, "Show")
    addon:Unsubscribe("TRACKING_CHANGED", self, "OnTrackingChanged")
end

function tooltip:Redraw()
    self.tip:Clear()
    self:Populate()
end

function tooltip:OnTrackingChanged()
    if self.tip then
        self:Redraw()
    end
end

function tooltip:OnZoneChangedNewArea()
    if self.tip then
        self:Redraw()
    end
end

function tooltip:Show(anchor)
    self:Hide()

    if self.enabledState then
        self.tip = LibQTip:Acquire(name .. "Tooltip", 3, "LEFT", "LEFT")
        self.tip.OnRelease = function() self.tip = nil end
        self.tip:SetAutoHideDelay(0.1, anchor)
        self.tip:SmartAnchorTo(anchor)
        self:Redraw()
        self.tip:Show()
    end
end

function tooltip:Hide()
    if self.tip then
        LibQTip:Release(self.tip)
    end
end

function tooltip:Populate()
    local trackingId = TrackingApi:GetActiveTrackingId()
    local spells = addon:GetSpells()

    local mapId = C_Map.GetBestMapForUnit("player")

    self:AddLine(0, nil, MINIMAP_TRACKING_NONE, not trackingId, "|cFFFFFFFF")

    local spellId, name, icon, textColor
    for i = 1, #spells do
        spellId, name, icon = unpack(spells[i])
        if PersistentStorage["autoTracking"][mapId] == spellId then
            textColor = "|cFF00FF00"
        else
            textColor = "|cFFFFFFFF"
        end
        self:AddLine(spellId, icon, name, spellId == trackingId, textColor)
    end
end

function tooltip:AddLine(spellId, icon, name, active, textColor)
    local line = self.tip:AddLine()
    local radio = "|T:0|t"

    if active then
        radio = "|TInterface\\Buttons\\UI-RadioButton:8:8:0:0:64:16:19:28:3:12|t"
    end

    self.tip:SetCell(line, 1, radio)
    if icon then
        self.tip:SetCell(line, 2, "|T" .. icon .. ":14|t")
    end
    self.tip:SetCell(line, 3, textColor .. name)
    self.tip:SetLineScript(line, "OnMouseUp", self:GetLineScript(spellId))
    return line
end

function tooltip:GetLineScript(spellId)
    return function()
        if IsShiftKeyDown() then
            local mapId = C_Map.GetBestMapForUnit("player")
            if PersistentStorage["autoTracking"][mapId] ~= nil then
                if PersistentStorage["autoTracking"][mapId] == spellId then
                    PersistentStorage["autoTracking"][mapId] = nil
                else
                    PersistentStorage["autoTracking"][mapId] = spellId
                end
            else
                PersistentStorage["autoTracking"][mapId] = spellId
            end
            self:Redraw()
        end
        addon:SetTracking(spellId)
    end
end
