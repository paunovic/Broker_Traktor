-- settings layout

local addonName, addon = ...

settingsLayout = {
    name = addonName,
    type = "group",
    args = {
        dualTrackingHeader = {
            name = "Dual Tracking",
            order = 1,
            type = "header",
        },
        dualTrackingInterval = {
            name = "Interval (seconds)",
            desc = "How often to switch between primary and secondary tracking",
            order = 1.1,
            type = "input",
            width = "double",
            set = function(info, value)
                value = tonumber(value)
                if not value or value < 1.5 then
                    value = 1.5
                end
                PersistentStorage.dualTrackingInterval = value
                if addon.dualTrackingTimer then
                    addon:CancelDualTrackingTicker()
                    addon:CreateDualTrackingTicker()
                end
            end,
            get = function(info)
                local v = tostring(PersistentStorage.dualTrackingInterval)
                return v
            end
        },
        dualTrackingDisableInCombat = {
            name = "Disable while in Combat",
            desc = "Temporarily disable dual tracking when entering combat",
            order = 1.2,
            type = "toggle",
            width = "double",
            set = function(info, value)
                PersistentStorage.dualTrackingDisableInCombat = value
            end,
            get = function(info)
                return PersistentStorage.dualTrackingDisableInCombat
            end
        },
        dualTrackingDisableInInstance = {
            name = "Disable when entering",
            order = 1.3,
            type = "multiselect",
            values = {
                party = "Dungeon",
                raid = "Raid",
                arena = "Arena",
                battleground = "Battleground"
            },
            set = function(info, key, value)
                PersistentStorage.dualTrackingDisableInInstance[key] = value
            end,
            get = function(info, key)
                return PersistentStorage.dualTrackingDisableInInstance[key]
            end
        },
    },
}
