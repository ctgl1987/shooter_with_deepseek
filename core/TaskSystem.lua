local TaskSystem = {}

function TaskSystem:create(p)
    p = p or {}
    
    local Task = {}
    Task.__index = Task
    
    function Task:new()
        local task = setmetatable({}, Task)
        task.name = p.name or "task"
        task.powerup = p.powerup or false
        task.duration = p.duration or 60
        task.time = task.duration
        task.onStart = p.onStart or function() end
        task.onUpdate = p.onUpdate or function() end
        task.onComplete = p.onComplete or function() end
        return task
    end
    
    function Task:isComplete()
        return self.time <= 0
    end
    
    function Task:update(dt)
        self:onUpdate(dt)
        
        if self.duration ~= math.huge then
            self.time = self.time - 1
            
            if self:isComplete() then
                self:onComplete()
            end
        end
    end
    
    function Task:reset()
        self.time = self.duration
    end
    
    return {
        create = function() return Task:new() end,
        name = p.name
    }
end

return TaskSystem