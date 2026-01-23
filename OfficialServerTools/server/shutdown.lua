local SetTimeout = require "common/timer".SetTimeout

local requestRouter = require "server_router"

local function BroadcastMessage(message)
    Console.Execute("Kyber.Broadcast " .. message)
end

local function KickAll(message)
    local players = PlayerManager.GetPlayers()
    for _, player in ipairs(players) do
        if player.isBot then
            goto continue
        end

        player:Kick(message)
        ::continue::
    end
end

local function HandleShutdown(secondsLeft, broadcast)
    if secondsLeft <= 0 then
        KickAll("Server shutting down")
        SetTimeout(function()
            Console.Execute("Kyber.CrashGame")
        end, 5.0)
        return
    end

    if broadcast and (secondsLeft == 60 or secondsLeft == 45 or secondsLeft == 30 or secondsLeft == 15 or secondsLeft <= 10) then
        BroadcastMessage("Server is shutting down in " .. secondsLeft .. " second" .. (secondsLeft == 1 and "" or "s"))
    end

    SetTimeout(function()
        HandleShutdown(secondsLeft - 1, true)
    end, 1.0)
end

requestRouter:handle("GET", "/shutdown", function(req)
    local secondsLeft = tonumber(req.headers["x-seconds"])
    if secondsLeft == nil then
        return
    end

    local reason = req.headers["x-reason"]

    BroadcastMessage("SERVER REBOOT! " .. reason .. " (in " .. secondsLeft .. " seconds)")
    HandleShutdown(secondsLeft, false)
    
    SetTimeout(function()
        req:sendNoContent()
    end, secondsLeft + 2)
end)
