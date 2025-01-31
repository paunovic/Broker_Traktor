local addonName, addon = ...
LibStub("AceAddon-3.0"):NewAddon(addon, addonName, "AceEvent-3.0", "LibPubSub-1.0")

-- localise global variables
local _G = _G
local GetNumSpellTabs, GetSpellCooldown, UnitIsDeadOrGhost = _G.GetNumSpellTabs, _G.GetSpellCooldown, _G.UnitIsDeadOrGhost

function addon:OnInitialize()
    self.spells = {}
    self.trackingId = nil
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
    self:RegisterEvent("SPELLS_CHANGED", "UpdateSpells")
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

    if not activeTrackingId then
        -- wait a second in case we"re (supposed to be) dead, event order is unpredictable
        C_Timer.After(1, function()
            local activeTrackingId = TrackingApi:GetActiveTrackingId()
            if self.trackingId ~= activeTrackingId then
                self:TriggerTrackingChanged()
            end
        end)
    elseif self.trackingId ~= activeTrackingId then
        self:TriggerTrackingChanged()
    end
end

function addon:TriggerTrackingChanged()
    if not UnitIsDeadOrGhost("player") then
        self.trackingId = TrackingApi:GetActiveTrackingId()
    end

    self:Publish("TRACKING_CHANGED")
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
        spell_id_a, _, _ = unpack(a)
        spell_id_b, _, _ = unpack(b)

        local aIndex, bIndex

        for i, v in ipairs(spells) do
            if v == spell_id_a then
                aIndex = i
            end
            if v == spell_id_b then
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
        CancelTrackingBuff()
    elseif spellId ~= TrackingApi:GetActiveTrackingId() then
        local cooldownStart, cooldownDuration = GetSpellCooldown(spellId)
        if cooldownStart > 0 and cooldownDuration > 0 then
            self.cooldownTimer = C_Timer.NewTimer(0.01 + cooldownStart + cooldownDuration - GetTime(), function()
                self:SetTracking(spellId)
            end)
        else
            CastSpellByID(spellId)
        end
    end
end

function addon:OnUnitEvent(event, unit)
    if unit == "player" then
        self:CheckTracking()
    end
end

function addon:OnMinimapUpdateTracking()
    self:CheckTracking()
end

function addon:OnPlayerResurrect()
    if self.trackingId and not UnitIsDeadOrGhost("player") then
        local trackingId = self.trackingId
        self.trackingId = nil
        self:SetTracking(trackingId)
    end
end

function addon:OnZoneChangedNewArea()
    zoneText = GetRealZoneText()

    local smartTrackingSpellId = PersistentStorage["smartTracking"][zoneText]

    if smartTrackingSpellId then
        self:SetTracking(smartTrackingSpellId)
    end

    self:Publish("REDRAW_INTERFACE")
end
