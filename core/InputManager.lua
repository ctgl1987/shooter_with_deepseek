local InputManager = {}

InputManager.currentContext = "menu"

InputManager.bindings = {
    menu = {
        up = { "up", "w", "button_dpup" },
        down = { "down", "s", "button_dpdown" },
        left = { "left", "a", "button_dpleft" },
        right = { "right", "d", "button_dpright" },
        select = { "return", "space", "button_a", "button_start" },
        back = { "escape", "button_b" }
    },
    pause = {
        up = { "up", "w", "button_dpup" },
        down = { "down", "s", "button_dpdown" },
        left = { "left", "a", "button_dpleft" },
        right = { "right", "d", "button_dpright" },
        select = { "return", "space", "button_a" },
        back = { "escape", "button_b", "button_start" }
    },
    game = {
        up = { "up", "w", "button_dpup" },
        down = { "down", "s", "button_dpdown" },
        left = { "left", "a", "button_dpleft" },
        right = { "right", "d", "button_dpright" },
        fire = { "space", "button_a" },
        bomb = { "b", "button_b" },
        pause = { "escape", "button_start" }
    }
}

function InputManager:setContext(context)
    self.currentContext = context
end

function InputManager:getActionForKey(key)
    -- print("Checking action for key: " .. key .. " in context: " .. self.currentContext)

    local keyBindings = self.bindings[self.currentContext]

    if not keyBindings then
        print("No key bindings found for context: " .. self.currentContext)
        return nil
    end

    for action, keys in pairs(keyBindings) do
        for _, k in ipairs(keys) do
            if k == key then
                -- print("Action for key '" .. key .. "' is '" .. action .. "'")
                return action
            end
        end
    end
    return nil
end

return InputManager
