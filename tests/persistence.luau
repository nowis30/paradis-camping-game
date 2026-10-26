local PersistentPlayerData = require("../src/ServerScriptService/ParadisServer/PersistentPlayerData")
local passed = 0
local function test(name, run)
    run()
    passed += 1
    print("PASS", name)
end
local function make(read, write, extra)
    local options = {
        read = read, write = write or function() end,
        defaults = function() return {Cash = 10} end,
        normalize = function(value) return value or {Cash = 10} end,
        wait = function() end,
    }
    for key, value in pairs(extra or {}) do options[key] = value end
    return PersistentPlayerData.new(options)
end

test("a failed read can never overwrite existing data with defaults", function()
    local saved = {Cash = 9000}
    local reads, writes = 0, 0
    local service = make(function() reads += 1; error("outage") end, function(_, data) writes += 1; saved = data end)
    local data, ready = service.Load(42)
    assert(not ready and data.Cash == 10 and reads == 3)
    data.Cash = 5
    assert(not service.Save(42, data))
    assert(writes == 0 and saved.Cash == 9000)
end)

test("a successful missing record is a new player and may be saved", function()
    local persisted
    local service = make(function() return nil end, function(_, data) persisted = data.Cash end)
    local data, ready = service.Load(42)
    assert(ready and data.Cash == 10)
    data.Cash = 25
    assert(service.Save(42, data) and persisted == 25)
end)

test("transient failures retry before any fallback becomes visible", function()
    local reads = 0
    local service = make(function() reads += 1; if reads < 3 then error("throttled") end; return {Cash = 500} end)
    local data, ready = service.Load(42)
    assert(ready and data.Cash == 500 and reads == 3)
    assert(service.Load(42) == data and reads == 3)
end)

test("reconnection recovers the saved state and rejects an old session save", function()
    local available = false
    local writes = 0
    local service = make(function() if not available then error("outage") end; return {Cash = 500} end, function() writes += 1 end)
    local stale = service.Load(42)
    available = true
    service.ResetFailed(42)
    local current, ready = service.Load(42)
    assert(ready and current.Cash == 500)
    assert(not service.Save(42, stale) and writes == 0)
    assert(service.Save(42, current) and writes == 1)
end)

test("malformed saved values and unknown users fail closed", function()
    local service = make(function() return "corrupt" end)
    local data, ready = service.Load(42)
    assert(not ready and not service.Save(42, data))
    assert(not service.Save(123, {Cash = 0}))
end)

test("a quick reconnect preserves healthy progress while a save may be in flight", function()
    local reads = 0
    local service = make(function() reads += 1; return {Cash = 500} end)
    local data = service.Load(42)
    data.Cash = 550
    service.ResetFailed(42)
    assert(service.Load(42) == data and data.Cash == 550 and reads == 1)
end)

test("a failed write is reported and can be retried", function()
    local writable = false
    local service = make(function() return {Cash = 500} end, function() if not writable then error("outage") end end)
    local data = service.Load(42)
    assert(not service.Save(42, data))
    writable = true
    assert(service.Save(42, data))
end)

test("concurrent callers share one load and the same authoritative table", function()
    local reads = 0
    local service = make(function() reads += 1; coroutine.yield(); return {Cash = 500} end, nil, {wait = coroutine.yield})
    local first, second
    local a = coroutine.create(function() first = service.Load(42) end)
    local b = coroutine.create(function() second = service.Load(42) end)
    assert(coroutine.resume(a)); assert(coroutine.resume(b))
    assert(coroutine.resume(a)); assert(coroutine.resume(b))
    assert(first == second and first.Cash == 500 and reads == 1)
end)

test("Studio remains memory-only", function()
    local service = make(function() error("must not read") end, function() error("must not write") end, {readOnly = true})
    local data, ready = service.Load(42)
    assert(ready and service.Save(42, data))
end)
print(string.format("%d persistence tests passed", passed))
