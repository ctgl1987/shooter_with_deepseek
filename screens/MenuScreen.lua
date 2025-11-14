

local MenuScreen = BaseScreen:new({
    name = "menu",

    enter = function(self)
        self.bg = Utils.createScrollingBackground(ImageManager:get("bg_title"), 0)
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
        }, 
        {
            name = function()
                return "Enemy Showcase"
            end,
            action = function()
                ScreenManager:push("enemy_showcase")
            end
        }
        ,{
            name = function()
                return "Settings"
            end,
            action = function()
                ScreenManager:push("settings")
            end
        }}

        -- Agregar opción de salida si estamos en NW.js
        if love.system.getOS() == "Windows" or love.system.getOS() == "OS X" or love.system.getOS() == "Linux" then
            table.insert(menuItems, {
                name = function()
                    return "Quit"
                end,
                action = function()
                    love.event.quit()
                end
            })
        end

        self.menu = Utils.createMenu(menuItems)

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
            color = {0.1, 0.1, 0.1, 0.3}
        })

        self.menu:render(GAME_HEIGHT * 0.6)
    end
})

return MenuScreen
