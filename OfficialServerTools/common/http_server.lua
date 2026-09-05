HttpRequest = {}
HttpRequest.__index = HttpRequest

function HttpRequest.new(server, client, method, path, headers, body)
    local obj = setmetatable({}, HttpRequest)
    obj.server = server
    obj.client = client
    obj.method = method
    obj.path = path
    obj.headers = headers
    obj.body = body
    return obj
end

function HttpRequest:send(data)
    self.client:Send("HTTP/1.1 200 OK\r\nContent-Length: " .. #data .. "\r\n\r\n" .. data)
    self.server:removeClient(self.client)
end

function HttpRequest:sendNoContent()
    self.client:Send("HTTP/1.1 204 No Content\r\n\r\n")
    self.server:removeClient(self.client)
end

function HttpRequest:sendNotFound()
    self.client:Send("HTTP/1.1 404 Not Found\r\n\r\n")
    self.server:removeClient(self.client)
end

local function parseHttpRequest(request)
    local method, path, version = request:match("^(%S+)%s(%S+)%s(HTTP/%d%.%d)\r?\n")
    if not method or not path or not version then
        return nil, "Invalid HTTP request line"
    end

    local headers = {}
    local bodyStart = request:find("\r\n\r\n")
    local headersPart = request:sub(#method + #path + #version + 4, bodyStart and bodyStart - 1 or #request)

    for line in headersPart:gmatch("[^\r\n]+") do
        local key, value = line:match("^(.-):%s*(.*)$")
        if key and value then
            headers[key] = value
        end
    end

    local body = bodyStart and request:sub(bodyStart + 4) or ""

    return {
        method = method,
        path = path,
        headers = headers,
        body = body
    }
end

HttpServer = {}
HttpServer.__index = HttpServer

function HttpServer.new(port, requestCallback)
    local obj = setmetatable({}, HttpServer)
    obj.socket = SocketManager.Create(port)
    obj.clients = {}
    obj.requestCallback = requestCallback
    if obj.socket == nil then
        print("Failed to create socket")
        return nil
    end

    EventManager.Listen("Server:UpdatePre", function(self, deltaSecs)
        self:update(deltaSecs)
    end, obj)

    print("HttpServer listening on port " .. port)
    return obj
end

function HttpServer:update(deltaSecs)
    do
        local client = self.socket:Accept()
        if client then
            table.insert(self.clients, client)
        end
    end

    for i = #self.clients, 1, -1 do
        local client = self.clients[i]
        local data = client:Recv(2048)
        if data == nil then
            goto continue
        end

        if #data == 0 then
            print("Client disconnected")
            table.remove(self.clients, i)
            return
        else
            local request, err = parseHttpRequest(data)
            if not request then
                print("Failed to parse HTTP request: " .. err)
                goto continue
            end

            self.requestCallback(HttpRequest.new(self, client, request.method, request.path, request.headers,
                request.body))
        end

        ::continue::
    end
end

function HttpServer:removeClient(client)
    client:Close()

    for i = #self.clients, 1, -1 do
        if self.clients[i] == client then
            table.remove(self.clients, i)
            return
        end
    end
end

HttpRouter = {}
HttpRouter.__index = HttpRouter

function HttpRouter.new()
    local obj = setmetatable({}, HttpRouter)
    obj.routes = {}
    return obj
end

function HttpRouter:handle(method, path, callback)
    table.insert(self.routes, {method = method, path = path, callback = callback})
end

function HttpRouter:handleRequest(req)
    for _, route in ipairs(self.routes) do
        if req.method == route.method and req.path == route.path then
            route.callback(req)
            return
        end
    end

    req:sendNotFound()
end

return {
    Server = HttpServer,
    Router = HttpRouter
}
