

local GamePauseScreen = BaseScreen:new({
    name = "game_pause",
    
    enter = function(self)

        self.menu = UI.createMenu({
            {
                name = function() return "Resume" end,
                action = function()
                    GameScreenManager:pop()
                end
            },
            {
                name = function() return "Settings" end,
                action = function()
                    ScreenManager:push("settings")
                end
            },
            {
                name = function() return "Main Menu" end,
                action = function()
                    ScreenManager:change("menu")
                end
            }
        })
    end,
    
    input = function(self, eventType, key)
        if eventType == "keydown" then
            if key == "back" then
                GameScreenManager:pop()
            else
                self.menu:input(eventType, key)
            end
        end
    end,

    update = function(self, dt)
        InputManager:setContext("pause")
    end,
    
    render = function(self)
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {color = {0.05, 0.05, 0.08, 0.9}})
        
        DrawManager:fillText("Paused", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.3, 
                           {size = 40, align = "center"})
        
        self.menu:render(GAME_HEIGHT * 0.5)
        
        DrawManager:fillText("Back (Escape or Button B)", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.8, 
                           {align = "center"})
    end
})

return GamePauseScreen