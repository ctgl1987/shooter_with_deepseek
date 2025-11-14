local Utils = {}

function Utils.collision(a, b)
    return a.x < b.x + b.width and a.x + a.width > b.x and a.y < b.y + b.height and a.y + a.height > b.y
end

function Utils.randomInt(min, max)
    return math.floor(math.random() * (max - min) + min)
end

function Utils.randomDouble(min, max)
    return math.random() * (max - min) + min
end

function Utils.randomItem(list)
    return list[math.random(1, #list)]
end

function Utils.values(tbl)
    local valores = {}
    for clave, valor in pairs(tbl) do
        valores[#valores + 1] = valor
    end
    return valores
end

function Utils.clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

function Utils.weightedRandom(items)
    local totalWeight = 0
    for _, item in ipairs(items) do
        totalWeight = totalWeight + item.weight
    end

    local random = math.random() * totalWeight
    local currentWeight = 0

    for _, item in ipairs(items) do
        currentWeight = currentWeight + item.weight
        if random < currentWeight then
            return item.item
        end
    end

    return items[#items].item
end

function Utils.getFps(dt)
    return 1 / dt
end

-- Crear fondo con desplazamiento
function Utils.createScrollingBackground(image, speed)
    local bg = BaseEntity:new({
        width = GAME_WIDTH,
        height = (image:getHeight() / image:getWidth()) * GAME_WIDTH,
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
        })
        -- Parte central
        DrawManager:drawImage(bg.image, {
            x = 0,
            y = bg.y,
            width = bg.width,
            height = bg.height
        })
        -- Parte inferior
        DrawManager:drawImage(bg.image, {
            x = 0,
            y = bg.y + bg.height,
            width = bg.width,
            height = bg.height
        })
    end)

    return bg
end

-- Crear barra de HP
function Utils.drawHpBar(params)
    local value = params.value
    local max = params.max
    local x = params.x
    local y = params.y
    local width = params.width or ENTITY_SIZE
    local backColor = params.backColor or "gray"
    local color = params.color or "green"

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
function Utils.createMenu(items)
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
                local color = (i == self.index) and "yellow" or "white"
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
function Utils.createScreenFlasher(color, duration)
    color = color or {1, 1, 1}
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

-- Crear arma de jugador
function Utils.createPlayerWeapon()
    return {
        baseFireRate = 20,
        fireRate = 20,
        current = 0,
        reload = function(self)
            self.current = 0
        end,
        update = function(self)
            if self.current < self.fireRate then
                self.current = self.current + 1
            end
        end,
        ready = function(self)
            return self.current >= self.fireRate
        end,
        reset = function(self)
            self.fireRate = self.baseFireRate
        end
    }
end

-- Crear atributo con modificadores
function Utils.makeAttribute(value)
    return {
        baseValue = value,
        modifiers = {},
        getValue = function(self)
            local total = self.baseValue
            for _, mod in pairs(self.modifiers) do
                total = total + mod
            end
            return total
        end,
        addModifier = function(self, name, value)
            self.modifiers[name] = value
        end,
        removeModifier = function(self, name)
            self.modifiers[name] = nil
        end
    }
end

function Utils.deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = Utils.deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

return Utils
