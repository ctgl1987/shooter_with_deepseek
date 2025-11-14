-- main.lua
function love.load()
    -- Configuración inicial
    love.window.setTitle("Zelda-like con Love2D")
    
    -- Jugador (círculo)
    player = {
        x = 400,
        y = 300,
        radius = 20,
        speed = 200,
        color = {0, 1, 0}  -- Verde
    }
    
    -- Enemigos (cuadrados)
    enemies = {
        {
            x = 200,
            y = 200,
            width = 30,
            height = 30,
            color = {1, 0, 0},  -- Rojo
            speed = 50
        },
        {
            x = 600,
            y = 400,
            width = 30,
            height = 30,
            color = {1, 0, 0},
            speed = 50
        }
    }
    
    -- Obstáculos (cuadrados)
    obstacles = {
        {x = 300, y = 250, width = 50, height = 50, color = {0.5, 0.5, 0.5}},
        {x = 500, y = 350, width = 50, height = 50, color = {0.5, 0.5, 0.5}}
    }
    
    -- Proyectiles
    projectiles = {}
    
    -- Cámara básica
    camera = {x = 0, y = 0}
    
    -- Estado del juego
    gameState = "playing"
end

function love.update(dt)
    if gameState == "playing" then
        -- Movimiento del jugador
        local dx, dy = 0, 0
        
        if love.keyboard.isDown("w", "up") then
            dy = -1
        elseif love.keyboard.isDown("s", "down") then
            dy = 1
        end
        
        if love.keyboard.isDown("a", "left") then
            dx = -1
        elseif love.keyboard.isDown("d", "right") then
            dx = 1
        end
        
        -- Normalizar movimiento diagonal
        if dx ~= 0 and dy ~= 0 then
            dx, dy = dx * 0.707, dy * 0.707
        end
        
        -- Nueva posición temporal
        local newX = player.x + dx * player.speed * dt
        local newY = player.y + dy * player.speed * dt
        
        -- Verificar colisiones con obstáculos
        local canMoveX = true
        local canMoveY = true
        for _, obstacle in ipairs(obstacles) do
            
            if checkCollisionCircleRectangle(newX, player.y, player.radius,
                                            obstacle.x, obstacle.y, obstacle.width, obstacle.height) then
                canMoveX = false
            end
            if checkCollisionCircleRectangle(player.x, newY, player.radius,
                                            obstacle.x, obstacle.y, obstacle.width, obstacle.height) then
                canMoveY = false
            end
        end
        
        -- Actualizar posición si no hay colisión
        if canMoveX then
            player.x = newX
        end
        if canMoveY then
            player.y = newY
        end
        
        -- Actualizar enemigos (movimiento simple hacia el jugador)
        for _, enemy in ipairs(enemies) do
            local angle = math.atan2(player.y - enemy.y, player.x - enemy.x)
            enemy.x = enemy.x + math.cos(angle) * enemy.speed * dt
            enemy.y = enemy.y + math.sin(angle) * enemy.speed * dt
        end
        
        -- Actualizar proyectiles
        for i = #projectiles, 1, -1 do
            local proj = projectiles[i]
            proj.x = proj.x + proj.dx * proj.speed * dt
            proj.y = proj.y + proj.dy * proj.speed * dt
            
            -- Verificar colisiones con enemigos
            for j = #enemies, 1, -1 do
                local enemy = enemies[j]
                if checkCollisionCircleRectangle(proj.x, proj.y, proj.radius,
                                               enemy.x, enemy.y, enemy.width, enemy.height) then
                    table.remove(enemies, j)
                    table.remove(projectiles, i)
                    break
                end
            end
            
            -- Eliminar proyectiles fuera de pantalla
            if proj.x < -100 or proj.x > 900 or proj.y < -100 or proj.y > 700 then
                table.remove(projectiles, i)
            end
        end
        
        -- Actualizar cámara para seguir al jugador
        camera.x = player.x - love.graphics.getWidth() / 2
        camera.y = player.y - love.graphics.getHeight() / 2
    end
end

function love.draw()
    -- Aplicar transformación de cámara
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)
    
    -- Dibujar obstáculos
    for _, obstacle in ipairs(obstacles) do
        love.graphics.setColor(obstacle.color)
        love.graphics.rectangle("fill", obstacle.x, obstacle.y, obstacle.width, obstacle.height)
    end
    
    -- Dibujar enemigos
    for _, enemy in ipairs(enemies) do
        love.graphics.setColor(enemy.color)
        love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)
    end
    
    -- Dibujar proyectiles
    for _, proj in ipairs(projectiles) do
        love.graphics.setColor(proj.color)
        love.graphics.circle("fill", proj.x, proj.y, proj.radius)
    end
    
    -- Dibujar jugador
    love.graphics.setColor(player.color)
    love.graphics.circle("fill", player.x, player.y, player.radius)
    
    love.graphics.pop()
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("WASD/Flechas: Moverse\nClick: Disparar\nEnemigos: " .. #enemies, 10, 10)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and gameState == "playing" then
        -- Crear proyectil
        local mouseX, mouseY = love.mouse.getPosition()
        local worldX = mouseX + camera.x
        local worldY = mouseY + camera.y
        
        local angle = math.atan2(worldY - player.y, worldX - player.x)
        
        table.insert(projectiles, {
            x = player.x,
            y = player.y,
            radius = 5,
            speed = 300,
            dx = math.cos(angle),
            dy = math.sin(angle),
            color = {1, 1, 0}  -- Amarillo
        })
    end
end

-- Funciones de colisión
function checkCollisionCircleRectangle(cx, cy, radius, rx, ry, rw, rh)
    -- Encontrar el punto más cercano en el rectángulo al círculo
    local closestX = math.max(rx, math.min(cx, rx + rw))
    local closestY = math.max(ry, math.min(cy, ry + rh))
    
    -- Calcular distancia
    local distanceX = cx - closestX
    local distanceY = cy - closestY
    
    return (distanceX * distanceX + distanceY * distanceY) < (radius * radius)
end

function checkCollisionRectangles(r1x, r1y, r1w, r1h, r2x, r2y, r2w, r2h)
    return r1x < r2x + r2w and
           r1x + r1w > r2x and
           r1y < r2y + r2h and
           r1y + r1h > r2y
end