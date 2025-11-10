local FSM = {}
FSM.__index = FSM

function FSM:new(name)
    local fsm = setmetatable({}, FSM)
    fsm.name = name or "default"
    fsm.states = {}
    fsm.current = {}
    return fsm
end

function FSM:add(name, state)
    self.states[name] = state
    state.name = name
end

function FSM:change(name, data)
    local state = self.states[name]
    if not state then
        print("Error: No state found: " .. name)
        return
    end
    
    -- Salir del estado actual
    for _, currentState in ipairs(self.current) do
        if currentState.exit then
            currentState:exit()
        end
    end
    
    self.current = {state}
    
    if state.enter then
        state:enter(data or {})
    end
end

function FSM:push(name, data)
    local state = self.states[name]
    if not state then
        print("Error: No state found: " .. name)
        return
    end
    
    table.insert(self.current, 1, state)
    
    if state.enter then
        state:enter(data or {})
    end
end

function FSM:pop()
    if #self.current <= 1 then return end
    
    local state = table.remove(self.current, 1)
    if state.exit then
        state:exit()
    end
end

function FSM:update(dt)
    if #self.current == 0 then return end
    if self.current[1].update then
        self.current[1]:update(dt)
    end
end

function FSM:render()
    for i = #self.current, 1, -1 do
        if self.current[i].render then
            self.current[i]:render()
        end
    end
end

function FSM:input(eventType, key, realKey)
    if #self.current == 0 then return end
    if self.current[1].input then
        self.current[1]:input(eventType, key, realKey)
    end
end

return FSM