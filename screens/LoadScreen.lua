local LoadScreen = BaseScreen:new({
    name = "load",
    loaded = 0,
    total = 0,
    progress = 0,
    currentName = "",
    enter = function(self)
        -- Reiniciar valores cuando entras a la pantalla
        self.loaded = 0
        self.total = 0
        self.progress = 0
        self.currentName = ""
    end,

    update = function(self, dt)
        -- local start_time = love.timer.getTime()
        -- while love.timer.getTime() - start_time < 0.1 do
        -- end
        -- Actualizar el ImageManager (esto procesa los mensajes del thread)
        ImageManager:update()

        -- Obtener los valores ACTUALIZADOS usando los métodos públicos
        self.loaded = ImageManager:getLoadedCount()
        self.total = ImageManager:getTotalCount()
        self.progress = ImageManager:getProgress()
        self.currentName = ImageManager.currentName or ""

        -- Debug: mostrar progreso en consola
        if self.loaded > 0 and self.loaded % 5 == 0 then
            print(string.format("LoadScreen: %d/%d (%.1f%%) - %s", self.loaded, self.total, self.progress * 100,
                self.currentName))
        end

        -- Cambiar de pantalla cuando termine la carga
        if not ImageManager:loading() and ImageManager:isLoaded() then
            print("> All images loaded, switching to menu...")
            ScreenManager:change("menu")
        end
    end,

    render = function(self)
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {
            color = BG_COLOR
        })

        -- Texto de carga
        DrawManager:fillText("Loading Assets...", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.4, {
            size = 30,
            align = "center"
        })

        -- Mostrar progreso
        local loaded = self.loaded
        local total = self.total
        local progress = self.progress

        -- Barra de progreso
        local barWidth = 400
        local barHeight = 30
        local barX = (GAME_WIDTH - barWidth) / 2
        local barY = GAME_HEIGHT * 0.6

        -- Fondo de la barra
        DrawManager:fillRect(barX, barY, barWidth, barHeight, {
            color = "gray"
        })
        -- Barra de progreso
        DrawManager:fillRect(barX, barY, barWidth * progress, barHeight, {
            color = "#FF0000"
        })
        -- Borde de la barra
        DrawManager:strokeRect(barX, barY, barWidth, barHeight, {
            color = "white"
        })
        -- Porcentaje numérico
        DrawManager:fillText(string.format("%.0f%%", progress * 100), GAME_WIDTH * 0.5, barY, {
            align = "center",
            size = 20,
            shadow = false
        })

        -- Mostrar qué se está cargando actualmente
        -- if self.currentName and self.currentName ~= "" then
        --     DrawManager:fillText("Loading: " .. self.currentName, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.7, {
        --         align = "center",
        --         size = 16
        --     })
        -- end
    end
})

return LoadScreen
