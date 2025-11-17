local ImageManager = {}

function ImageManager:init(imageList)
    print("> Initializing ImageManager...")
    self.images = {}
    self.queue = imageList
    self.loaded = 0
    self.total = #imageList
    self.callback = nil
    self.isLoading = false
    self.progress = 0
    self.currentName = nil
    
    -- Channels para comunicación con el thread
    self.commandChannel = love.thread.getChannel("image_manager_cmd")
    self.progressChannel = love.thread.getChannel("image_manager_progress")
    
    -- Código del thread mejorado
    self.threadCode = [[
        local commandChannel = love.thread.getChannel("image_manager_cmd")
        local progressChannel = love.thread.getChannel("image_manager_progress")
        
        -- Función para simular delay sin love.timer
        local function simulateWork()
            local result = 0
            for i = 1, 5000 do  -- Ajusta este número para cambiar la velocidad
                result = result + math.sqrt(i) * math.sin(i)
            end
            return result
        end
        
        while true do
            local command = commandChannel:demand()
            
            if command and command.type == "load_images" then
                local imageList = command.images
                local total = #imageList
                local batchSize = command.batchSize or 1  -- Imágenes por lote
                
                for i = 1, total, batchSize do
                    local batchEnd = math.min(i + batchSize - 1, total)
                    
                    for j = i, batchEnd do
                        local imgData = imageList[j]
                        progressChannel:push({
                            type = "progress",
                            name = imgData.name,
                            src = imgData.src,
                            current = j,
                            total = total
                        })
                        
                        -- Simular trabajo
                        simulateWork()
                    end
                end
                
                progressChannel:push({type = "complete"})
                break
                
            elseif command and command.type == "stop" then
                break
            end
        end
    ]]
end

function ImageManager:load(callback, batchSize)
    if self.isLoading then
        print("> ImageManager is already loading!")
        return
    end
    
    if self.total == 0 then
        print("> No images to load!")
        if callback then callback() end
        return
    end
    
    print("> Loading images in background... Total: " .. self.total)
    
    self.callback = callback
    self.isLoading = true
    self.loaded = 0
    self.progress = 0
    
    -- Crear e iniciar thread
    self.thread = love.thread.newThread(self.threadCode)
    self.thread:start()
    
    -- Enviar comando de carga al thread
    self.commandChannel:push({
        type = "load_images",
        images = self.queue,
        batchSize = batchSize or 1
    })
end

-- El resto de las funciones se mantienen igual...

function ImageManager:update()
    if not self.isLoading then return end
    
    -- Procesar mensajes del thread
    local message = self.progressChannel:pop()
    if message then
        if message.type == "progress" then
            -- Cargar la imagen real en el hilo principal
            local success, img = pcall(function()
                return love.graphics.newImage(message.src)
            end)

            if success then
                self.images[message.name] = img
                print("> Loaded: " .. message.name .. " from " .. message.src)
            else
                -- Crear imagen de placeholder si falla
                print("X Failed to load: " .. message.src .. " - using placeholder")
                self.images[message.name] = self:createPlaceholder(message.name)
            end

            -- ACTUALIZAR currentName (esto es importante)
            self.currentName = message.name
            self.loaded = self.loaded + 1
            self.progress = self.loaded / self.total
            
            -- QUITA este delay porque puede bloquear la actualización visual
            -- local start_time = love.timer.getTime()
            -- while love.timer.getTime() - start_time < 0.01 do end
            
        elseif message.type == "complete" then
            self.isLoading = false
            self.progress = 1.0
            self.currentName = "Complete!"  -- Mensaje final
            print("> ImageManager completed: " .. self.loaded .. " images loaded.")
            
            if self.callback then
                self.callback()
            end
            
            -- Limpiar
            self.commandChannel:push({type = "stop"})
        end
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
    return self.loaded >= self.total and not self.isLoading
end

function ImageManager:loading()
    return self.isLoading
end

function ImageManager:getProgress()
    return self.progress
end

function ImageManager:getLoadedCount()
    return self.loaded
end

function ImageManager:getTotalCount()
    return self.total
end

function ImageManager:getCurrentName()
    return self.currentName
end

-- Detener la carga si es necesario
function ImageManager:stop()
    if self.thread and self.thread:isRunning() then
        self.commandChannel:push({type = "stop"})
        self.isLoading = false
        print("> ImageManager loading stopped")
    end
end

return ImageManager