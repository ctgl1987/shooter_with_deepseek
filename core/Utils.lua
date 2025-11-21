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

function Utils.createTimer(ticks)
    return {
        duration = 0,
        start = function(self)
            self.duration = ticks
        end,
        update = function(self)
            if self.duration > 0 then
                self.duration = self.duration - 1
            end
        end,
        ready = function(self)
            return self.duration <= 0
        end,
        reset = function(self)
            self.duration = ticks
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
