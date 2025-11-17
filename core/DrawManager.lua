local DrawManager = {}

function DrawManager:init()
    -- Colores predefinidos
    self.colors = {
        white = { 1, 1, 1 },
        black = { 0, 0, 0 },
        red = { 1, 0, 0 },
        green = { 0, 1, 0 },
        blue = { 0, 0, 1 },
        yellow = { 1, 1, 0 },
        gray = { 0.5, 0.5, 0.5 },
        --more colors can be added here
        purple = { 0.5, 0, 0.5 },
        orange = { 1, 0.65, 0 },
        cyan = { 0, 1, 1 },
        magenta = { 1, 0, 1 }
    }
end

function DrawManager:setColor(color)
    if type(color) == "string" then
        if color:sub(1, 1) == "#" then
            -- Color hexadecimal
            local r = tonumber(color:sub(2, 3), 16) / 255
            local g = tonumber(color:sub(4, 5), 16) / 255
            local b = tonumber(color:sub(6, 7), 16) / 255
            local a = 1
            if #color == 9 then
                a = tonumber(color:sub(8, 9), 16) / 255
            end
            love.graphics.setColor(r, g, b, a)
            return
        end
        love.graphics.setColor(self.colors[color] or self.colors.white)
    elseif type(color) == "table" then
        love.graphics.setColor(unpack(color))
    else
        love.graphics.setColor(color)
    end
end

function DrawManager:drawLine(x1, y1, x2, y2, options)
    options = options or {}
    local color = options.color or "white"
    local width = options.width or 1

    self:setColor(color)
    love.graphics.setLineWidth(width)
    love.graphics.line(x1, y1, x2, y2)
end

function DrawManager:fillRect(x, y, w, h, options)
    options = options or {}
    local color = options.color or "white"
    local borderRadius = options.borderRadius or 0

    self:setColor(color)
    love.graphics.rectangle("fill", x, y, w, h, borderRadius)
end

function DrawManager:strokeRect(x, y, w, h, options)
    options = options or {}
    local color = options.color or "white"
    local lineWidth = options.lineWidth or 1
    local borderRadius = options.borderRadius or 0

    love.graphics.setLineWidth(lineWidth)
    self:setColor(color)
    love.graphics.rectangle("line", x, y, w, h, borderRadius)
end

function DrawManager:fillText(text, x, y, options)
    options = options or {}
    local color = options.color or "white"
    local size = options.size or 24
    local align = options.align or "left"
    local baseline = options.baseline or "top"
    local shadow = options.shadow ~= false

    -- Crear fuente con alta calidad
    -- local font = love.graphics.newFont("assets/fonts/slkscr.ttf",size)
    -- local font = love.graphics.newFont("assets/fonts/sprint-2.otf",size)
    -- local font = love.graphics.newFont("assets/fonts/BoldPixels.ttf",size)
    -- local font = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf",size)
    -- local font = love.graphics.newFont("assets/fonts/GNF.ttf", size)
    local font = love.graphics.newFont("assets/fonts/Nihonium113-Console.ttf", size)
    -- local font = love.graphics.newFont(size)
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

    -- Extraer alpha del color principal
    local mainAlpha = 1
    local shadowAlpha = 1

    -- Si el color tiene alpha, extraerlo
    if type(color) == "table" and #color >= 4 then
        mainAlpha = color[4] or 1
    elseif type(color) == "string" and color:sub(1, 5) == "rgba(" then
        -- Parsear rgba string si es necesario
        local r, g, b, a = color:match("rgba%((%d+),(%d+),(%d+),(%d+.?%d*)%)")
        if a then
            mainAlpha = tonumber(a) or 0
        end
    end

    -- Calcular alpha del shadow (usar el mismo alpha que el texto principal)
    shadowAlpha = mainAlpha

    -- Dibujar sombra (si está habilitada y tiene alpha > 0)
    if shadow and shadowAlpha > 0 then
        love.graphics.setColor(0, 0, 0, shadowAlpha)    -- Negro con alpha
        love.graphics.print(text, drawX + 1, drawY + 1) -- Offset de sombra
    end

    -- Dibujar texto principal (solo si tiene alpha > 0)
    if mainAlpha > 0 then
        self:setColor(color) -- Esto manejará el alpha del color principal
        love.graphics.print(text, drawX, drawY)
    end
end

function DrawManager:fillCircle(x, y, radius, options)
    options = options or {}
    local color = options.color or "white"

    self:setColor(color)
    love.graphics.circle("fill", x, y, radius)
end

function DrawManager:drawImage(img, dst, src, options)
    options = options or {}
    local rotate = options.rotate or 0
    local pulse = options.pulse or nil
    local alpha = options.alpha or 1
    local color = options.color or { 1, 1, 1 } -- Color por defecto: blanco

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

    love.graphics.setColor(color[1], color[2], color[3], alpha) -- Establecer color blanco con alpha

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
