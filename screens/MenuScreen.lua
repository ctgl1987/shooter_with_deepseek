local MenuScreen = BaseScreen:new({
    name = "menu",

    enter = function(self)
        self.bg = UI.createScrollingBackground(ImageManager:get("bg_title"), 0)
        self:createMenu()

    end,

    createMenu = function(self)
        local menuItems = {{
            name = function()
                return "Play Game"
            end,
            action = function()
                ScreenManager:change("intro")
            end
        }, {
            name = function()
                return "Enemy Showcase"
            end,
            action = function()
                ScreenManager:push("enemy_showcase")
            end
        }, {
            name = function()
                return "Settings"
            end,
            action = function()
                ScreenManager:push("settings")
            end
        }}

        -- Agregar opción de salida si es una plataforma de escritorio o android
        if love.system.getOS() == "Windows" or love.system.getOS() == "OS X" or love.system.getOS() == "Linux" or
            love.system.getOS() == "Android" then
            table.insert(menuItems, {
                name = function()
                    return "Quit"
                end,
                action = function()
                    love.event.quit()
                end
            })
        end

        self.menu = UI.createMenu(menuItems)

    end,

    input = function(self, eventType, key)
        if eventType == "keydown" then
            self.menu:input(eventType, key)
        end
    end,

    update = function(self, dt)
        InputManager:setContext("menu")
        self.bg:update(dt)
    end,

    render = function(self)
        self.bg:render()
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {
            color = "#1A1A1A4D",
        })

        self.menu:render(GAME_HEIGHT * 0.6)
    end
})

return MenuScreen
