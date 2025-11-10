local KeyManager = {}

function KeyManager:init()
    self.keys = {}
end

function KeyManager:isDown(key)
    return self.keys[key] == true
end

function KeyManager:keypressed(key)
    if not key then return end
    self.keys[key] = true
end

function KeyManager:keyreleased(key)
    if not key then return end
    self.keys[key] = nil
end

return KeyManager