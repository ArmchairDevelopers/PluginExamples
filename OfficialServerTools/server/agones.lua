require "common/sdk"
local HttpClient = require "common/http_client"
local DebugLog = HttpClient.DebugLog

local hasServerInitialized = false
local isReserveLoopRunning = false
local playerCount = 0

local AgonesUri <const> = "127.0.0.1"
local AgonesPort <const> = math.tointeger(tonumber(os.getenv("AGONES_SDK_HTTP_PORT") or "0"))
local AgonesHealthInterval <const> = math.tointeger(tonumber(os.getenv("KYBER_AGONES_HEALTH_INTERVAL") or "10"))
local AgonesReserveDuration <const> = "60"
local AgonesReserveInterval <const> = 30

local AgonesBetaPrefix <const> = "v1beta1/"

if AgonesPort == 0 then
    return
end


local function callAgones(path, requestType, headers, body, responseCallback)
    DebugLog(("agones request: %s /%s"):format(tostring(requestType), path))
    HttpClient.call(AgonesUri, AgonesPort, path, requestType, headers, body, responseCallback)
end

local function callAgonesGeneric(path, requestType, responseCallback)
    callAgones(path, requestType, { ["Content-Type"] = "application/json" }, "{}", responseCallback)
end

-- Should only ever be called once, on module load
local function intervalHealthRequest()
    callAgonesGeneric("health", RequestType.Post)
    SetTimeout(intervalHealthRequest, AgonesHealthInterval)
end

local function intervalReserveRequest()
    if playerCount == 0 then
        isReserveLoopRunning = false
        return
    end

    callAgones("reserve", RequestType.Post, nil, {
        seconds = AgonesReserveDuration
    })

    SetTimeout(intervalReserveRequest, AgonesReserveInterval)
end

local function ensureReserved()
    if isReserveLoopRunning then
        return
    end

    isReserveLoopRunning = true
    intervalReserveRequest()
end

---@param player Player
local function addAgonesPlayer(player)
    playerCount = playerCount + 1
    ensureReserved()

    callAgones(AgonesBetaPrefix .. "lists/players:addValue", RequestType.Post, nil, {
        value = tostring(player.playerId)
    })
end

---@param player Player
local function removeAgonesPlayer(player)
    playerCount = math.max(0, playerCount - 1)

    callAgones(AgonesBetaPrefix .. "lists/players:removeValue", RequestType.Post, nil, {
        value = tostring(player.playerId)
    })
end

EventManager.Listen("Level:Loaded", function()
    if not hasServerInitialized then
        callAgonesGeneric("ready", RequestType.Post, function(response)
            if response.statusCode < 200 or response.statusCode > 299 then
                print("agones: ready failed: " .. response.statusCode)
            end
        end)

        intervalHealthRequest()
    end

    hasServerInitialized = true
end)

EventManager.Listen("ServerPlayer:Joined", addAgonesPlayer)
EventManager.Listen("ServerPlayer:Disconnect", removeAgonesPlayer)