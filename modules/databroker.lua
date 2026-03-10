local addonName, addon = ...
local broker = addon:NewModule("TraktorDataBroker")

local _G = _G

function broker:OnEnable()
    self.type = "data source"
    LibStub("LibDataBroker-1.1"):NewDataObject(addonName, self)
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
    local textColor = {r = 1, g = 1, b = 1, a = 1}  -- default color for databroker label is white
    if (
        addon.activeTrackingId
        and (
            addon.activeTrackingId == addon.dualTracking.primaryId
            or addon.activeTrackingId == addon.dualTracking.secondaryId
        )
    ) then
        textColor = BrokerTraktorStorage.colors.dualTracking
    elseif addon:IsAutoTracking(_G.GetRealZoneText(), addon.activeTrackingId) then
        textColor = BrokerTraktorStorage.colors.autoTracking
    end

    if not addon.activeTrackingId or addon.activeTrackingId == 0 then
        self:SetValue(TraktorUtils:ColorToString(textColor).."Not Tracking", nil)
    else
        local spellName, spellIcon, _ = TrackingApi:GetTrackingInfo(addon.activeTrackingId)
        self:SetValue(TraktorUtils:ColorToString(textColor)..spellName, spellIcon)
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

function broker.OnClick(frame, ...)
	if broker.enabledState then
		addon:Publish("MOUSE_CLICK", frame, ...)
	end
end
