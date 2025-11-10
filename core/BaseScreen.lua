local BaseScreen = {}

function BaseScreen:new(p)
    p = p or {}
    local screen = {}
    
    screen.name = p.name or "screen"
    
    -- Métodos base
    screen.enter = p.enter or function(data) end
    screen.exit = p.exit or function() end
    screen.input = p.input or function(eventType, key, realKey) end
    screen.update = p.update or function(dt) end
    screen.render = p.render or function() end
    
    -- Propiedades adicionales
    for k, v in pairs(p) do
        screen[k] = v
    end
    
    return screen
end

return BaseScreen