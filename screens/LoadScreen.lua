local BaseScreen = require("core.BaseScreen")

local LoadScreen = BaseScreen:new({
    name = "load",
    
    enter = function(self)
        print("[] Starting asset loading...")
        ImageManager:load(function()
            print("> All assets loaded! Total: " .. ImageManager.loaded .. "/" .. ImageManager.total)
            ScreenManager:change("menu")
        end)
    end,
    
    render = function(self)
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color = BG_COLOR })
        
        -- Texto de carga
        DrawManager:fillText("Loading Assets...", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.4, 
                           {size = 30, align = "center"})
        
        -- Mostrar progreso
        local progress = ImageManager.loaded / ImageManager.total
        DrawManager:fillText(ImageManager.loaded .. "/" .. ImageManager.total .. " loaded", 
                           GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5, 
                           {align = "center"})
        
        -- Barra de progreso
        local barWidth = 400
        local barHeight = 30
        local barX = (GAME_WIDTH - barWidth) / 2
        local barY = GAME_HEIGHT * 0.6
        
        DrawManager:fillRect(barX, barY, barWidth, barHeight, {color = "gray"})
        DrawManager:fillRect(barX, barY, barWidth * progress, barHeight, {color = "green"})
        
        -- Mostrar qué se está cargando actualmente
        if ImageManager.loaded < ImageManager.total then
            local currentAsset = ImageManager.queue[ImageManager.loaded + 1]
            if currentAsset then
                DrawManager:fillText("Loading: " .. currentAsset.name, 
                                   GAME_WIDTH * 0.5, GAME_HEIGHT * 0.7, 
                                   {align = "center", size = 16})
            end
        end
    end
})

return LoadScreen