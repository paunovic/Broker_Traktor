local addonName, addon = ...

LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceEvent-3.0", "LibPubSub-1.0")

local _G = _G

function addon:OnInitialize()
    self.spells = {}
    self.activeTrackingId = nil
    self.dualTrackingIds = {
        primary = nil,
        secondary = nil
    }
    self.dualTrackingTimer = nil
    self.cooldownTimer = nil
end

function addon:OnEnable()
    -- initialize on first run
    if not PersistentStorage then
        print("|cFFBBBBBBTraktor: ".."|cFFFFFFFFInitializing...")

        PersistentStorage = {
            dualTrackingInterval = 2,
            dualTrackingDisableInCombat = true,
            dualTrackingDisableInInstance = {
                party = true,
                raid = true,
                arena = true,
                battleground = true
            },
            autoTracking = {}
        }
    end

    -- backwards compatibility, remove in the future
    if PersistentStorage.smartTracking then
        PersistentStorage.autoTracking = PersistentStorage.smartTracking
        PersistentStorage.smartTracking = nil
    end
    if not PersistentStorage.dualTrackingInterval then
        PersistentStorage.dualTrackingInterval = 2
    end
    if not PersistentStorage.dualTrackingDisableInCombat then
        PersistentStorage.dualTrackingDisableInCombat = true
    end
    if not PersistentStorage.dualTrackingDisableInInstance then
        PersistentStorage.dualTrackingDisableInInstance = {
            party = true,
            raid = true,
            arena = true,
            battleground = true
        }
    end

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, settingsLayout, nil)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName):SetParent(InterfaceOptionsFramePanelContainer)

    self:RegisterEvent("SPELLS_CHANGED", "OnSpellsChanged")
    self:RegisterEvent("SKILL_LINES_CHANGED", "OnSpellsChanged")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnSpellsChanged")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnUnitEvent")
    self:RegisterEvent("UNIT_AURA", "OnUnitEvent")
    self:RegisterEvent("MINIMAP_UPDATE_TRACKING", "OnMinimapUpdateTracking")
    self:RegisterEvent("PLAYER_ALIVE", "OnPlayerResurrect")
    self:RegisterEvent("PLAYER_UNGHOST", "OnPlayerResurrect")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChangedNewArea")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnPlayerRegenDisabled")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayerRegenEnabled")

    addon:Subscribe("MOUSE_CLICK", self, "OnClick")
end

function addon:OnDisable()
    addon:Unsubscribe("MOUSE_CLICK", self, "OnClick")
    self:UnregisterAllEvents()
    self:CancelDualTrackingTicker()
end

function addon:GetSpells()
    return self.spells
end

function addon:CheckTracking()
    local activeTrackingId = TrackingApi:GetActiveTrackingId()

    if activeTrackingId == 0 then
        -- wait a second in case we're (supposed to be) dead
        C_Timer.After(1, function()
            activeTrackingId = TrackingApi:GetActiveTrackingId()
            if self.activeTrackingId ~= activeTrackingId then
                if not _G.UnitIsDeadOrGhost("player") then
                    self.activeTrackingId = activeTrackingId
                end
                self:Publish("TRACKING_CHANGED")
            end
        end)
    elseif self.activeTrackingId ~= activeTrackingId then
        if not _G.UnitIsDeadOrGhost("player") then
            self.activeTrackingId = activeTrackingId
        end
        self:Publish("TRACKING_CHANGED")
    end
end

function addon:UpdateSpells()
    -- spells will show in this order
    local spells = {
        2383, -- Find Herbs
        2580, -- Find Minerals
        2481, -- Find Treasure (Dwarf)
        5225, -- Track Humanoids (Druid)
        5500, -- Sense Demons (Warlock)
        5502, -- Sense Undead (Paladin)
        19882, -- Track Giants (Hunter)
        19884, -- Track Undead (Hunter)
        19880, -- Track Elementals (Hunter)
        19878, -- Track Demons (Hunter)
        19879, -- Track Dragonkin (Hunter)
        1494, -- Track Beasts (Hunter)
        19883, -- Track Humanoids (Hunter)
        19885, -- Track Hidden (Hunter)
    }

    TrackingApi:BuildSpellList()

    self.spells = {}

    for spellId, spellInfo in pairs(TrackingApi.SpellInfo) do
        for j = 1, #spells do
            if spellId == spells[j] then
                table.insert(self.spells, {spellId, spellInfo.name, spellInfo.icon})
                break
            end
        end
    end

    -- sort spells table based on the order in the spells list
    table.sort(self.spells, function(a, b)
        local spellIdA, _, _ = unpack(a)
        local spellIdB, _, _ = unpack(b)

        local aIndex, bIndex

        for i, v in ipairs(spells) do
            if v == spellIdA then
                aIndex = i
            end
            if v == spellIdB then
                bIndex = i
            end
        end

        return aIndex < bIndex
    end)
end

function addon:SetTracking(spellId)
    if self.cooldownTimer then
        self.cooldownTimer:Cancel()
        self.cooldownTimer = nil
    end

    if not spellId or spellId == 0 then
        -- if no tracking is selected, cancel dual tracking as well
        addon:SetDualTracking(nil, nil)
        _G.CancelTrackingBuff()
    elseif spellId ~= TrackingApi:GetActiveTrackingId() then
        local cooldownStart, cooldownDuration = _G.GetSpellCooldown(spellId)
        if cooldownStart > 0 and cooldownDuration > 0 then
            self.cooldownTimer = C_Timer.NewTimer(cooldownStart + cooldownDuration - _G.GetTime() + 0.01, function()
                self:SetTracking(spellId)
            end)
        else
            _G.CastSpellByID(spellId)
        end
    end
end

function addon:SetAutoTracking(zoneText, spellId)
    PersistentStorage.autoTracking[zoneText] = spellId

    local spellName = "Not Tracking"
    if spellId and spellId ~= 0 then
        spellName = C_Spell.GetSpellName(spellId)
    end

    addon:Publish("REDRAW_INTERFACE")

    if not spellId then
        print("|cFFFFFFFFTraktor: auto tracking |cFFFF3333off|cFFFFFFFF for |cFFFCBA03"..zoneText)
    else
        print("|cFFFFFFFFTraktor: auto tracking |cFF00FF00on|cFFFFFFFF for "..
              "|cFFFCBA03"..zoneText.."|cFFFFFFFF (|cFF75FF75"..spellName.."|cFFFFFFFF)")
    end
end

function addon:IsAutoTracking(zoneText, spellId)
    return PersistentStorage.autoTracking[zoneText] == spellId
end

function addon:CreateDualTrackingTicker()
    self.dualTrackingTimer = C_Timer.NewTicker(PersistentStorage.dualTrackingInterval, function()
        if not _G.UnitIsDeadOrGhost("player") then
            if self.activeTrackingId == self.dualTrackingIds.primary then
                self:SetTracking(self.dualTrackingIds.secondary)
            else
                self:SetTracking(self.dualTrackingIds.primary)
            end
        end
    end)
end

function addon:CancelDualTrackingTicker()
    if self.dualTrackingTimer then
        self.dualTrackingTimer:Cancel()
        self.dualTrackingTimer = nil
    end
end

function addon:SetDualTracking(primarySpellId, secondarySpellId)
    if (
       self.dualTrackingIds.primary == primarySpellId
       and self.dualTrackingIds.secondary == secondarySpellId
    ) then
        return
    end

    local original_primary = self.dualTrackingIds.primary
    self.dualTrackingIds.primary = primarySpellId
    self.dualTrackingIds.secondary = secondarySpellId

    self:CancelDualTrackingTicker()

    if self.dualTrackingIds.primary then
        self:CreateDualTrackingTicker()
        print("|cFFFFFFFFTraktor: dual tracking |cFF00FF00on|cFFFFFFFF "..
              "(|cFFFFFF00"..C_Spell.GetSpellName(primarySpellId).."|cFFFFFFFF / "..
              "|cFFFFFF00"..C_Spell.GetSpellName(secondarySpellId).."|cFFFFFFFF)")
    else
        self:SetTracking(original_primary)
        print("|cFFFFFFFFTraktor: dual tracking |cFFFF3333off")
   end
end

function addon:OnZoneChangedNewArea()
    local zoneText = _G.GetRealZoneText()

    -- clear dual tracking on entering instance
    local _, instanceType = _G.GetInstanceInfo()
    if PersistentStorage.dualTrackingDisableInInstance[instanceType:lower()] then
        self:SetDualTracking(nil, nil)
    end

    local autoTrackingSpellId = PersistentStorage.autoTracking[zoneText]

    if autoTrackingSpellId then
        -- if dual tracking is enabled, set new primary tracking
        if addon.dualTrackingIds.primary then
            addon.dualTrackingIds.primary = autoTrackingSpellId
        end
        self:SetTracking(autoTrackingSpellId)
    end

    self:Publish("REDRAW_INTERFACE")
end

function addon:OnUnitEvent(_, unit)
    if unit == "player" then
        self:CheckTracking()
    end
end

function addon:OnMinimapUpdateTracking()
    self:CheckTracking()
end

function addon:OnSpellsChanged()
    self:UpdateSpells()
    self:CheckTracking()
    self:Publish("RELOAD_INTERFACE")
end

function addon:OnPlayerResurrect()
    -- on ressurect, re-enable previously active tracking
    if self.activeTrackingId and not _G.UnitIsDeadOrGhost("player") then
        local trackingId = self.activeTrackingId
        self.activeTrackingId = nil
        self:SetTracking(trackingId)
    end
end

function addon:OnPlayerRegenDisabled()
    -- on combat start, cancel dual tracking ticker
    if PersistentStorage.dualTrackingDisableInCombat then
        if self.dualTrackingIds.primary then
            self:CancelDualTrackingTicker()
        end
    end
end

function addon:OnPlayerRegenEnabled()
    -- on combat end, restart dual tracking ticker
    if PersistentStorage.dualTrackingDisableInCombat then
        if self.dualTrackingIds.primary then
            self:CreateDualTrackingTicker()
        end
    end
end

function addon:OnClick(frame, button)
    if button == "RightButton" then
        _G.Settings.OpenToCategory(addonName)
    end
end
