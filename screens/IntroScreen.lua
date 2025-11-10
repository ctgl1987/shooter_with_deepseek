local BaseScreen = require("core.BaseScreen")

local IntroScreen = BaseScreen:new({
    name = "intro",

    enter = function(self)
        
        self.currentLine = 0
        self.counter = 0
        self.bg = Utils.createScrollingBackground(ImageManager:get("bg_intro"), 0)

        self.briefText = {"THE YEAR IS 2154.", "HUMANITY'S GOLDEN AGE OF SPACE EXPLORATION",
                          "HAS COME TO A SUDDEN, VIOLENT END.", "", "THE XENOTYPES - AN ANCIENT SWARM INTELLIGENCE -",
                          "HAVE AWAKENED. THEY CONSUME WORLDS, LEAVE ONLY DUST.", "",
                          "EARTH'S FLEET HAS FALLEN. COLONIES ARE SILENT.", "",
                          "YOU ARE THE LAST ACTIVE FIGHTER OF THE", "ORBITAL DEFENSE INITIATIVE - CODENAME: 'DEFIANT'.",
                          "", "YOUR MISSION: HOLD THE LINE AT THE SOLAR GATE,",
                          "THE FINAL BARRIER BETWEEN THE SWARM AND EARTH.", "", "SURVIVE. ENDURE. DEFY."}
    end,

    input = function(self, eventType, key)
        if eventType == "keydown" then
            ScreenManager:change("game")
        end
    end,

    update = function(self, dt)
        InputManager:setContext("menu")
        
        self.counter = self.counter + 1
        self.bg:update(dt)

        if self.counter % 90 == 0 and self.currentLine < #self.briefText then
            self.currentLine = self.currentLine + 1
        end

        if self.currentLine >= #self.briefText and self.counter > (#self.briefText * 90) + 180 then
            ScreenManager:change("game")
        end
    end,

    render = function(self)
        self.bg:render()

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
                    color = {1, 1, 1, alpha}
                })
            end
        end
    end
})

return IntroScreen
