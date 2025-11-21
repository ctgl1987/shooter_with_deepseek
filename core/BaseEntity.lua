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
    entity.speed = p.speed or 1
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
    self:updateTasks(dt)
    
    self:emit("post-update")
end

function BaseEntity:render()
    self:emit("pre-render")

    --renderizar entidad si self.color no es transparente
    if self.color ~= DrawManager.colors.transparent then
        DrawManager:fillRect(self.x, self.y, self.width, self.height, {color = self.color})
    end
    
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

function BaseEntity:getTask(name)
    for i, task in ipairs(self.tasks) do
        if task.name == name then
            print("Found task: " .. name .. " at index " .. i)
            return task
        end
    end
    print("Task not found: " .. name)
    return nil
end

-- Sistema de tareas
function BaseEntity:addTask(task)
    for _, existingTask in pairs(self.tasks) do
        if existingTask.name == task.name then
            existingTask:onComplete()
            -- Si la tarea ya existe, reemplazamos
            print("Replaced existing task: " .. task.name)
            self.tasks[task.name] = task
            task:onStart(self)
            return
        end
    end
    self.tasks[task.name] = task
    task:onStart(self)
end

function BaseEntity:removeTask(name)
    local task = self.tasks[name]
    if task then
        task:onComplete()
        self.tasks[name] = nil
        print("Removed task: " .. name)
    end
end

function BaseEntity:updateTasks(dt)
    for name, task in pairs(self.tasks) do
        task:update(dt)
        if task:isComplete() then
            self:removeTask(name)
        end
    end
end

return BaseEntity