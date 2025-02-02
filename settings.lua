-- settings layout

local addonName, addon = ...

settingsLayout = {
    name = "Broker: Traktor",
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
                if value > 20 then
                    value = 20
                end
                PersistentStorage.dualTracking.interval = value
                if addon.dualTrackingTimer then
                    addon:CancelDualTrackingTicker()
                    addon:CreateDualTrackingTicker()
                end
            end,
            get = function(info)
                local v = tostring(PersistentStorage.dualTracking.interval)
                return v
            end
        },
        dualTrackingDisableInCombat = {
            name = "Disable while in combat",
            desc = "Temporarily disable dual tracking when entering combat",
            order = 1.2,
            type = "toggle",
            width = "double",
            set = function(info, value)
                PersistentStorage.dualTracking.disableInCombat = value
            end,
            get = function(info)
                return PersistentStorage.dualTracking.disableInCombat
            end
        },
        dualTrackingDisableWhileResting = {
            name = "Disable while resting",
            desc = "Temporarily disable dual tracking while resting (in town/inn)",
            order = 1.2,
            type = "toggle",
            width = "double",
            set = function(info, value)
                PersistentStorage.dualTracking.disableWhileResting = value
            end,
            get = function(info)
                return PersistentStorage.dualTracking.disableWhileResting
            end
        },
        dualTrackingDisableWhileStationary = {
            name = "Disable while stationary",
            desc = "Temporarily disable dual tracking while stationary (not moving)",
            order = 1.2,
            type = "toggle",
            width = "double",
            set = function(info, value)
                PersistentStorage.dualTracking.disableWhileStationary = value
            end,
            get = function(info)
                return PersistentStorage.dualTracking.disableWhileStationary
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
                PersistentStorage.dualTracking.disableInInstance[key] = value
            end,
            get = function(info, key)
                return PersistentStorage.dualTracking.disableInInstance[key]
            end
        },
    },
}
