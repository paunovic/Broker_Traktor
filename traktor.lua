local addonName, addon = ...
LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceEvent-3.0", "LibPubSub-1.0")

local _G = _G

function addon:OnInitialize()
    self.spells = {}
    self.activeTrackingId = nil
    self.alternateTrackingIds = {
        primary = nil,
        secondary = nil
    }
    self.alternateTrackingTimer = nil
    self.cooldownTimer = nil
end


function addon:OnEnable()
    if not PersistentStorage then
        print("|cFFBBBBBBTraktor: ".."|cFFFFFFFFInitializing...")

        PersistentStorage = {
            smartTracking = {}
        }
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
        -- if no tracking is selected, cancel alternate tracking as well
        addon:SetAlternateTracking(nil, nil)
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

function addon:CreateAlternateTrackingTicker()
    self.alternateTrackingTimer = C_Timer.NewTicker(2.5, function()
        if not _G.UnitIsDeadOrGhost("player") then
            if self.activeTrackingId == self.alternateTrackingIds.primary then
                self:SetTracking(self.alternateTrackingIds.secondary)
            else
                self:SetTracking(self.alternateTrackingIds.primary)
            end
        end
    end)
end

function addon:CancelAlternateTrackingTicker()
    if self.alternateTrackingTimer then
        self.alternateTrackingTimer:Cancel()
        self.alternateTrackingTimer = nil
    end
end

function addon:SetAlternateTracking(primarySpellId, secondarySpellId)
    if (
       self.alternateTrackingIds.primary == primarySpellId
       and self.alternateTrackingIds.secondary == secondarySpellId
    ) then
        return
    end

    local original_primary = self.alternateTrackingIds.primary
    self.alternateTrackingIds.primary = primarySpellId
    self.alternateTrackingIds.secondary = secondarySpellId

    self:CancelAlternateTrackingTicker()

    if self.alternateTrackingIds.primary then
        self:CreateAlternateTrackingTicker()
        print("|cFFFFFFFFTraktor: alternate tracking |cFF00FF00on|cFFFFFFFF (|cFF75FF75"..C_Spell.GetSpellName(secondarySpellId).."|cFFFFFFFF)")
    else
        self:SetTracking(original_primary)
        print("|cFFFFFFFFTraktor: alternate tracking |cFFFF3333off")
   end
end

function addon:IsSmartTracking(spellId)
    local zoneText = _G.GetRealZoneText()
    return PersistentStorage["smartTracking"][zoneText] == spellId
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

function addon:OnZoneChangedNewArea()
    local zoneText = _G.GetRealZoneText()

    local smartTrackingSpellId = PersistentStorage["smartTracking"][zoneText]

    if smartTrackingSpellId then
        if addon.alternateTrackingIds.primary then
            addon.alternateTrackingIds.primary = smartTrackingSpellId
        end
        self:SetTracking(smartTrackingSpellId)
    end

    self:Publish("REDRAW_INTERFACE")
end

function addon:OnSpellsChanged()
    self:UpdateSpells()
    self:Publish("RELOAD_INTERFACE")
end
