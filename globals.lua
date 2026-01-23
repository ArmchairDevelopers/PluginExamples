---@meta

--- EventManager global table.
--- @class EventManager
EventManager = {}

--- Subscribes a listener to an event.
--- @param event string The name of the event.
--- @param callback fun(...) The function to call when the event is triggered.
function EventManager.Listen(event, callback) end

-- Console global table.
--- @class Console
Console = {}

--- Gets the settings for a specific category.
--- @param category string The category to get the settings for.
function Console.GetSettings(category) end