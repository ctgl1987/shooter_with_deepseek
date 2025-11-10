local ImageManager = {}

function ImageManager:init(imageList)
    self.images = {}
    self.queue = imageList
    self.loaded = 0
    self.total = #imageList
    self.callback = nil
end

function ImageManager:load(callback)
    self.callback = callback
    
    for _, imgData in ipairs(self.queue) do
        local success, img = pcall(function()
            -- Intentar cargar la imagen real
            return love.graphics.newImage(imgData.src)
        end)
        
        if success then
            self.images[imgData.name] = img
            -- print("> Loaded: " .. imgData.name .. " from " .. imgData.src)
        else
            -- Crear imagen de placeholder si falla
            -- print("X Failed to load: " .. imgData.src .. " - using placeholder")
            self.images[imgData.name] = self:createPlaceholder(imgData.name)
        end
        
        self.loaded = self.loaded + 1
    end
    
    -- Llamar callback inmediatamente (podrías hacerlo asíncrono si quieres)
    if self.callback and self.loaded >= self.total then
        self.callback()
    end
end

function ImageManager:createPlaceholder(name)
    -- Crear una imagen de placeholder colorida
    local canvas = love.graphics.newCanvas(100, 100)
    love.graphics.setCanvas(canvas)
    
    -- Color basado en el nombre para debugging
    local r = (name:len() * 17) % 255 / 255
    local g = (name:len() * 23) % 255 / 255  
    local b = (name:len() * 29) % 255 / 255
    
    love.graphics.clear(r, g, b, 1)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(name:sub(1, 8), 10, 40)
    
    love.graphics.setCanvas()
    return canvas
end

function ImageManager:get(name)
    local img = self.images[name]
    if not img then
        print("⚠️ Image not found: " .. name)
        return self:createPlaceholder("MISSING:" .. name)
    end
    return img
end

function ImageManager:isLoaded()
    return self.loaded >= self.total
end

return ImageManager