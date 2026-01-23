-- local Timer = require "common/timer".Timer

local DebugLog = function(s)
    if (os.getenv("KYBER_DEV_MODE") ~= nil) or ((os.getenv("KYBER_LOG_LEVEL") or ""):lower() == "debug") then
        print("[Debug] " .. s)
    end
end

-- <Settings>

local KickBanCountThreshold <const> = 99

local EnableKickBan <const> = false

-- </Settings>

local pluginPrefix <const> = "[HVVPlayground] "

table.contains = function(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

string.split = function(str, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

PluginService = {
    banPlayerVotes = {},
    bannedPlayers = {},
    banReasons = {},

    playerExist = function(self, playerName)
        local players = PlayerManager.GetPlayers()
        for _, player in ipairs(players) do
            if player.isBot then goto continue end

            if player.name:lower() == playerName:lower() then
                return true
            end
            
            ::continue::
        end

        return false
    end,

    getProperPlayerName = function(self, playerName)
        local players = PlayerManager.GetPlayers()
        for _, player in ipairs(players) do
            if player.isBot then goto continue end

            if player.name:lower() == playerName:lower() then
                return player.name
            end

            ::continue::
        end

        print("ERROR: Player does not exist.")
    end,

    -- Accessibility
    isPlayerBanned = function(self, player)
        return table.contains(PluginService.bannedPlayers, player.playerId)
    end,

    banPlayer = function(self, player, reason)
        table.insert(PluginService.bannedPlayers, player.playerId)
        self.banReasons[player.playerId] = reason
        self:executeBanKick(player)
    end,

    executeBanKick = function(self, player)
        player:Kick("You are banned from this server! Reason: " .. self.banReasons[player.playerId])
    end

}


EventManager.Listen("ServerPlayer:Join", function(player)
    if player == nil then
        DebugLog("[ERROR] Given invalid player on ServerPlayer:Join")
        return
    end

    if PluginService:isPlayerBanned(player) then
        PluginService:executeBanKick(player)
        return
    end
end)

EventManager.Listen("ServerPlayer:SendMessage", function(playerName, message)
    local player = PlayerManager.GetPlayer(playerName)
    if message:len() < 2 then return end
    local messageSplit = string.split(message)

    if #messageSplit <= 0 then return end
    if messageSplit[1]:len() < 3 then return end
    if messageSplit[1]:sub(1, 1) ~= '!' and messageSplit[1]:sub(1, 1) ~= '/' then return end

    local command = messageSplit[1]:lower():sub(2)

    -- A command is attempted to be executed; dont send to everyone
    EventManager.SetCancelled(true)

    if command == "swapteam" or command == "swap" or command == "st" then
        if player == nil then
            return
        end

        if not player.isSpawned then
            player:SetTeam((math.fmod(player.team, 2)) + 1)
            DebugLog(string.format("Swapped player %s to team %d", player.name, player.team))
        else 
            DebugLog("Player is spawned in; no swap.")
        end
    elseif EnableKickBan and command == "voteban" then
        if #messageSplit < 2 then return end
        local targetPlayerName = messageSplit[2]
        if not PluginService:playerExist(targetPlayerName) then
            -- Player does not exist; terminate
            return
        end
        targetPlayerName = PluginService:getProperPlayerName(targetPlayerName)
        local targetPlayer = PlayerManager.GetPlayer(targetPlayerName)

        PluginService.banPlayerVotes[targetPlayerName] = (PluginService.banPlayerVotes[targetPlayerName] or {})
        if table.contains(PluginService.banPlayerVotes[targetPlayerName], playerName) then 
            -- Player has already voted for this player to be banned.
            return 
        end
        table.insert(PluginService.banPlayerVotes[targetPlayerName], playerName);
        
        local votes = #PluginService.banPlayerVotes[targetPlayerName]
        if votes >= KickBanCountThreshold then
            -- Ban player officially
            PluginService:banPlayer(targetPlayer, "Vote banned.")
            Console.Execute(string.format("Kyber.Broadcast Player %s has been votebanned by %d people.", targetPlayerName,
            votes))
            return
        end

        DebugLog(string.format("Player %s voted for player %s, vote count = %d", playerName, targetPlayerName, votes))
        Console.Execute(string.format("Kyber.Broadcast Player %s has %d votes to be votebanned, needs %d. (!voteban <name>)", targetPlayerName, votes, KickBanCountThreshold))

    else
        return
    end

    -- A command was successfully executed

end)
