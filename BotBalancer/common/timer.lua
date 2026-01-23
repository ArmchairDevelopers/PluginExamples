TimerService = {
    timers = {},
    
    update = function(self, deltaSecs)
        for i = #self.timers, 1, -1 do
            local timer = self.timers[i]
            timer.elapsed = timer.elapsed + deltaSecs
            if timer.elapsed >= timer.interval then
                timer.elapsed = timer.elapsed - timer.interval
                timer.callback(timer)
                if not timer.running then
                    table.remove(self.timers, i)
                end
            end
        end
    end,
}

EventManager.Listen("Server:UpdatePre", TimerService.update, TimerService)

Timer = {}
Timer.__index = Timer

function Timer.new(interval, callback)
    local obj = setmetatable({}, self)
    obj.interval = interval
    obj.callback = callback
    obj.elapsed = 0
    obj.running = true
    table.insert(TimerService.timers, obj)
    return obj
end

function Timer:cancel()
    self.running = false
end

function SetTimeout(callback, delay)
    Timer:new(delay, function(timer)
        callback()
        timer:cancel()
    end)
end

return {
    Timer = Timer,
    SetTimeout = SetTimeout
}
