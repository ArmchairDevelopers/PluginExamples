local Timer = require "common/timer".Timer

-- This is the interval at which the bot balancer will run, in seconds.
local updateIntervalSeconds <const> = 5

-- This is the desired game density, which is the percentage of the maximum number of players
-- If it's 80%, and the maximum number of players is 8, then the desired number of players is 6.
-- This is used to determine how many bots should be added or removed.
--
-- We don't want to add too many bots, because a game completely full of bots is not fun,
-- and we want to leave room for human players to join.
local desiredGameDensity <const> = 0.8

-- Wether to tie the player balancer routine to if the current gamemode
-- is among the allowed gamemodes for the plugin's functionality. 
local playerBalancerTiedToWhitelistedGamemodes <const> = true

-- This is so we don't touch the player manager before it is actually constructed.
-- Set to true once Server:Init has fired
local hasServerInitialized = false

-- This table stores the max player counts of each loaded game mode. The engine's resource
-- loading system is intercepted to populate this table. When a level is loaded, we'll use
-- this data to determine the max player count of the game mode.
local gameModes = {}

-- This is current the game mode that we're balancing bots for.
local gameMode = nil

-- The gamemodes the balancer should be active for
local whitelistedGameModes = {
    "Mode1",
    "PlanetaryBattles",
    "IOISupremacyUnrestricted",
}



function IsGameModeWhitelisted(mode)
    for _, whitelistedMode in ipairs(whitelistedGameModes) do
        if whitelistedMode == mode then
            return true
        end
    end
    return false
end


function getTeamCounts()
    -- Count up the current human players on each team.
    local teamCounts = {0, 0}

    local players = PlayerManager.GetPlayers()
    for _, player in ipairs(players) do
        if player.isBot then
            goto continue
        end

        local team = player.team
        teamCounts[team] = (teamCounts[team] or 0) + 1
        ::continue::
    end

    return teamCounts
end


-- Get current player count of non ai
function getPlayerCount()
    -- Quick and dirty method of just adding up all the numbers from getTeamCounts()
    local teamCounts = getTeamCounts()
    return teamCounts[1] + teamCounts[2]
end


-- This function will be called every `updateIntervalSeconds` seconds.
function balanceBots()
    -- A level with a gamemode we're aware of is not currently loaded.
    if gameMode == nil then
        return
    end

    -- If you press the '~' key while in-game, and type AutoPlayers, you will see
    -- the settings that we're modifying here.
    local settings = Console.GetSettings("AutoPlayers")
    if settings == nil then
        print("AutoPlayers settings not found! Bot balancing disabled.")
        -- timer:cancel()
        return
    end

    -- Count up the current human players on each team.
    local teamCounts = getTeamCounts()

    -- Calculate how many bots we currently need on each team.
    local desiredPlayersPerTeam = math.floor(math.floor(gameMode.maxPlayers * desiredGameDensity) / 2)

    local neededBotsPerTeam = {}
    for team, count in pairs(teamCounts) do
        neededBotsPerTeam[team] = math.max(0, desiredPlayersPerTeam - count)
    end

    -- Apply these values to the AutoPlayers settings.
    function BalanceTeam(team, settingsVariable)
        local neededBots = neededBotsPerTeam[team]
        if settings[settingsVariable] == neededBots then
            return
        end

        settings[settingsVariable] = neededBots
        print(string.format("Balancing team %d: %d bots", team, neededBots))
    end

    BalanceTeam(1, "forceFillGameplayBotsTeam1")
    BalanceTeam(2, "forceFillGameplayBotsTeam2")
end

BotService = {
    elapsed = 0,

    update = function(self, deltaSecs)
        self.elapsed = self.elapsed + deltaSecs
        if self.elapsed >= updateIntervalSeconds then
            self.elapsed = self.elapsed - updateIntervalSeconds
            balanceBots()
        end
    end,
}

EventManager.Listen("Server:UpdatePre", BotService.update, BotService)

EventManager.Listen("Server:Init", function()
    hasServerInitialized = true
end)

-- A potential improvement would be to only run balanceBots
-- when a player joins or leaves the server, or when the game mode changes.
-- I'm leaving that as an exercise for the reader.
-- Timer.new(updateIntervalSeconds, balanceTeam)

-- This event is triggered when a partition is loaded.
-- A partition is a game file ('EBX') that can contain
-- any type of general game data. It's used for anything
-- from hero descriptions, to logic blueprints, to levels.
EventManager.Listen("ResourceManager:PartitionLoaded", function(name, instance)
    if instance.typeInfo.name ~= "GameModeInformationAsset" then
        return
    end

    gameModes[instance.gameModeId] = {
        name = instance.aurebeshGameModeName,
        maxPlayers = instance.numberOfPlayers,
    }
end)

function ResetBots()
    local settings = Console.GetSettings("AutoPlayers")
    if settings == nil then
        print("AutoPlayers settings not found! Bot balancing disabled.")
        return
    end

    settings.forceFillGameplayBotsTeam1 = 0
    settings.forceFillGameplayBotsTeam2 = 0
    gameMode = nil
end


function randomizeTeams()
    if not hasServerInitialized then
        return
    end

    local randomTeamTable = {}
    local playerCount = getPlayerCount()

    if playerCount < 2 then
        Console.Execute("Kyber.Broadcast **KYBER:** Skipped team shuffle. (More than 2 players required)")
        return
    end

    -- Fill randomTeamTable 
    for i = 1, playerCount - (playerCount // 2), 1 do
        table.insert(randomTeamTable, 1)
    end
    for i = (playerCount - (playerCount // 2)) + 1, playerCount, 1 do
        table.insert(randomTeamTable, 2)
    end

    -- Shuffles inputted table (https://stackoverflow.com/questions/35572435/how-do-you-do-the-fisher-yates-shuffle-in-lua)
    local function shuffleTable(t)
        for i = #t, 2, -1 do
            local j = math.random(i)
            t[i], t[j] = t[j], t[i]
        end
    end

    shuffleTable(randomTeamTable)

    -- Set teams
    local players = PlayerManager.GetPlayers()
    local i = 1
    for _, player in ipairs(players) do
        if player.isBot then
            goto continue
        end

        player:SetTeam(randomTeamTable[i])
        print(string.format("Debug: Put player '%s' on team '%d'", player.name, randomTeamTable[i]))
        i = i + 1
        ::continue::
    end
    
    -- Disabled message because of chat spam
    -- Console.Execute("Kyber.Broadcast Successfully randomized teams!")

end

-- This event is triggered when a level is loaded.
-- The game modes will have been loaded by this point,
-- so we can determine the max player count of the mode.
EventManager.Listen("Level:Loaded", function(levelName, gameModeId)
    if gameModes[gameModeId] == nil then
        print("Unknown game mode ID: " .. gameModeId)
        ResetBots()
        return
    end

    if not IsGameModeWhitelisted(gameModeId) then
        print("Game mode not whitelisted: " .. gameModes[gameModeId].name .. " (" .. gameModeId .. ")")
        ResetBots()
        return
    end

    gameMode = gameModes[gameModeId]
    print(string.format("Balancing bots for game mode '%s' with %d max players", gameMode.name, gameMode.maxPlayers))

    Console.Execute(string.format("Kyber.Broadcast **KYBER:** Bot balancing enabled with %.0f%% backfill capacity.", desiredGameDensity * 100))

    -- Setup for Kyber team balancing
    local kyberSettings = Console.GetSettings("Kyber")
    kyberSettings.disableTeamBalancing = true
    -- Extra ensurance
    local wsSettings = Console.GetSettings("Whiteshark")
    wsSettings.autoBalanceTeamsOnNeutral = false

    print("Disabled traditional team balancing in favor for Kyber team balancing.")

    -- Randomizing teams
    randomizeTeams()

end)

-- Team balancing

-- Finds the best fit team by looking at both team player counts
-- If equal, set team to first
function balancePlayer(player)
    local teamCounts = getTeamCounts()

    if teamCounts[1] > teamCounts[2] then 
        player:SetTeam(2) 
    else
        -- then teams are either equal (which we want to set to team 1) or
        -- Team 2 has more and we want to set to team 1
        player:SetTeam(1)
    end

    print(string.format("Balanced player '%s' to team %d.", player.name, player.team))
end


-- This event is triggered when a player joins the server.
-- We will determine the best team to set them to here
EventManager.Listen("Server:PlayerJoined", function(player)
    if player == nil then
        print("Given invalid player on Server:PlayerJoined")
        return
    end

    -- If the player balancer is not tied to whitelistedGameModes, pass through
    -- if it is tied, gameMode is only nil whenever the current gamemode is not a whitelisted one
    if playerBalancerTiedToWhitelistedGamemodes and gameMode == nil then
        return
    end

    balancePlayer(player)
end)
