local name, addon = ...
local broker = addon:NewModule("DataBroker")

-- localise global variables
local _G = _G
local ICON_ABILITY_TRACKING = 132328

function broker:OnInitialize()
    self.type = "data source"

    LibStub("LibDataBroker-1.1"):NewDataObject(name, self)
end

function broker:OnEnable()
    addon:Subscribe("TRACKING_CHANGED", self, "OnTrackingChanged")
    self:OnTrackingChanged()
end

function broker:OnDisable()
    addon:Unsubscribe("TRACKING_CHANGED", self, "OnTrackingChanged")
end

function broker:OnTrackingChanged()
    local spellId = TrackingApi:GetActiveTrackingId()

    if not spellId then
        self:SetValue("Not Tracking", ICON_ABILITY_TRACKING)
    else
        name, icon, active = TrackingApi:GetTrackingInfo(spellId)

        local mapId = addon:GetZoneId()

        if PersistentStorage["autoTracking"][mapId] == spellId then
            textColor = "|cFF75FF75"
        else
            textColor = "|cFFFFFFFF"
        end

        self:SetValue(textColor..name, icon)
    end
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
