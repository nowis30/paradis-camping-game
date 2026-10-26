-- Persistence gate independent of Roblox services, so failure/recovery is testable.
local PersistentPlayerData = {}

function PersistentPlayerData.new(options)
    local sessions = {}
    local api = {}

    function api.Reset(userId)
        sessions[userId] = nil
    end

    function api.ResetFailed(userId)
        local session = sessions[userId]
        if session and not session.loading and not session.loaded then
            sessions[userId] = nil
        end
    end

    function api.Load(userId)
        local existing = sessions[userId]
        if existing then
            while existing.loading do options.wait() end
            return existing.data, existing.loaded
        end

        local session = { loading = true, loaded = false }
        sessions[userId] = session
        local ok, value = false, "DataStore unavailable"
        if options.readOnly then
            ok, value = true, nil
        else
            for attempt = 1, options.attempts or 3 do
                ok, value = pcall(options.read, userId)
                -- nil means a genuinely new player; a read error never means nil.
                if ok and value ~= nil and type(value) ~= "table" then
                    ok, value = false, "Unexpected saved data type"
                end
                if ok then break end
                if attempt < (options.attempts or 3) then options.wait(attempt) end
            end
        end
        session.data = options.normalize(ok and value or options.defaults())
        session.loaded = ok
        session.loading = false
        if not ok and options.onLoadFailure then options.onLoadFailure(userId, value) end
        return session.data, session.loaded
    end

    function api.Save(userId, data)
        local session = sessions[userId]
        if not session or session.loading or not session.loaded then
            return false, "LOAD_FAILED"
        end
        -- A late save from an older connection must not overwrite a new session.
        if data ~= session.data then return false, "STALE_SESSION" end
        if options.readOnly then return true, "STUDIO_READ_ONLY" end
        local ok, err = pcall(options.write, userId, options.normalize(data))
        if not ok and options.onSaveFailure then options.onSaveFailure(userId, err) end
        if ok then return true end
        return false, "SAVE_FAILED"
    end

    return api
end

return PersistentPlayerData
