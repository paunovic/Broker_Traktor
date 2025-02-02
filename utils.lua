Utils = {}

function Utils:SetDefault(table, key, defaultValue)
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
