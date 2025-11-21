local StartScreen = BaseScreen:new({
    name = "start",

    enter = function(self)
        InputManager:setContext("menu")
        AudioManager:playLoop("bg")
        ScreenManager:change("menu")
    end,

    render = function(self)
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {
            color = { 0.04, 0, 0.13 }
        })
        DrawManager:fillText("Press Any Key to Start", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5, {
            size = 30,
            align = "center"
        })
    end
})

return StartScreen
