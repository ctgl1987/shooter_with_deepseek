

local LevelCompletedScreen = BaseScreen:new({
    name = "game_level_completed",
    
    enter = function(self, data)
        self.score = data.score
        self.level = data.level
        self.bg = Utils.createScrollingBackground(ImageManager:get("bg_intro"), 0)
    end,
    
    input = function(self, eventType, key)
        if eventType == "keydown" then
            -- if key == "return" then
                local nextLevel = self.level.lastLevel and nil or (self.level.id + 1)
                GameScreenManager:change("game_level_select", {
                    nextLevel = nextLevel
                })
            -- end
        end
    end,
    update = function(self, dt)
        InputManager:setContext("menu")
        self.bg:update(dt)
    end,
    
    render = function(self)
        
        self.bg:render()

        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {color = {0, 0, 0, 0.5}})
        
        DrawManager:fillText("Level " .. self.level.id .. " Completed!", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.4, 
                           {size = 30, align = "center"})
        DrawManager:fillText("Score: " .. self.score, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5, 
                           {align = "center"})
        DrawManager:fillText("Press any key to continue", GAME_WIDTH * 0.5, GAME_HEIGHT - 100, 
                           {align = "center"})
    end
})

return LevelCompletedScreen