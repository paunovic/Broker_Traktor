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
    if not PersistentStorage then
        print("|cFFBBBBBBTraktor: ".."|cFFFFFFFFInitializing...")

        PersistentStorage = {
            autoTracking = {}
        }
    end

    -- backwards compatibility, remove in the future
    if PersistentStorage.smartTracking then
        PersistentStorage.autoTracking = PersistentStorage.smartTracking
        PersistentStorage.smartTracking = nil
    end

    self:RegisterEvent("MINIMAP_UPDATE_TRACKING", "OnMinimapUpdateTracking")
    self:RegisterEvent("SPELLS_CHANGED", "OnSpellsChanged")
    self:RegisterEvent("SKILL_LINES_CHANGED", "UpdateSpells")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateSpells")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnUnitEvent")
    self:RegisterEvent("UNIT_AURA", "OnUnitEvent")
    self:RegisterEvent("PLAYER_ALIVE", "OnPlayerResurrect")
    self:RegisterEvent("PLAYER_UNGHOST", "OnPlayerResurrect")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChangedNewArea")
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

    self:CheckTracking()

    self:Publish("REDRAW_INTERFACE")
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
    PersistentStorage["autoTracking"][zoneText] = spellId

    local spellName = "Not Tracking"
    if spellId and spellId ~= 0 then
        spellName = C_Spell.GetSpellName(spellId)
    end

    addon:Publish("REDRAW_INTERFACE")

    if not spellId then
        print("|cFFFFFFFFTraktor: auto tracking |cFFFF3333off|cFFFFFFFF for |cFFFCBA03"..zoneText)
    else
        print("|cFFFFFFFFTraktor: auto tracking |cFF00FF00on|cFFFFFFFF for |cFFFCBA03"..zoneText.."|cFFFFFFFF (|cFF75FF75"..spellName.."|cFFFFFFFF)")
    end
end

function addon:IsAutoTracking(zoneText, spellId)
    return PersistentStorage["autoTracking"][zoneText] == spellId
end

function addon:CreateDualTrackingTicker()
    self.dualTrackingTimer = C_Timer.NewTicker(2.5, function()
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

    -- clear dual tracking if we're in a dungeon, raid, or arena
    local _, instanceType = _G.GetInstanceInfo()
    if instanceType == "party" or instanceType == "raid" or instanceType == "arena" then
        if addon.dualTrackingIds.primary then
            addon.dualTrackingIds.primary = nil
            addon.dualTrackingIds.secondary = nil
        end
    end

    local autoTrackingSpellId = PersistentStorage["autoTracking"][zoneText]

    if autoTrackingSpellId then
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

function addon:OnPlayerResurrect()
    if self.activeTrackingId and not _G.UnitIsDeadOrGhost("player") then
        local trackingId = self.activeTrackingId
        self.activeTrackingId = nil
        self:SetTracking(trackingId)
    end
end

function addon:OnSpellsChanged()
    self:UpdateSpells()
    self:Publish("RELOAD_INTERFACE")
end
