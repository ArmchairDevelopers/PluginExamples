local Http = require "http_server"
local HttpServer = Http.Server
local HttpRouter = Http.Router

local requestRouter = HttpRouter.new()

HttpServer.new(29184, function(req)
    requestRouter:handleRequest(req)
end)

return requestRouter
