local requestRouter = require "server_router"

requestRouter:handle("GET", "/broadcast", function(req)
    Console.Execute("Kyber.Broadcast " .. req.headers["x-message"])
    req:sendNoContent()
end)

require "shutdown"
