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

        if not self.tipAnchor then
            self.tipAnchor = _G.CreateFrame("Frame", anchor)
        end
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

        self:SetLine(
            lineIndex,
            spellId,
            spellIcon,
            spellName,
            zoneText
        )
    end
end

function tooltip:SetLine(lineIndex, spellId, spellIcon, spellName, zoneText)
    local spellIsAlternate = (
        addon.alternateTrackingIds.primary == spellId
        or addon.alternateTrackingIds.secondary == spellId
    )

    local textColor = "|cFFFFFFFF" -- white
    if spellIsAlternate then
        textColor = "|cFFFFFF00" -- yellow
    elseif PersistentStorage["smartTracking"][zoneText] == spellId then
        textColor = "|cFF75FF75" -- green
    end

    local radio = "|T:0|t"
    if addon.activeTrackingId == spellId then
        radio = "|TInterface\\Buttons\\UI-RadioButton:8:8:0:0:64:16:19:28:3:12|t"
    elseif spellIsAlternate then
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
        if _G.IsShiftKeyDown() then
            local zoneText = _G.GetRealZoneText()

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
                    addon:Publish("REDRAW_INTERFACE")
                end
            else
                PersistentStorage["smartTracking"][zoneText] = spellId
                print("|cFFFFFFFFTraktor: smart tracking |cFF00FF00on|cFFFFFFFF for |cFFFCBA03"..zoneText.."|cFFFFFFFF (|cFF75FF75"..spellName.."|cFFFFFFFF)")
                addon:Publish("REDRAW_INTERFACE")
            end
        end

        if _G.IsControlKeyDown() and spellId ~=0 then
            if (
                addon.alternateTrackingIds.secondary == spellId
                or addon.alternateTrackingIds.primary == spellId
            ) then
                addon:SetAlternateTracking(nil, nil)
            elseif (
               addon.activeTrackingId ~= 0
               and addon.activeTrackingId ~= spellId
            ) then
                if addon.alternateTrackingIds.primary then
                    addon:SetAlternateTracking(addon.alternateTrackingIds.primary, spellId)
                else
                    addon:SetAlternateTracking(addon.activeTrackingId, spellId)
                end
            end

            addon:Publish("REDRAW_INTERFACE")

            return
        end

        -- if alternate tracking is enabled, set new primary tracking if tooltip is left clicked
        if addon.alternateTrackingIds.primary then
            addon.alternateTrackingIds.primary = spellId
        end

        addon:SetTracking(spellId)
    end
end
