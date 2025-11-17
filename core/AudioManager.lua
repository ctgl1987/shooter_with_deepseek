local AudioManager = {}

function AudioManager:init(soundList)

    print("> Initializing AudioManager...")
    self.sounds = {}
    self.muted = false
    self.soundList = soundList -- Guardar la lista para referencia

    for _, soundData in ipairs(soundList) do
        self:loadSound(soundData)
    end

    self:preloadAll()

    print("> AudioManager initialized: " .. #soundList .. " sounds.")
end

function AudioManager:loadSound(soundData)
    -- Usar el mismo pool size que en JavaScript: 10 por defecto
    local poolSize = soundData.pool or 10

    -- Determinar el tipo de fuente
    local sourceType = soundData.loop and "stream" or "static"

    if not self.sounds[soundData.name] then
        self.sounds[soundData.name] = {}
    end

    -- Crear el pool de sonidos (igual que en JS)
    for i = 1, poolSize do
        local success, sound = pcall(love.audio.newSource, soundData.src, sourceType)

        if success then
            sound:setVolume(soundData.volume or 0.5)
            sound:setLooping(soundData.loop or false)
            sound:setVolume(self.muted and 0 or (soundData.volume or 0.5))

            table.insert(self.sounds[soundData.name], sound)
        else
            print("Error loading sound: " .. soundData.src)
        end
    end

    -- print("> Cargado: " .. soundData.name .. " (pool: " .. poolSize .. ")")
end

function AudioManager:preloadAll()
    for name, pool in pairs(self.sounds) do
        for _, sound in ipairs(pool) do
            -- Precargar reproduciendo y parando inmediatamente
            sound:play()
            sound:stop()
            sound:seek(0)
        end
    end
end

function AudioManager:play(name)
    if self.muted then
        return nil
    end

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
                newSound:setVolume(soundData.volume or 0.5)
                newSound:setLooping(soundData.loop or false)
                newSound:setVolume(self.muted and 0 or (soundData.volume or 0.5))

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
    local newVolume = self.muted and 0 or 1

    for _, pool in pairs(self.sounds) do
        for _, sound in ipairs(pool) do
            sound:setVolume(newVolume)
        end
    end

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
