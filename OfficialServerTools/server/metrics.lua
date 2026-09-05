require "common/sdk"

local requestRouter = require "server_router"

-- kyber_dedicated_server_avg_tick_delta_time{level_name="",mode_name="",player_count="",server_name="",group_id="",instance_id=""} <value>
-- kyber_dedicated_server_max_tick_delta_time{level_name="",mode_name="",player_count="",server_name="",group_id="",instance_id=""} <value>

local cache = {
    level_name = "",
    mode_name = "",
    player_count = "",
    server_name = "",
    group_id = "",
    instance_id = "",
}

---@type string
local latestAvgTickMessage

---@type string
local latestMaxTickMessage

---@param cacheObject table
---@param id string
---@param value any
---@return string
local function ConstructMessage(cacheObject, id, value)
    local s = id .. "{"
    local stringArray = {}
    for key, value in pairs(cacheObject) do
        table.insert(stringArray, key .. "=\"" .. value .. "\"")
    end
    s = s .. table.concat(stringArray, ",") .. "} " .. value
    return s
end

-- From BotBalancerPlugin
---@return integer[]
local function GetTeamCounts()
    -- Count up the current human players on each team.
    local teamCounts = { 0, 0 }

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
---@return integer
local function GetPlayerCount()
    -- Quick and dirty method of just adding up all the numbers from getTeamCounts()
    local teamCounts = GetTeamCounts()
    return teamCounts[1] + teamCounts[2]
end

local function GetResponseBody()
    return 
            latestAvgTickMessage .. "\n" ..
            latestMaxTickMessage
end

EventManager.Listen("Level:Loaded",
    ---@param level string
    ---@param mode string
    function(level, mode)
        cache.level_name = level
        cache.mode_name = mode

        -- Get server name
        cache.server_name = Console.GetSettings("Server").serverName or cache.server_name

        -- Get server metadata
        local metadata = os.getenv("KYBER_SERVER_META")
        if metadata ~= nil then
            local parts = string.split(metadata, ",")
            for _, part in ipairs(parts) do
                local kv = string.split(part, "=")
                if kv == nil or #kv == 0 then
                    goto continue
                end

                local key = string.lower(kv[1])
                local value = kv[2]
                if string.find(key, "group") then
                    cache.group_id = value
                elseif string.find(key, "instance") then
                    cache.instance_id = value
                end

                ::continue::
            end
        else
            print("Metadata env does not exist!! GroupId and InstanceId will not be set")
        end
    end
)

-- Send messages
EventManager.Listen("DedicatedServer:PerformanceStatsMessage",
    ---@param tps number
    ---@param avgTickTime number
    ---@param worstTickTime number
    function(tps, avgTickTime, worstTickTime)
        -- Update player count
        cache.player_count = GetPlayerCount()

        latestAvgTickMessage = ConstructMessage(cache, "kyber_dedicated_server_avg_tick_delta_time", avgTickTime)
        latestMaxTickMessage = ConstructMessage(cache, "kyber_dedicated_server_max_tick_delta_time", worstTickTime)
    end
)

ConsoleCommands = {
    commandQueryMetrics = function(args)
        print(GetResponseBody())
    end
}

-- For manual querying
Console.Register("Kyber", "QueryMetrics", "Run to have the latest server metrics logged.", ConsoleCommands,
    ConsoleCommands.commandQueryMetrics)

-- Handle metrics request
requestRouter:handle("GET", "/metrics", function(req)
    req:send(GetResponseBody())
end)
