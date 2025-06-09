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
            type = "range",
            min = 1.5,
            max = 20,
            step = 0.1,
            width = "full",
            set = function(info, value)
                BrokerTraktorStorage.dualTracking.interval = value
                if addon.dualTrackingTimer then
                    addon:CancelDualTrackingTicker()
                    addon:CreateDualTrackingTicker()
                end
            end,
            get = function(info)
                return BrokerTraktorStorage.dualTracking.interval
            end
        },
        dualTrackingDisableInCombat = {
            name = "Disable while in combat",
            desc = "Temporarily disable dual tracking when entering combat",
            order = 1.2,
            type = "toggle",
            width = "double",
            set = function(info, value)
                BrokerTraktorStorage.dualTracking.disableInCombat = value
            end,
            get = function(info)
                return BrokerTraktorStorage.dualTracking.disableInCombat
            end
        },
        dualTrackingDisableWhileResting = {
            name = "Disable while resting",
            desc = "Temporarily disable dual tracking while resting (in town/inn)",
            order = 1.3,
            type = "toggle",
            width = "double",
            set = function(info, value)
                BrokerTraktorStorage.dualTracking.disableWhileResting = value
            end,
            get = function(info)
                return BrokerTraktorStorage.dualTracking.disableWhileResting
            end
        },
        dualTrackingDisableWhileStationary = {
            name = "Disable while stationary",
            desc = "Temporarily disable dual tracking while stationary (not moving)",
            order = 1.4,
            type = "toggle",
            width = "double",
            set = function(info, value)
                BrokerTraktorStorage.dualTracking.disableWhileStationary = value
            end,
            get = function(info)
                return BrokerTraktorStorage.dualTracking.disableWhileStationary
            end
        },
        dualTrackingDisableInInstance = {
            name = "Disable when entering",
            order = 1.5,
            type = "multiselect",
            values = {
                party = "Dungeon",
                raid = "Raid",
                arena = "Arena",
                battleground = "Battleground"
            },
            set = function(info, key, value)
                BrokerTraktorStorage.dualTracking.disableInInstance[key] = value
            end,
            get = function(info, key)
                return BrokerTraktorStorage.dualTracking.disableInInstance[key]
            end
        },
        colorsHeader = {
            name = "Colors",
            order = 2,
            type = "header",
        },
        colorNotTracking = {
            name = "Not tracking",
            desc = "Color for inactive tracking spells",
            order = 2.1,
            type = "color",
            hasAlpha = true,
            set = function(info, r, g, b, a)
                local c = BrokerTraktorStorage.colors.notTracking
                c.r = r
                c.g = g
                c.b = b
                c.a = a
            end,
            get = function(info)
                local c = BrokerTraktorStorage.colors.notTracking
                return c.r, c.g, c.b, c.a
            end
        },
        colorTracking = {
            name = "Active tracking",
            desc = "Color for active tracking spell",
            order = 2.2,
            type = "color",
            hasAlpha = true,
            set = function(info, r, g, b, a)
                local c = BrokerTraktorStorage.colors.activeTracking
                c.r = r
                c.g = g
                c.b = b
                c.a = a
            end,
            get = function(info)
                local c = BrokerTraktorStorage.colors.activeTracking
                return c.r, c.g, c.b, c.a
            end
        },
        colorAutoTracking = {
            name = "Auto tracking",
            desc = "Color for auto tracking spell",
            order = 2.3,
            type = "color",
            hasAlpha = true,
            set = function(info, r, g, b, a)
                local c = BrokerTraktorStorage.colors.autoTracking
                c.r = r
                c.g = g
                c.b = b
                c.a = a
            end,
            get = function(info)
                local c = BrokerTraktorStorage.colors.autoTracking
                return c.r, c.g, c.b, c.a
            end
        },
        colorDualTracking = {
            name = "Dual tracking",
            desc = "Color for dual tracking spells",
            order = 2.4,
            type = "color",
            hasAlpha = true,
            set = function(info, r, g, b, a)
                local c = BrokerTraktorStorage.colors.dualTracking
                c.r = r
                c.g = g
                c.b = b
                c.a = a
            end,
            get = function(info)
                local c = BrokerTraktorStorage.colors.dualTracking
                return c.r, c.g, c.b, c.a
            end
        },
        miscHeader = {
            name = "Miscellaneous",
            order = 3,
            type = "header",
        },
        showChatMessages = {
            name = "Show chat messages",
            desc = "Show messages in chat",
            order = 3.1,
            type = "toggle",
            width = "double",
            set = function(info, value)
                BrokerTraktorStorage.showChatMessages = value
            end,
            get = function(info)
                return BrokerTraktorStorage.showChatMessages
            end
        },
        resetButtonGroup = {
            name = "",
            order = 3.2,
            type = "group",
            inline = true,
            args = {
                resetAutoTrackingToDefaults = {
                    name = "Reset auto tracking zones",
                    desc = "Reset all auto tracking zones to default values",
                    order = 1,
                    width = "double",
                    type = "execute",
                    func = function(info)
                        StaticPopupDialogs["TRAKTOR_RESET_AUTO_TRACKING_TO_DEFAULTS"] = {
                            text = "Are you sure you want to reset all auto tracking zones to default values?",
                            button1 = "Yes",
                            button2 = "No",
                            OnAccept = function()
                                BrokerTraktorStorage.autoTracking = {}
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("Broker: Traktor")
                            end,
                            timeout = 0,
                            whileDead = true,
                            hideOnEscape = true,
                            preferredIndex = 3,
                            showAlert = true,
                        }
                        _G.StaticPopup_Show("TRAKTOR_RESET_AUTO_TRACKING_TO_DEFAULTS")
                    end
                },
                resetToDefaults = {
                    name = "Reset to defaults",
                    desc = "Reset all settings to default values, except auto tracking zones",
                    order = 2,
                    width = "double",
                    type = "execute",
                    func = function(info)
                        StaticPopupDialogs["TRAKTOR_RESET_TO_DEFAULTS"] = {
                            text = "Are you sure you want to reset all settings to default values (except auto tracking zones)?",
                            button1 = "Yes",
                            button2 = "No",
                            OnAccept = function()
                                BrokerTraktorStorage = {
                                    autoTracking = BrokerTraktorStorage.autoTracking,
                                }
                                addon:SetBrokerTraktorStorageDefaults()
                                LibStub("AceConfigRegistry-3.0"):NotifyChange("Broker: Traktor")
                            end,
                            timeout = 0,
                            whileDead = true,
                            hideOnEscape = true,
                            preferredIndex = 3,
                            showAlert = true,
                        }
                        _G.StaticPopup_Show("TRAKTOR_RESET_TO_DEFAULTS")
                    end
                },
            },
        },
        labelHelp = {
            name = (
                "Ctrl + Click on the tooltip to enable auto tracking for the current zone.\n"..
                "Alt + Click on the tooltip to enable dual tracking."
            ),
            order = 4,
            type = "description",
            fontSize = "medium",
        },
    },
}
