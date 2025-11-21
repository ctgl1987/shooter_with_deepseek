-- serpent.lua (versión simplificada para el sistema de guardado)
local serpent = {}

function serpent.block(value, options)
    options = options or {}
    local seen = {}
    local function dump(value, indent)
        local typ = type(value)
        
        if typ == "nil" then
            return "nil"
        elseif typ == "boolean" then
            return tostring(value)
        elseif typ == "number" then
            return tostring(value)
        elseif typ == "string" then
            return string.format("%q", value)
        elseif typ == "table" then
            if seen[value] then
                return "\"<cycle>\""
            end
            seen[value] = true
            
            local result = "{\n"
            local new_indent = indent .. "  "
            
            for k, v in pairs(value) do
                result = result .. new_indent .. "[" .. dump(k, new_indent) .. "] = " .. dump(v, new_indent) .. ",\n"
            end
            
            result = result .. indent .. "}"
            seen[value] = nil
            return result
        else
            return "\"<" .. typ .. ">\""
        end
    end
    
    return dump(value, "")
end

return serpent