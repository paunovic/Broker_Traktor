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
    addon:Subscribe("REDRAW_INTERFACE", self, "Redraw")
end

function tooltip:OnDisable()
    self:Hide()

    addon:Unsubscribe("REDRAW_INTERFACE", self, "Redraw")
    addon:Unsubscribe("ZONE_CHANGED_NEW_AREA", self, "OnZoneChangedNewArea")
    addon:Unsubscribe("MOUSE_ENTER", self, "Show")
    addon:Unsubscribe("TRACKING_CHANGED", self, "OnTrackingChanged")
end

function tooltip:Redraw()
    if self.tip then
        self.tip:Clear()
        self:Populate()
    end
end

function tooltip:OnTrackingChanged()
    self:Redraw()
end

function tooltip:OnZoneChangedNewArea()
    self:Redraw()
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

    local zoneText = GetRealZoneText()

    local textColor = "|cFFFFFFFF"
    if PersistentStorage["smartTracking"][zoneText] == 0 then
        textColor = "|cFF75FF75"
    end
    self:AddLine(0, nil, MINIMAP_TRACKING_NONE, trackingId == 0, textColor)

    local spellId, name, icon, textColor

    for i = 1, #spells do
        spellId, name, icon = unpack(spells[i])
        if PersistentStorage["smartTracking"][zoneText] == spellId then
            textColor = "|cFF75FF75"
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
            local zoneText = GetRealZoneText()

            local spellName = "Not Tracking"
            if spellId and spellId ~= 0 then
                spellName = C_Spell.GetSpellName(spellId)
            end

            if PersistentStorage["smartTracking"][zoneText] ~= nil then
                if PersistentStorage["smartTracking"][zoneText] == spellId then
                    PersistentStorage["smartTracking"][zoneText] = nil
                    print("|cFFFFFFFFTraktor: smart tracking |cFFFF3333off|cFFFFFFFF for |cFFFCBA03"..zoneText)
                    addon:Publish("REDRAW_INTERFACE")
                    return
                else
                    PersistentStorage["smartTracking"][zoneText] = spellId
                    print("|cFFFFFFFFTraktor: smart tracking |cFF00FF00on|cFFFFFFFF for |cFFFCBA03"..zoneText.."|cFFFFFFFF (|cFF75FF75"..spellName.."|cFFFFFFFF)")
                end
            else
                PersistentStorage["smartTracking"][zoneText] = spellId
                print("|cFFFFFFFFTraktor: smart tracking |cFF00FF00on|cFFFFFFFF for |cFFFCBA03"..zoneText.."|cFFFFFFFF (|cFF75FF75"..spellName.."|cFFFFFFFF)")
            end
        end

        addon:SetTracking(spellId)
        addon:Publish("TRACKING_CHANGED")
    end
end
