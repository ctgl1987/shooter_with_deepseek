local GameOverScreen = BaseScreen:new({
    name = "gameover",

    enter = function(self, data)
        self.score = 0
        for _, level in pairs(GameState.levelsCompleted) do
            self.score = self.score + (level.score or 0)
        end
        self.bg = Utils.createScrollingBackground(ImageManager:get("bg_intro"), 0)
    end,

    input = function(self, eventType, key)
        if eventType == "keydown" then
            if key == "back" then
                ScreenManager:change("menu")
            end
        end
    end,
    update = function(self, dt)
        InputManager:setContext("menu")
        self.bg:update(dt)
    end,

    render = function(self)
        self.bg:render()

        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color = { 0, 0, 0, 0.5 } })

        DrawManager:fillText("Game Over!", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.4,
            { size = 40, align = "center", color = "red" })
        DrawManager:fillText("Last Score: " .. self.score, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5,
            { align = "center", color = "white" })
        DrawManager:fillText("Back to Menu (Escape or Button B)", GAME_WIDTH * 0.5, GAME_HEIGHT - 100,
            { align = "center", color = "white" })
    end
})

return GameOverScreen
