-- tracking spells api

local _G = _G

TrackingApi = {}
TrackingApi.SpellInfo = {}
TrackingApi.SpellIcons = {}


function TrackingApi:BuildSpellList()
    local keywords = {"Track", "Find"}
    local tracked

    for tab = 1, _G.GetNumSpellTabs() do
        local _, _, offset, numSpells = _G.GetSpellTabInfo(tab);

        for i = offset + 1, offset + numSpells do
            local spellIcon = _G.GetSpellBookItemTexture(i, BOOKTYPE_SPELL);
            local spellName = _G.GetSpellBookItemName(i, BOOKTYPE_SPELL);
            local _, spellId = _G.GetSpellBookItemInfo(i, BOOKTYPE_SPELL)

            for _, keyword in ipairs(keywords) do
                tracked = spellName:match(keyword.." (%a+)")
                if tracked then
                    break
                end
            end

            if tracked then
                self.SpellInfo[spellId] = {
                    name = spellName,
                    icon = spellIcon
                }
                self.SpellIcons[spellIcon] = spellId
            end
        end
    end
end

function TrackingApi:GetCurrentTracking()
    for i = 1, C_Minimap.GetNumTrackingTypes() do
        local trackingInfo = C_Minimap.GetTrackingInfo(i)
        if trackingInfo.active then
            for spellId, spellInfo in pairs(self.SpellInfo) do
                if spellInfo.name == trackingInfo.name then
                    return spellId, spellInfo.name, spellInfo.icon
                end
            end
        end
    end

    return nil
end

function TrackingApi:SetTracking(id, _)
    local spell = self.SpellInfo[id]

    if not spell then
        error("Invalid spell ID: " .. id)
    end

    _G.CastSpellByName(spell["name"])
end

function TrackingApi:IsTracking(spellId)
    local currentId, _, _ = TrackingApi:GetCurrentTracking()

    if not currentId then
        return false
    end

    if currentId == spellId then
        return true
    else
        return false
    end
end

function TrackingApi:GetTrackingInfo(spellId)
    local spell = self.SpellInfo[spellId]
    local active = TrackingApi:IsTracking(spellId)
    return spell.name, spell.icon, active
end

function TrackingApi:GetActiveTrackingId()
    for spellId, _ in pairs(self.SpellInfo) do
        local _, _, spellActive = TrackingApi:GetTrackingInfo(spellId)
        if spellActive then
            return spellId
        end
    end

    return 0
end
