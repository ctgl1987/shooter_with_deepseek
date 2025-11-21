

local LevelSelectScreen = BaseScreen:new({
    name = "game_level_select",

    enter = function(self, data)
        self.bg = UI.createScrollingBackground(ImageManager:get("bg_intro"), 0)
        self.levels = {}

        for i, level in ipairs(Levels.list) do
            table.insert(self.levels, {
                id = level.id,
                name = "Level " .. level.id .. ": " .. level.name,
                unlocked = GameState.levelsUnlocked[level.id] or false,
                finished = (GameState.levelsCompleted[level.id] or { completed = false }).completed
            })
        end

        self.selectedLevel = data and data.nextLevel or 1
        for i, level in ipairs(self.levels) do
            if level.unlocked then
                self.selectedLevel = level.id
            end
        end
    end,

    input = function(self, eventType, key)
        if eventType == "keydown" then
            if key == "back" then
                ScreenManager:change("menu")
            elseif key == "up" then
                AudioManager:play("menu")
                self.selectedLevel = self.selectedLevel - 1
                if self.selectedLevel < 1 then self.selectedLevel = #self.levels end
            elseif key == "down" then
                AudioManager:play("menu")
                self.selectedLevel = self.selectedLevel + 1
                if self.selectedLevel > #self.levels then self.selectedLevel = 1 end
            elseif key == "select" then
                local level = self.levels[self.selectedLevel]
                if level.unlocked then
                    AudioManager:play("menu")
                    local selectedLevel = Utils.deepCopy(Levels.list[self.selectedLevel])
                    GameScreenManager:change("game_play", {
                        level = selectedLevel
                    })
                end
            end
        end
    end,

    update = function(self, dt)
        InputManager:setContext("menu")
        self.bg:update(dt)
    end,

    render = function(self)
        self.bg:render()

        -- Draw semi-transparent overlay
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {color = "#00000088"})

        DrawManager:fillText("Select Level", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.1,
            { size = 30, align = "center" })

        for i, level in ipairs(self.levels) do
            local selected = self.selectedLevel == i
            local color = level.unlocked and "#FFFFFF" or "#888888"
            if level.finished then
                color = "green"
            end

            local name = selected and "> " .. level.name .. " <" or level.name
            DrawManager:fillText(name, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.3 + (i * 40), {
                color = color,
                align = "center",
                shadow = true
            })
        end

        DrawManager:fillText("Back (Escape or Button B)", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.9, {
            align = "center"
        })
    end
})

return LevelSelectScreen
