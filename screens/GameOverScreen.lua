local BaseScreen = require("core.BaseScreen")

local GameOverScreen = BaseScreen:new({
    name = "gameover",
    
    enter = function(self, data)
        self.score = 0
        for _, level in pairs(GameState.levelsCompleted) do
            self.score = self.score + (level.score or 0)
        end
    end,
    
    input = function(self, eventType, key)
        if eventType == "keydown" then
            if key == "escape" then
                ScreenManager:change("menu")
            end
        end
    end,
    
    render = function(self)
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color = BG_COLOR })
        
        DrawManager:fillText("Game Over!", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.4, 
                           {size = 40, align = "center", color = "red"})
        DrawManager:fillText("Last Score: " .. self.score, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5, 
                           {align = "center", color = "white"})
        DrawManager:fillText("Back to Menu (Escape or Button B)", GAME_WIDTH * 0.5, GAME_HEIGHT - 100, 
                           {align = "center", color = "white"})
    end
})

return GameOverScreen