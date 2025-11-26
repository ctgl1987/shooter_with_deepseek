local sti = require("lib.sti")
local Camera = require("lib.hump.camera")

local TestScreen = BaseScreen:new({
    name = "test",

    enter = function(self)

        love.physics.setMeter(16)
        self.world = love.physics.newWorld(0, 0, true) -- gravedad (0,0)
        self.map = sti("assets/maps/town1.lua", {"box2d"})

        self.map:box2d_init(self.world)

        self.camera = Camera(GAME_WIDTH, GAME_HEIGHT)
        -- self.camera:zoom(2)

        self.player = {
            body = love.physics.newBody(self.world, 100, 100, "dynamic"),
            shape = love.physics.newRectangleShape(16, 16),
            width = 16,
            height = 16,
            speed = 100
        }
        self.player.fixture = love.physics.newFixture(self.player.body, self.player.shape)

        self.map.layers["object_walls"].visible = false

    end,

    input = function(self, eventType, key)

    end,

    update = function(self, dt)

        -- Mover el CUERPO FÍSICO, no las coordenadas manuales
        if love.keyboard.isDown("w") then
            self.player.body:setLinearVelocity(0, -self.player.speed)
        elseif love.keyboard.isDown("s") then
            self.player.body:setLinearVelocity(0, self.player.speed)
        elseif love.keyboard.isDown("a") then
            self.player.body:setLinearVelocity(-self.player.speed, 0)
        elseif love.keyboard.isDown("d") then
            self.player.body:setLinearVelocity(self.player.speed, 0)
        else
            self.player.body:setLinearVelocity(0, 0) -- Parar cuando no hay input
        end

        self.world:update(dt)
        self.map:update(dt)

        -- Actualizar cámara para seguir al jugador
        if self.camera and self.player then
            local x, y = self.player.body:getPosition()
            self.camera:lockPosition(x, y)
        end
    end,

    render = function(self)

        self.camera:attach()

        
        love.graphics.setColor(1, 1, 1)
        -- local camX, camY = self.camera:position()
        -- self.map:draw(-camX, -camY) -- Ajustar por posición de cámara
        
        self.map:draw(0, 0)
        
        -- Dibujar objetos de la capa de objetos (para debug)
        love.graphics.setColor(1, 0, 0, 0.5) -- Rojo semitransparente
        for _, layer in ipairs(self.map.layers) do
            if layer.type == "objectgroup" then
                for _, obj in ipairs(layer.objects) do
                    if obj.shape == "rectangle" then
                        love.graphics.rectangle("line", obj.x, obj.y, obj.width, obj.height)
                    end
                end
            end
        end

        local x, y = self.player.body:getPosition()
        love.graphics.rectangle("fill", x - self.player.width / 2, y - self.player.height / 2, self.player.width,
            self.player.height)

        self.camera:detach()
    end
})

return TestScreen
