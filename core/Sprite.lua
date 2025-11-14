local Sprite = {}

function Sprite:new(image, options)
    options = options or {}
    local sprite = {
        image = image,
        frameWidth = options.frames and (image:getWidth() / options.frames) or image:getWidth(),
        frameHeight = image:getHeight(),
        frame = 0,
        frameCounter = 0,
        frames = options.frames or 1,
        frameRate = options.frameRate or 10
    }
    
    setmetatable(sprite, {__index = Sprite})
    return sprite
end

function Sprite:update()
    self.frameCounter = self.frameCounter + 1
    if self.frameCounter >= self.frameRate then
        self.frameCounter = 0
        self.frame = (self.frame + 1) % self.frames
    end
end

function Sprite:render(bounds, options)
    if self.frames > 1 then
        local quad = love.graphics.newQuad(
            self.frame * self.frameWidth,
            0,
            self.frameWidth,
            self.frameHeight,
            self.image:getWidth(),
            self.image:getHeight()
        )
        DrawManager:drawImage(self.image, bounds, quad, options)
    else
        DrawManager:drawImage(self.image, bounds, nil, options)
    end
end

return Sprite