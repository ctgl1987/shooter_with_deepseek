local BaseEntity = {}
BaseEntity.__index = BaseEntity

function BaseEntity:new(p)
    p = p or {}
    local entity = setmetatable({}, BaseEntity)
    
    -- Propiedades base
    entity.type = p.type or "entity"
    entity.x = p.x or 0
    entity.y = p.y or 0
    entity.width = p.width or 32
    entity.height = p.height or 32
    entity.vx = p.vx or 0
    entity.vy = p.vy or 0
    entity.friction = p.friction or 1
    entity.acceleration = p.acceleration or 1
    entity.color = p.color or {1, 1, 1}
    entity.dead = p.dead or false
    entity.hp = p.hp or 1
    entity.maxHp = p.maxHp or 1
    
    -- Sistema de eventos
    entity.events = {}
    
    -- Sistema de tareas
    entity.tasks = {}
    
    -- Propiedades adicionales
    for k, v in pairs(p) do
        if entity[k] == nil then
            entity[k] = v
        end
    end
    
    return entity
end

function BaseEntity:update(dt)
    self:emit("pre-update")
    
    -- Actualizar tareas
    for i = #self.tasks, 1, -1 do
        local task = self.tasks[i]
        task:update(dt)
        if task:isComplete() then
            table.remove(self.tasks, i)
        end
    end
    
    self:emit("post-update")
end

function BaseEntity:render()
    self:emit("pre-render")
    DrawManager:fillRect(self.x, self.y, self.width, self.height, {color = self.color})
    self:emit("post-render")
end

function BaseEntity:bounds(options)
    options = options or {}
    local scale = options.scale or 1
    
    return {
        x = self.x - (self.width * (scale - 1)) / 2,
        y = self.y - (self.height * (scale - 1)) / 2,
        width = self.width * scale,
        height = self.height * scale
    }
end

function BaseEntity:center()
    return {
        x = self.x + (self.width / 2),
        y = self.y + (self.height / 2)
    }
end

function BaseEntity:centerTo(pos)
    if pos.x then
        self.x = pos.x - (self.width / 2)
    end
    if pos.y then
        self.y = pos.y - (self.height / 2)
    end
end

function BaseEntity:bottom()
    return self.y + self.height
end

function BaseEntity:right()
    return self.x + self.width
end

-- Sistema de eventos
function BaseEntity:on(event, callback)
    if not self.events[event] then
        self.events[event] = {}
    end
    table.insert(self.events[event], callback)
    
    return {
        remove = function()
            for i, cb in ipairs(self.events[event]) do
                if cb == callback then
                    table.remove(self.events[event], i)
                    break
                end
            end
        end
    }
end

function BaseEntity:emit(event, data)
    data = data or {}
    if self.events[event] then
        for _, callback in ipairs(self.events[event]) do
            callback(data)
        end
    end
end

-- Sistema de tareas
function BaseEntity:addTask(task)
    for i, existingTask in ipairs(self.tasks) do
        if existingTask.name == task.name then
            existingTask:reset()
            return
        end
    end
    table.insert(self.tasks, task)
    task:onStart(self)
end

function BaseEntity:removeTask(name)
    for i, task in ipairs(self.tasks) do
        if task.name == name then
            task:onComplete()
            table.remove(self.tasks, i)
            break
        end
    end
end

function BaseEntity:updateTasks(dt)
    for i = #self.tasks, 1, -1 do
        local task = self.tasks[i]
        task:update(dt)
        if task:isComplete() then
            table.remove(self.tasks, i)
        end
    end
end

return BaseEntity