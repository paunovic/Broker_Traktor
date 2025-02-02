local addonName, addon = ...
local tooltip = addon:NewModule("Tooltip")

local _G = _G

local LibQTip = LibStub("LibQTip-1.0")

function tooltip:OnEnable()
    addon:Subscribe("MOUSE_ENTER", self, "Show")
    addon:Subscribe("TRACKING_CHANGED", self, "RedrawInterface")
    addon:Subscribe("ZONE_CHANGED_NEW_AREA", self, "RedrawInterface")
    addon:Subscribe("RELOAD_INTERFACE", self, "ReloadInterface")
    addon:Subscribe("REDRAW_INTERFACE", self, "RedrawInterface")
end

function tooltip:OnDisable()
    self:Hide()

    addon:Unsubscribe("REDRAW_INTERFACE", self, "RedrawInterface")
    addon:Unsubscribe("RELOAD_INTERFACE", self, "ReloadInterface")
    addon:Unsubscribe("ZONE_CHANGED_NEW_AREA", self, "RedrawInterface")
    addon:Unsubscribe("TRACKING_CHANGED", self, "RedrawInterface")
    addon:Unsubscribe("MOUSE_ENTER", self, "Show")
end

function tooltip:ReloadInterface()
    self:Redraw(true)
end

function tooltip:RedrawInterface()
    self:Redraw(false)
end

function tooltip:Show(anchor)
    self:Hide()

    if self.enabledState then
        self.tip = LibQTip:Acquire(addonName.."Tooltip", 3, "LEFT", "LEFT", "LEFT")
        self.tip.OnRelease = function() self.tip = nil end

        self.tipAnchor = _G.CreateFrame("Frame", anchor)
        self.tipAnchor:SetPoint(anchor:GetPoint())
        self.tipAnchor:SetWidth(anchor:GetWidth())
        self.tipAnchor:SetHeight(anchor:GetHeight())
        self.tip:SmartAnchorTo(self.tipAnchor)

        self.tip:SetAutoHideDelay(0.1, anchor)

        self:ReloadInterface()
        self.tip:Show()
    end
end

function tooltip:Hide()
    if self.tipAnchor then
        self.tipAnchor:Hide()
        self.tipAnchor:SetParent(nil)
        self.tipAnchor = nil
    end

    if self.tip then
        LibQTip:Release(self.tip)
    end
end

function tooltip:Redraw(reload)
    if not self.tip then
        return
    end

    local spells = addon:GetSpells()
    local zoneText = _G.GetRealZoneText()

    local lineIndex

    if reload then
        self.tip:Clear()
        lineIndex = self.tip:AddLine()
     else
        lineIndex = 1
    end

    self:SetLine(lineIndex, 0, nil, _G.MINIMAP_TRACKING_NONE, zoneText)

    local spellId, spellName, spellIcon

    for i = 1, #spells do
        spellId, spellName, spellIcon = unpack(spells[i])

        if reload then
            lineIndex = self.tip:AddLine()
        else
            lineIndex = lineIndex + 1
        end

        self:SetLine(lineIndex, spellId, spellIcon, spellName, zoneText)
    end
end

function tooltip:SetLine(lineIndex, spellId, spellIcon, spellName, zoneText)
    local isSpellDualTracked = (
        addon.dualTrackingIds.primary == spellId
        or addon.dualTrackingIds.secondary == spellId
    )

    local textColor = "|cFFFFFFFF" -- white
    if isSpellDualTracked then
        textColor = "|cFFFFFF00" -- yellow
    elseif PersistentStorage["autoTracking"][zoneText] == spellId then
        textColor = "|cFF75FF75" -- green
    end

    local radio = "|T:0|t"
    if addon.activeTrackingId == spellId then
        radio = "|TInterface\\Buttons\\UI-RadioButton:8:8:0:0:64:16:19:28:3:12|t"
    elseif isSpellDualTracked then
        radio = "|TInterface\\Buttons\\UI-RadioButton:7:7:0:0:64:16:2:11:3:12|t"
    end

    self.tip:SetCell(lineIndex, 1, radio)

    if spellIcon then
        self.tip:SetCell(lineIndex, 2, "|T"..spellIcon..":14|t")
    end

    self.tip:SetCell(lineIndex, 3, textColor..spellName)

    self.tip:SetLineScript(lineIndex, "OnMouseUp", self:LineScriptFactory(spellId))
end

function tooltip:LineScriptFactory(spellId)
    return function()
        -- CTRL + left click to toggle auto tracking
        if _G.IsControlKeyDown() then
            local zoneText = _G.GetRealZoneText()

            if PersistentStorage["autoTracking"][zoneText] ~= nil then
                if PersistentStorage["autoTracking"][zoneText] == spellId then
                    addon:SetAutoTracking(zoneText, nil)
                    return
                else
                    addon:SetAutoTracking(zoneText, spellId)
                end
            else
                addon:SetAutoTracking(zoneText, spellId)
            end
        end

        -- ALT + left click to toggle dual tracking
        if _G.IsAltKeyDown() and spellId ~=0 then
            if (
                addon.dualTrackingIds.secondary == spellId
                or addon.dualTrackingIds.primary == spellId
            ) then
                addon:SetDualTracking(nil, nil)
            elseif (
               addon.activeTrackingId ~= 0
               and addon.activeTrackingId ~= spellId
            ) then
                if addon.dualTrackingIds.primary then
                    addon:SetDualTracking(addon.dualTrackingIds.primary, spellId)
                else
                    addon:SetDualTracking(addon.activeTrackingId, spellId)
                end
            end

            addon:Publish("REDRAW_INTERFACE")

            return
        end

        -- if dual tracking is enabled, set new primary tracking if tooltip is left clicked
        if addon.dualTrackingIds.primary then
            addon.dualTrackingIds.primary = spellId
        end

        addon:SetTracking(spellId)
    end
end
