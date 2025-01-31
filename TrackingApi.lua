-- tracking spells api

TrackingApi = {}
TrackingApi.SpellInfo = {}
TrackingApi.SpellIcons = {}

function TrackingApi:BuildSpellList(keywords)
    if not keywords then
        keywords = {"Track", "Find"}
    end

    local count = 0
    local tracked

    for tab=1,4 do
        local _, _, offset, numSpells = GetSpellTabInfo(tab);

        for i = offset + 1, offset + numSpells do
            local spellIcon = GetSpellBookItemTexture(i, BOOKTYPE_SPELL);

            local spellName = GetSpellBookItemName(i, BOOKTYPE_SPELL);
            local _, spellId = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)

            for _, keyword in ipairs(keywords) do
                tracked = spellName:match(keyword.." (%a+)")
                if tracked then
                    break
                end
            end

            if tracked then
                self.SpellInfo[spellId] = { name=spellName, icon= spellIcon }
                self.SpellIcons[spellIcon] = spellId
                count = count + 1
            end
        end
    end
end

function TrackingApi:GetCurrentTracking()
    local icon = GetTrackingTexture()

    if not icon then
        return
    end

    local spellId = self.SpellIcons[icon]
    local spell = self.SpellInfo[spellId]
    return spellId, spell.name, spell.icon
end

function SetTracking(id, _)
    local spell = self.SpellInfo[id]

    if not spell then
        error("Invalid spell ID: " .. id)
    end

    CastSpellByName(spell["name"])
end

function TrackingApi:IsTracking(spellId)
    local currentId, _, _ = TrackingApi:GetCurrentTracking()

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
    for spellId, spell in pairs(self.SpellInfo) do
        name, texture, active = TrackingApi:GetTrackingInfo(spellId)
        if active then
            return spellId
        end
    end

    return 0
end
