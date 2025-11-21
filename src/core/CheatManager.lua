local CheatManager = {
    cheats = {},
    buffer = {},
    counter = 0
}

function CheatManager:register(sequence, callback)
    self.cheats[sequence] = {
        sequence = sequence,
        callback = callback,
        progress = 0
    }
end

function CheatManager:reset()
    self.buffer = {}
    self.counter = 0
end

function CheatManager:update(dt)
    self.counter = self.counter + 1
    if self.counter > 30 then
        self:reset()
    end
end

function CheatManager:input(key)
    print("CheatManager received key: " .. key)
    if #key > 1 then
        return
    end

    table.insert(self.buffer, key)
    self.counter = 0

    if #self.buffer > 20 then
        table.remove(self.buffer, 1)
    end

    for cheatName, cheat in pairs(self.cheats) do
        local seq = cheat.sequence
        local bufLen = #self.buffer

        if bufLen >= #seq then
            local recentInput = table.concat(self.buffer, "", bufLen - #seq + 1, bufLen)
            if recentInput == seq then
                cheat.callback(cheat)
                self:reset()
            end
        end
    end
end

function CheatManager:render()
    -- Opcional: mostrar buffer de cheats para debugging
    DrawManager:fillText("Cheat Buffer: " .. table.concat(self.buffer, ""), 10, GAME_HEIGHT - 40, {
        color = "#FFFF00",
        size = 14,
        baseline = "top"
    })
end

return CheatManager
