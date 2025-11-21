local UI = {}

-- Crear fondo con desplazamiento
function UI.createScrollingBackground(image, options)
    options = options or {}
    local speed = options.speed or 0
    local alpha = options.alpha or 1

    local width = 0
    local height = 0

    if image:getWidth() < GAME_WIDTH then
        width = GAME_WIDTH
        height = (image:getHeight() / image:getWidth()) * GAME_WIDTH
    else
        width = image:getWidth()
        height = image:getHeight()
    end

    local bg = BaseEntity:new({
        width = width,
        height = height,
        image = image,
        vy = speed
    })

    bg:addTask(EntityTasks.EntityMoveTask.create())

    bg:on("post-update", function()
        if bg.y >= bg.height then
            bg.y = 0
        end
    end)

    bg:on("post-render", function()
        -- Parte superior
        DrawManager:drawImage(bg.image, {
            x = 0,
            y = bg.y - bg.height,
            width = bg.width,
            height = bg.height
        }, nil, {
            alpha = alpha
        })
        -- Parte central
        DrawManager:drawImage(bg.image, {
            x = 0,
            y = bg.y,
            width = bg.width,
            height = bg.height
        }, nil, {
            alpha = alpha
        })
        -- Parte inferior
        DrawManager:drawImage(bg.image, {
            x = 0,
            y = bg.y + bg.height,
            width = bg.width,
            height = bg.height
        }, nil, {
            alpha = alpha
        })
    end)

    return bg
end

-- Crear barra de HP
function UI.drawHpBar(params)
    local value = params.value
    local max = params.max
    local x = params.x
    local y = params.y
    local width = params.width or ENTITY_SIZE
    local backColor = params.backColor or "#777777"
    local color = params.color or "#00FF00"

    if value < 0 then
        value = 0
    end

    local w = width
    local h = ENTITY_SIZE * 0.1

    -- Fondo (igual que en JS)
    DrawManager:fillRect(x, y - h * 2, w, h, {
        color = backColor
    })

    local percent = (value * w / max)

    -- Barra de vida (igual que en JS)
    DrawManager:fillRect(x, y - h * 2, percent, h, {
        color = color
    })
end

-- Crear sistema de menú
function UI.createMenu(items)
    return {
        items = items,
        index = 1,
        input = function(self, eventType, key)
            if eventType == "keydown" then
                if key == "up" then
                    AudioManager:play("menu")
                    self.index = self.index - 1
                    if self.index < 1 then
                        self.index = #self.items
                    end
                elseif key == "down" then
                    AudioManager:play("menu")
                    self.index = self.index + 1
                    if self.index > #self.items then
                        self.index = 1
                    end
                elseif key == "select" then
                    local item = self.items[self.index]
                    if item.action then
                        item.action()
                        AudioManager:play("menu")
                    end
                end
            end
        end,
        render = function(self, y)

            local startY = y - ((#self.items - 1) * 30) * 0.5
            for i, item in ipairs(self.items) do
                local color = (i == self.index) and "#FFFF00" or "#FFFFFF"

                DrawManager:fillText(item.name(), GAME_WIDTH * 0.5, startY + (i * 40), {
                    size = 30,
                    color = color,
                    align = "center"
                })
            end
        end
    }
end

-- Crear flash de pantalla
function UI.createScreenFlasher(color, duration)
    color = color or "#FFFFFF"
    duration = duration or 10

    return {
        duration = 0,
        stop = function(self)
            self.duration = 0
        end,
        start = function(self)
            self.duration = duration
        end,
        update = function(self)
            if self.duration > 0 then
                self.duration = self.duration - 1
            end
        end,
        render = function(self)
            if self.duration <= 0 then
                return
            end
            DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, {
                color = color
            })
        end
    }
end

return UI
