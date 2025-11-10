local BaseScreen = require("core.BaseScreen")

local GameScreen = BaseScreen:new({
    name = "game",
    
    enter = function(self)
        GameScreenManager:change("game_level_select")
    end,
    
    input = function(self, eventType, key, realKey)
        GameScreenManager:input(eventType, key, realKey)
    end,
    
    update = function(self, dt)
        GameScreenManager:update(dt)
    end,
    
    render = function(self)
        GameScreenManager:render()
    end
})

return GameScreen