require "common/sdk"

local debugMode = os.getenv("KYBER_DEV_MODE") ~= nil
local DebugLog = function(s)
    if (debugMode) or ((os.getenv("KYBER_LOG_LEVEL") or ""):lower() == "debug") then
        print("[Debug] " .. s)
    end
end

local enum = function(keys)
    local Enum = {}
    for i, value in ipairs(keys) do
        Enum[value] = i
    end
    return Enum
end

RequestType = enum
{
    "Post",
    "Get",
    "Delete",
    "Put",
    "Patch",
    "Options",
    "Head"
}

local __requestTypeToString <const> = {
	[RequestType.Post] = "Post",
	[RequestType.Get] = "Get",
	[RequestType.Delete] = "Delete",
	[RequestType.Put] = "Put",
	[RequestType.Patch] = "Patch",
	[RequestType.Options] = "Options",
	[RequestType.Head] = "Head",
}

local function RequestTypeToString(value)
    if type(value) == "number" then
        return __requestTypeToString[value]
    end
    return value
end

local function parseHttpResponse(request)
    local version, statusCode, statusName = request:match("^(HTTP/%d%.%d)%s+(%d%d%d)%s+(.-)\r?\n")
    if not version or not statusCode or not statusName then
        return nil, "Invalid HTTP response line"
    end

    local headers = {}
    local bodyStart = request:find("\r\n\r\n")
    local headersPart = request:sub(#version + #statusCode + #statusName + 4, bodyStart and bodyStart - 1 or #request)

    for line in headersPart:gmatch("[^\r\n]+") do
        local key, value = line:match("^(.-):%s*(.*)$")
        if key and value then
            headers[key] = value
        end
    end

    local body = bodyStart and request:sub(bodyStart + 4) or ""
    local statusCode = math.tointeger(tonumber(statusCode))

    return {
        statusCode = statusCode,
        statusName = statusName,
        headers = headers,
        body = body
    }
end


---@class HttpClient
---@field socket WinSocket
---@field responseCallback function()
---@field connectionReady boolean 
---@field outData string 
HttpClient = {}
HttpClient.__index = HttpClient

-- Efficient array indexing while iterating through them. In HttpClientManager.Update() we do not care for the index
-- and we just want them in the list; this is the best way to remove them if we want the client removed.
-- Source - https://stackoverflow.com/a/53038524
-- Posted by Mitch McMabers, modified by community. See post 'Timeline' for change history
-- Retrieved 2026-07-26, License - CC BY-SA 4.0
function ArrayRemove(t, fnKeep)
    local j, n = 1, #t;

    for i = 1, n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end

HttpClientManager = {
    ---@type HttpClient[]
    clients = {},

    Update = function(self, deltaSecs)
        --print("Active clients: " .. #self.clients)
        ArrayRemove(self.clients, function(clientsArray, i, _)
            local client = clientsArray[i]
            if not client.connectionReady then
                local status = client.socket:PollConnectionStatus()
                -- 0 = Pending
                -- 1 = Ready
                -- 2 = Failure

                if status == 0 then
                    goto continue
                elseif status == 2 then
                    -- Remove, its failed
                    print("Failed to fulfill an outgoing client request! (enable debug logs to see indepth)")
                    DebugLog("Failed to fulfill request: " .. client.outData)
                    client.socket:Close()
                    return false
                end

                if status ~= 1 then
                    print("Recieved unknown polling status code: " .. status)
                    client.socket:Close()
                    return false
                end

                -- check if the socket is usable and we have recieved no errors
                local isUsable = client.socket:IsOutgoingConnectionUsable()
                if not isUsable then
                    print(
                        "Got socket that completed timeout phase yet errored. Terminating processing on client")
                    client.socket:Close()
                    return false
                end

                client.connectionReady = true
                -- Do send data
                client.socket:Send(client.outData)

                DebugLog("Successfully sent data!")

                -- Pass since its pointless to expect the socket to have recieved any data immediately
                goto continue
            end

            -- Encapsulate so continue can be jumped to without worry of preceeding locals being out of scope 
            do
                local data = client.socket:Recv(2048)
                if data == nil then
                    goto continue
                end

                if #data == 0 then
                    DebugLog("Client disconnected")
                    client.socket:Close()
                    return false
                else
                    local response, err = parseHttpResponse(data)
                    if not response then
                        print("Failed to parse HTTP response: " .. err)
                        goto continue
                    end

                    if client.responseCallback then
                        local success, error = pcall(client.responseCallback, response)
                        if not success then
                            print("HttpClient response callback failure: " .. error)
                        end
                    end
                end
            end

            ::continue::
            return true
        end)
    end,

    AddClient = function(self, client)
        table.insert(self.clients, client)
    end,

    -- FreeClient = function(self, client)
    --     table.remove(self.clients, client)
    -- end
}

EventManager.Listen("Server:UpdatePre", HttpClientManager.Update, HttpClientManager)


local function constructHttpRequest(requestType, path, headers, data)
    local headerLines = {}
    for key, value in pairs(headers) do
        if type(key) == "number" then
            table.insert(headerLines, tostring(value))
        else
            table.insert(headerLines, key .. ": " .. tostring(value))
        end
    end

    return string.upper(requestType) .. " /" .. path .. " HTTP/1.1\r\n" ..
        table.concat(headerLines, "\r\n") ..
        "\r\n\r\n" ..
        data
end

function checkIsIpv4(str)
    if type(str) ~= "string" then return false end

    local p = "(%d+)%.(%d+)%.(%d+)%.(%d+)"
    local o1, o2, o3, o4 = str:match("^" .. p .. "$")

    if not o1 then return false end

    local octets = { tonumber(o1), tonumber(o2), tonumber(o3), tonumber(o4) }
    for _, octet in ipairs(octets) do
        if octet < 0 or octet > 255 then
            return false
        end
    end

    return true
end

local function call(uri, port, path, requestType, headers, body, responseCallback)
    local obj = setmetatable({}, HttpClient)
    obj.socket = SocketManager.CreateConnect(uri, port)
    obj.responseCallback = responseCallback
    if obj.socket == nil then
        print("Failed to create socket")
        return nil
    end

    headers = headers or {}
    headers["Connection"] = headers["Connection"] or "close"
    local requestTypeStr = RequestTypeToString(requestType)
    local bodyStr = body
    if not headers["Content-Type"] then
        if type(body) == "table" then
            headers["Content-Type"] = "application/json"
            bodyStr = json.encode(body)
        else
            headers["Content-Type"] = "text/plain"
        end
    end
    headers["Host"] = headers["Host"] or (uri .. ":" .. tostring(port))
    headers["Content-Length"] = #bodyStr

    obj.connectionReady = false
    obj.outData = constructHttpRequest(requestTypeStr, path, headers, bodyStr)
    HttpClientManager:AddClient(obj)
    DebugLog("HttpClient sent request of type " ..
        requestTypeStr .. " with headers " .. json.encode(headers) .. " and body \"" .. bodyStr .. "\"")
    return obj
end

local function callGenericCallback(uri, port, path, requestType, headers, body)
    return call(uri, port, path, requestType, headers or {}, body or "", function(response)
        if response.statusCode < 200 or response.statusCode > 299 then
            error("Response had a non-2XX status code: " .. response.statusCode .. " " .. response.statusName)
        end
        DebugLog(uri .. ":" .. port .. "[" .. RequestTypeToString(requestType) .. "] -> " .. response.statusCode .. " " .. response.statusName)
    end)
end

local function callNoData(uri, port, path, requestType)
    return callGenericCallback(uri, port, path, requestType, {}, "")
end

return {
    DebugLog = DebugLog,
    call = call,
    callGenericCallback = callGenericCallback,
    callNoData = callNoData
}