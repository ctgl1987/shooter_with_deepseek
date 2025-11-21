

local GameEndScreen = BaseScreen:new({
    name = "game_end",

    enter = function(self, data)
        self.score = 0
        for _, level in pairs(GameState.levelsCompleted) do
            self.score = self.score + (level.score or 0)
        end
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
    end,

    render = function(self)
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {
            color = BG_COLOR
        })

        DrawManager:fillText("Congratulations! You completed the game!", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.4, {
            size = 30,
            align = "center",
            color = "yellow"
        })
        DrawManager:fillText("Total Score: " .. self.score, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5, {
            align = "center",
            color = "white"
        })
        DrawManager:fillText("Back to Menu (Escape or Button B)", GAME_WIDTH * 0.5, GAME_HEIGHT - 100, {
            align = "center",
            color = "white"
        })
    end
})

return GameEndScreen
