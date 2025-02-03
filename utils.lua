Utils = {}

function Utils:SetDefault(table, key, defaultValue)
    -- set default value for a nested table key
    local keys = {strsplit(".", key)}
    local t = table
    for i = 1, #keys - 1 do
        if t[keys[i]] == nil then
            t[keys[i]] = {}
        end
        t = t[keys[i]]
    end
    if t[keys[#keys]] == nil then
        t[keys[#keys]] = defaultValue
    end
end

function Utils:ColorToString(color)
    -- convert RGB table {a, r, g, b} color to hex string |cAARRGGBB
    return string.format("|c%02x%02x%02x%02x", color.a * 255, color.r * 255, color.g * 255, color.b * 255)
end

function Utils:ChatMessage(msg)
    -- print a message to chat
    if PersistentStorage.showChatMessages then
        print(msg)
    end
end
