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
    addon:Subscribe("RELOAD_INTERFACE", self, "ReloadInterface")
    addon:Subscribe("REDRAW_INTERFACE", self, "RedrawInterface")
end

function broker:OnDisable()
    addon:Unsubscribe("REDRAW_INTERFACE", self, "RedrawInterface")
    addon:Unsubscribe("RELOAD_INTERFACE", self, "ReloadInterface")
    addon:Unsubscribe("TRACKING_CHANGED", self, "OnTrackingChanged")
end

function broker:OnTrackingChanged()
    local textColor = "|cFFFFFFFF" -- white
    if (
        addon.activeTrackingId
        and (
            addon.activeTrackingId == addon.alternateTrackingIds.primary
            or addon.activeTrackingId == addon.alternateTrackingIds.secondary
        )
    ) then
        textColor = "|cFFFFFF00" -- yellow
    elseif addon:IsSmartTracking(addon.activeTrackingId) then
        textColor = "|cFF75FF75" -- green
    end

    if not addon.activeTrackingId or addon.activeTrackingId == 0 then
        self:SetValue(textColor.."Not Tracking", ICON_ABILITY_TRACKING)
    else
        local spellName, spellIcon, _ = TrackingApi:GetTrackingInfo(addon.activeTrackingId)
        self:SetValue(textColor..spellName, spellIcon)
    end
end

function broker:RedrawInterface()
    self:OnTrackingChanged()
end

function broker:ReloadInterface()
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
