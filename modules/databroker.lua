local addonName, addon = ...
local broker = addon:NewModule("DataBroker")

local _G = _G
local ICON_ABILITY_TRACKING = 132328

function broker:OnInitialize()
    self.type = "data source"

    LibStub("LibDataBroker-1.1"):NewDataObject(addonName, self)
end

function broker:OnEnable()
    addon:Subscribe("TRACKING_CHANGED", self, "OnTrackingChanged")
    addon:Subscribe("REDRAW_INTERFACE", self, "OnRedrawInterface")
end

function broker:OnDisable()
    addon:Unsubscribe("REDRAW_INTERFACE", self, "OnRedrawInterface")
    addon:Unsubscribe("TRACKING_CHANGED", self, "OnTrackingChanged")
end

function broker:OnTrackingChanged()
    local spellId = TrackingApi:GetActiveTrackingId()
    local zoneText = _G.GetRealZoneText()

    local textColor = "|cFFFFFFFF"
    if PersistentStorage["smartTracking"][zoneText] == spellId then
        textColor = "|cFF75FF75"
    end

    if not spellId or spellId == 0 then
        self:SetValue(textColor.."Not Tracking", ICON_ABILITY_TRACKING)
    else
        local spellName, spellIcon, spellActive = TrackingApi:GetTrackingInfo(spellId)
        self:SetValue(textColor..spellName, spellIcon)
    end
end

function broker:OnRedrawInterface()
    self:OnTrackingChanged()
end

function broker:SetValue(value, icon)
    self.text = value
    self.value = value
    self.icon = icon
end

function broker.OnEnter(frame)
    if broker.enabledState then
        addon:Publish("MOUSE_ENTER", frame)
    end
end

function broker.OnLeave(frame)
    if broker.enabledState then
        addon:Publish("MOUSE_LEAVE", frame)
    end
end

function broker.OnClick(frame, ...)
    if broker.enabledState then
        addon:Publish("MOUSE_CLICK", frame, ...)
    end
end
