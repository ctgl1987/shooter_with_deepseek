local AudioManager = {}

function AudioManager:init(soundList)
    print("> Initializing AudioManager...")
    self.sounds = {}
    self.muted = false
    self.soundList = soundList -- Guardar la lista para referencia

    for _, soundData in ipairs(soundList) do
        soundData.volume = soundData.volume or 1 -- Valor por defecto si no está definido
        soundData.pool = soundData.pool or 10 -- Valor por defecto si no está definido
        soundData.loop = soundData.loop or false -- Valor por defecto si no está definido
        self:loadSound(soundData)
    end

    print("> AudioManager initialized: " .. #soundList .. " sounds.")
end

function AudioManager:loadSound(soundData)
    -- Usar el mismo pool size que en JavaScript: 10 por defecto
    local poolSize = soundData.pool

    -- Determinar el tipo de fuente
    local sourceType = soundData.loop and "stream" or "static"

    if not self.sounds[soundData.name] then
        self.sounds[soundData.name] = {}
    end

    -- Crear el pool de sonidos (igual que en JS)
    for i = 1, poolSize do
        local success, sound = pcall(love.audio.newSource, soundData.src, sourceType)

        -- si es distinto de nil, asignar valores por defecto
        
        if success then
            local volume = soundData.volume
            local loop = soundData.loop

            sound:setLooping(loop)
            sound:setVolume(volume)

            print("> Loaded sound: " .. soundData.name .. " (instance " .. i .. ") " .. sound:getVolume())

            table.insert(self.sounds[soundData.name], sound)
        else
            print("Error loading sound: " .. soundData.src)
        end
    end
end

function AudioManager:play(name)

    local pool = self.sounds[name]
    if not pool then
        print("❌ Sound not found: " .. name)
        return nil
    end

    -- Buscar un sonido que no esté reproduciéndose (igual que en JS)
    for _, sound in ipairs(pool) do
        if (not sound:isPlaying() and sound:tell("seconds") == 0) then
            sound:play()
            return sound
        end
    end

    -- Si todos están en uso, crear uno nuevo dinámicamente (como fallback)
    print("⚠️ Pool exhausted for: " .. name .. ", creating additional instance")
    return self:createNewSoundInstance(name)
end

function AudioManager:createNewSoundInstance(name)
    -- Buscar la configuración original del sonido
    for _, soundData in ipairs(self.soundList) do
        if soundData.name == name then
            local sourceType = soundData.loop and "stream" or "static"
            local success, newSound = pcall(love.audio.newSource, soundData.src, sourceType)

            if success then
                newSound:setVolume(soundData.volume)
                newSound:setLooping(soundData.loop)
                newSound:setVolume(soundData.volume)

                table.insert(self.sounds[name], newSound)
                newSound:play()
                return newSound
            end
        end
    end
    return nil
end

function AudioManager:playLoop(name)
    if self.muted then
        return nil
    end

    local pool = self.sounds[name]
    if pool and #pool > 0 then
        local sound = pool[1]
        sound:setLooping(true)
        sound:play()
        return sound
    end
end

function AudioManager:stop(name)
    local pool = self.sounds[name]
    if pool then
        for _, sound in ipairs(pool) do
            sound:stop()
            sound:seek(0)
        end
    end
end

function AudioManager:stopAll()
    for name, pool in pairs(self.sounds) do
        for _, sound in ipairs(pool) do
            sound:stop()
            sound:seek(0)
        end
    end
end

function AudioManager:setMute(mute)
    self.muted = mute

    love.audio.setVolume(self.muted and 0 or 1)
    
    -- Aplicar el volumen correcto según el estado de mute
    -- for _, soundData in ipairs(self.soundList) do
    --     local pool = self.sounds[soundData.name]
    --     if pool then
    --         local targetVolume = self.muted and 0 or soundData.volume
            
    --         for _, sound in ipairs(pool) do
    --             sound:setVolume(targetVolume)
    --         end
    --     end
    -- end

    print(self.muted and "X Audio muted" or "+ Audio unmuted")
end

function AudioManager:toggleMute()
    self:setMute(not self.muted)
end

function AudioManager:isMuted()
    return self.muted
end

-- Función para debug: mostrar estado de los pools
function AudioManager:debugPools()
    print("=== DEBUG AUDIO POOLS ===")
    for name, pool in pairs(self.sounds) do
        local playing = 0
        local available = 0

        for _, sound in ipairs(pool) do
            if sound:isPlaying() then
                playing = playing + 1
            else
                available = available + 1
            end
        end

        print(name .. ": " .. playing .. " playing, " .. available .. " available (total: " .. #pool .. ")")
    end
    print("=========================")
end

return AudioManager