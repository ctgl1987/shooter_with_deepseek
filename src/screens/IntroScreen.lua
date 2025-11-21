

local IntroScreen = BaseScreen:new({
    name = "intro",

    enter = function(self)
        self.currentLine = 0
        self.counter = 0
        self.bg = UI.createScrollingBackground(ImageManager:get("bg_intro"))

        self.briefText = GAME_BRIEF
    end,

    input = function(self, eventType, key)
        if eventType == "keydown" then
            if self.currentLine < #self.briefText then
                self.currentLine = #self.briefText
                self.counter = (#self.briefText * 90)
                print("Skipping intro...")
            else
                ScreenManager:change("game")
            end
        end
    end,

    update = function(self, dt)
        InputManager:setContext("menu")

        self.counter = self.counter + 1
        self.bg:update(dt)

        if self.counter % 90 == 0 and self.currentLine < #self.briefText then
            self.currentLine = self.currentLine + 1
            if self.briefText[self.currentLine] == "" then
                self.currentLine = self.currentLine + 1
            end
        end

        if self.currentLine >= #self.briefText and self.counter > (#self.briefText * 90) + 180 then
            ScreenManager:change("game")
        end
    end,

    render = function(self)
        self.bg:render()

        -- Draw semi-transparent overlay
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {color = "#00000077"})

        local totalLines = #self.briefText
        local lineHeight = 30
        local totalTextHeight = totalLines * lineHeight
        local startY = (GAME_HEIGHT - totalTextHeight) * 0.4

        for i = 1, math.min(self.currentLine + 1, #self.briefText) do
            local lineStartTime = (i - 1) * 90
            local lineVisibleTime = math.max(0, self.counter - lineStartTime)
            local alpha = math.min(1, lineVisibleTime / 45)

            if self.briefText[i] ~= "" then
                DrawManager:fillText(self.briefText[i], GAME_WIDTH * 0.5, startY + ((i - 1) * lineHeight), {
                    align = "center",
                    color = { 1, 1, 1, alpha }
                })
            end
        end
    end
})

return IntroScreen
