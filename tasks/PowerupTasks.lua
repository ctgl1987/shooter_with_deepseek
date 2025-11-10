local TaskSystem = require("core.TaskSystem")

-- Shield Powerup
local ShieldPowerupTask = TaskSystem:create({
    name = "Shield",
    duration = 300,
    powerup = true,
    
    onStart = function(self, entity)
        self.entity = entity
        AudioManager:play("shield")
        
        self.renderListener = self.entity:on("pre-render", function()
            local pos = self.entity:center()
            DrawManager:fillCircle(pos.x, pos.y, self.entity.width * 1.5, {color = {0, 0.57, 1, 0.07}})
        end)
        
        self.damageListener = self.entity:on("damage-received", function(data)
            data.damage = 0
        end)
    end,
    
    onComplete = function(self)
        self.renderListener:remove()
        self.damageListener:remove()
    end
})

-- Triple Shot Powerup
local TripleShotPowerupTask = TaskSystem:create({
    name = "Triple Shot",
    duration = 450,
    powerup = true,
    
    onStart = function(self, entity)
        self.entity = entity
        self.bulletListener = self.entity:on("bullet-created", function(data)
            local baseBullet = data.bullets[1]
            
            -- Bala izquierda
            local leftBullet = BaseEntity:new({
                type = "bullet",
                owner = self.entity,
                width = ENTITY_SIZE * 0.05,
                height = ENTITY_SIZE * 0.2,
                color = baseBullet.color,
                damage = baseBullet.damage,
                vy = baseBullet.vy
            })
            leftBullet:centerTo({
                x = self.entity:center().x - 20,
                y = self.entity.y
            })
            leftBullet:addTask(EntityTasks.EntityMoveTask.create())
            table.insert(data.bullets, leftBullet)
            
            -- Bala derecha
            local rightBullet = BaseEntity:new({
                type = "bullet",
                owner = self.entity,
                width = ENTITY_SIZE * 0.05,
                height = ENTITY_SIZE * 0.2,
                color = baseBullet.color,
                damage = baseBullet.damage,
                vy = baseBullet.vy
            })
            rightBullet:centerTo({
                x = self.entity:center().x + 20,
                y = self.entity.y
            })
            rightBullet:addTask(EntityTasks.EntityMoveTask.create())
            table.insert(data.bullets, rightBullet)
        end)
    end,
    
    onComplete = function(self)
        self.bulletListener:remove()
    end
})

-- Fast Speed Powerup
local FastSpeedPowerupTask = TaskSystem:create({
    name = "Fast Speed",
    duration = 600,
    powerup = true,
    
    onStart = function(self, entity)
        self.entity = entity
        self.originalSpeed = self.entity.speed
        self.entity.speed = self.entity.speed * 1.5
    end,
    
    onComplete = function(self)
        self.entity.speed = self.originalSpeed
    end
})

-- Rapid Fire Powerup
local RapidFirePowerupTask = TaskSystem:create({
    name = "Rapid Fire",
    duration = 600,
    powerup = true,
    
    onStart = function(self, entity)
        self.entity = entity
        self.originalFireRate = self.entity.weapon.fireRate
        self.entity.weapon.fireRate = self.entity.weapon.fireRate / 2
    end,
    
    onComplete = function(self)
        self.entity.weapon.fireRate = self.originalFireRate
    end
})

-- Life Drain Powerup
local LifeDrainPowerupTask = TaskSystem:create({
    name = "Life Drain",
    duration = 600,
    powerup = true,
    
    onStart = function(self, entity)
        self.entity = entity
        self.bulletListener = self.entity:on("bullet-created", function(data)
            for _, bullet in ipairs(data.bullets) do
                bullet:on("bullet-hit", function(hitData)
                    self.entity:emit("hp-restored", {amount = hitData.damage})
                end)
            end
        end)
    end,
    
    onComplete = function(self)
        self.bulletListener:remove()
    end
})

-- Freeze Powerup
local FreezePowerupTask = TaskSystem:create({
    name = "Freeze",
    duration = 600,
    powerup = true,
    
    onStart = function(self, entity)
        self.entity = entity
        self.bulletListener = self.entity:on("bullet-created", function(data)
            for _, bullet in ipairs(data.bullets) do
                bullet:on("bullet-hit", function(hitData)
                    if hitData.target and not hitData.target.frozen then
                        hitData.target.frozen = true
                        hitData.target:addTask(PowerupTasks.FreezedTask.create())
                    end
                end)
            end
        end)
    end,
    
    onComplete = function(self)
        self.bulletListener:remove()
    end
})

-- Freezed Effect Task
local FreezedTask = TaskSystem:create({
    name = "Freezed",
    duration = 180,
    powerup = true,
    
    onStart = function(self, entity)
        self.entity = entity
        self.originalVx = self.entity.vx
        self.originalVy = self.entity.vy
        self.entity.vx = 0
        self.entity.vy = 0
        
        self.renderListener = self.entity:on("pre-render", function()
            local pos = self.entity:center()
            DrawManager:fillCircle(pos.x, pos.y, self.entity.width, {color = {0.43, 0.75, 0.99, 0.07}})
        end)
    end,
    
    onComplete = function(self)
        self.entity.vx = self.originalVx
        self.entity.vy = self.originalVy
        self.entity.frozen = false
        self.renderListener:remove()
    end
})

return {
    ShieldPowerupTask = ShieldPowerupTask,
    TripleShotPowerupTask = TripleShotPowerupTask,
    FastSpeedPowerupTask = FastSpeedPowerupTask,
    RapidFirePowerupTask = RapidFirePowerupTask,
    LifeDrainPowerupTask = LifeDrainPowerupTask,
    FreezePowerupTask = FreezePowerupTask,
    FreezedTask = FreezedTask
}