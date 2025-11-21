

local SettingScreen = BaseScreen:new({
    name = "settings",
    
    enter = function(self)

        self.menu = UI.createMenu({
            {
                name = function() 
                    return "Sound: " .. (AudioManager:isMuted() and "OFF" or "ON")
                end,
                action = function()
                    AudioManager:toggleMute()
                    GameState.sound = not AudioManager:isMuted()
                    SaveGame()
                end
            },
            {
                name = function() 
                    return "Fullscreen: " .. (GameState.fullscreen and "ON" or "OFF")
                end,
                action = function()
                    GameState.fullscreen = not GameState.fullscreen
                    SetFullScreen(GameState.fullscreen)
                    SaveGame()
                end
            }
        })
    end,
    
    input = function(self, eventType, key)
        if eventType == "keydown" then
            if key == "back" then
                ScreenManager:pop()
            else
                self.menu:input(eventType, key)
            end
        end
    end,

    update = function(self, dt)
        InputManager:setContext("menu")
    end,
    
    render = function(self)
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color = BG_COLOR })
        
        DrawManager:fillText("Settings", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.2, 
                           {size = 30, align = "center"})
        
        self.menu:render(GAME_HEIGHT * 0.5)
        
        DrawManager:fillText("Back (Escape or Button B)", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.8, 
                           {align = "center"})
    end
})

return SettingScreen