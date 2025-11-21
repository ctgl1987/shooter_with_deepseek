local DrawManager = {}

function DrawManager:init()
    -- Colores predefinidos
    self.colors = {
        white = { 1, 1, 1, 1 },
        black = { 0, 0, 0, 1 },
        red = { 1, 0, 0, 1 },
        green = { 0, 1, 0, 1 },
        blue = { 0, 0, 1, 1 },
        yellow = { 1, 1, 0, 1 },
        gray = { 0.5, 0.5, 0.5, 1 },
        --more colors can be added here
        purple = { 0.5, 0, 0.5, 1 },
        orange = { 1, 0.65, 0, 1 },
        cyan = { 0, 1, 1, 1 },
        magenta = { 1, 0, 1, 1 },
        transparent = { 0, 0, 0, 0 },
    }

    love.graphics.setDefaultFilter("nearest", "nearest")
end

-- Nueva función: parsear cualquier formato de color a tabla RGBA
function DrawManager:parseColor(color)
    -- Si ya es una tabla, retornarla (asegurando que tenga 4 componentes)
    if type(color) == "table" then
        -- Asegurar que tenga alpha
        if #color == 3 then
            return { color[1], color[2], color[3], 1 }
        elseif #color == 4 then
            return color
        else
            return { 1, 1, 1, 1 } -- Fallback a blanco
        end
    end
    
    -- Si es string hexadecimal
    if type(color) == "string" and color:sub(1, 1) == "#" then
        local hex = color:sub(2)
        local r, g, b, a
        
        if #hex == 6 then
            -- Formato #RRGGBB
            r = tonumber(hex:sub(1, 2), 16) / 255
            g = tonumber(hex:sub(3, 4), 16) / 255
            b = tonumber(hex:sub(5, 6), 16) / 255
            a = 1
        elseif #hex == 8 then
            -- Formato #RRGGBBAA
            r = tonumber(hex:sub(1, 2), 16) / 255
            g = tonumber(hex:sub(3, 4), 16) / 255
            b = tonumber(hex:sub(5, 6), 16) / 255
            a = tonumber(hex:sub(7, 8), 16) / 255
        else
            -- Formato inválido, fallback a blanco
            return { 1, 1, 1, 1 }
        end
        
        return { r, g, b, a }
    end
    
    -- Si es nombre de color predefinido
    if type(color) == "string" and self.colors[color] then
        return self.colors[color]
    end
    
    -- Fallback a blanco
    return { 1, 1, 1, 1 }
end

-- Función setColor mejorada
function DrawManager:setColor(color)
    local parsedColor = self:parseColor(color)
    love.graphics.setColor(parsedColor)
end

-- Función para obtener solo el componente alpha de un color
function DrawManager:getAlpha(color)
    local parsedColor = self:parseColor(color)
    return parsedColor[4] or 1
end

-- Resto de las funciones modificadas para usar parseColor...

function DrawManager:drawLine(x1, y1, x2, y2, options)
    options = options or {}
    local color = options.color or "#FFFFFF"
    local width = options.width or 1

    self:setColor(color)
    love.graphics.setLineWidth(width)
    love.graphics.line(x1, y1, x2, y2)
end

function DrawManager:fillRect(x, y, w, h, options)
    options = options or {}
    local color = options.color or "#FFFFFF"
    local borderRadius = options.borderRadius or 0

    self:setColor(color)
    love.graphics.rectangle("fill", x, y, w, h, borderRadius)
end

function DrawManager:strokeRect(x, y, w, h, options)
    options = options or {}
    local color = options.color or "#FFFFFF"
    local lineWidth = options.lineWidth or 1
    local borderRadius = options.borderRadius or 0

    love.graphics.setLineWidth(lineWidth)
    self:setColor(color)
    love.graphics.rectangle("line", x, y, w, h, borderRadius)
end

function DrawManager:fillText(text, x, y, options)
    options = options or {}
    local color = options.color or "#FFFFFF"
    local size = options.size or 24
    local align = options.align or "left"
    local baseline = options.baseline or "top"
    local shadow = options.shadow ~= false

    -- Crear fuente con alta calidad
    local font = love.graphics.newFont("assets/fonts/Nihonium113-Console.ttf", size)
    font:setFilter("linear", "linear", 4)
    love.graphics.setFont(font)

    -- Calcular dimensiones del texto
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    local descent = font:getDescent()

    -- Ajustar posición horizontal
    local drawX = x
    if align == "center" then
        drawX = x - textWidth / 2
    elseif align == "right" then
        drawX = x - textWidth
    end

    -- Ajustar posición vertical
    local drawY = y
    if baseline == "top" then
        drawY = y
    elseif baseline == "middle" then
        drawY = y - textHeight / 2
    elseif baseline == "bottom" then
        drawY = y - textHeight
    elseif baseline == "alphabetic" then
        drawY = y - (textHeight - descent)
    end

    -- ✅ NUEVO: Usar parseColor para obtener alpha correctamente
    local parsedColor = self:parseColor(color)
    local mainAlpha = parsedColor[4] or 1
    local shadowAlpha = mainAlpha  -- Mismo alpha para la sombra

    -- Dibujar sombra (si está habilitada y tiene alpha > 0)
    if shadow and shadowAlpha > 0 then
        love.graphics.setColor(0, 0, 0, shadowAlpha)    -- Negro con alpha
        love.graphics.print(text, drawX + 1, drawY + 1) -- Offset de sombra
    end

    -- Dibujar texto principal (solo si tiene alpha > 0)
    if mainAlpha > 0 then
        self:setColor(parsedColor) -- Usar el color ya parseado
        love.graphics.print(text, drawX, drawY)
    end
end

function DrawManager:fillCircle(x, y, radius, options)
    options = options or {}
    local color = options.color or "#FFFFFF"
    local alpha = options.alpha or 1

    self:setColor(color)
    love.graphics.circle("fill", x, y, radius)
end

function DrawManager:drawImage(img, dst, src, options)
    options = options or {}
    local rotate = options.rotate or 0
    local pulse = options.pulse or nil
    local alpha = options.alpha or 1
    local color = options.color or "#FFFFFF" -- Color por defecto: blanco con alpha

    -- ✅ NUEVO: Parsear el color y combinar con el alpha específico
    local parsedColor = self:parseColor(color)
    local finalAlpha = (parsedColor[4] or 1) * alpha  -- Combinar alpha del color con alpha de opciones

    -- Calcular dimensiones y escala base
    local imgWidth, imgHeight = img:getDimensions()
    local scaleX = dst.width / imgWidth
    local scaleY = dst.height / imgHeight

    -- Variables para efectos de transformación
    local pulseScaleX, pulseScaleY = scaleX, scaleY
    local drawX, drawY = dst.x + (dst.width / 2), dst.y + (dst.height / 2)
    local ox, oy = imgWidth * 0.5, imgHeight * 0.5

    -- Aplicar efecto pulse si está presente
    if pulse and pulse.amplitude and pulse.speed then
        local time = love.timer.getTime() -- Tiempo actual en segundos
        local scaleFactor = 1 + math.sin(time * pulse.speed) * pulse.amplitude

        -- Aplicar el escalado del pulse
        pulseScaleX = scaleX * scaleFactor
        pulseScaleY = scaleY * scaleFactor
    end

    -- ✅ NUEVO: Usar el color parseado con el alpha combinado
    love.graphics.setColor(parsedColor[1], parsedColor[2], parsedColor[3], finalAlpha)

    -- Dibujar la imagen con todas las transformaciones y alpha
    if src and src.x then
        local quad = love.graphics.newQuad(src.x, src.y, src.width, src.height, imgWidth, imgHeight)
        love.graphics.draw(img, quad, drawX, drawY, math.rad(rotate), pulseScaleX, pulseScaleY, ox, oy)
    else
        love.graphics.draw(img, drawX, drawY, math.rad(rotate), pulseScaleX, pulseScaleY, ox, oy)
    end

    -- Restaurar color
    love.graphics.setColor(1, 1, 1, 1)
end

return DrawManager