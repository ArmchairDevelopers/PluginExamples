--- https://luals.github.io/wiki/annotations/
--- @meta


-- Note on how this document works:

-- If you are using the Lua extension on VS Code, the IDE will use this 
-- file to know what symbols exist in the global scope.

-- There are 3 sections in this file: "Global Libraries", "Types", & "Events"
-- These sections cannot have their name changed and you cannot put a library 
-- in the Type section and vice versa. The formatting of this document is designed
-- so the `KyberLuaDocumentationGenerator` can properly parse it to generate what
-- you see on the `KyberDocs`
-- Comments with two '-' are skipped while comments with 3 '-' are parsed & treated 
-- as comments if they are not declarators (comments with @param or something)


--#region Global Libraries

--- EventManager global table.
--- @class EventManager
EventManager = {}

--- Subscribes a listener to an event.
--- @param event string The name of the event.
--- @param callback fun(...) The function to call when the event is triggered.
function EventManager.Listen(event, callback) end

--- Subscribes a listener to an event.
--- @param event string The name of the event.
--- @param inst any Object that has callback as one of its instanced methods.
--- @param callback fun(...) The function to call when the event is triggered.
function EventManager.Listen(event, inst, callback) end

--- Set current running event cancellation to be queued.
--- @param isCancelled boolean Set if the event is queued to be cancelled.
function EventManager.SetCancelled(isCancelled) end

--- Console global table.
--- @class Console
Console = {}

--- Gets the settings for a specific category.
--- @param category string The category to get the settings for.
--- @return DataContainer Settings object
function Console.GetSettings(category) end

--- Execute a console command.
--- @param command string The command to be executed.
function Console.Execute(command) end

-- Not implemented
-- --- Register a new command.
-- --- @param group string The category to get the settings for.
-- --- @param name string The name for the command.
-- --- @param description string The description for the command.
-- --- @param callback fun(args: string) The callback function that is called when the command is executed.
-- function Console.Register(group, name, description, callback) end

--- Register a new command.
--- @param group string The category to get the settings for.
--- @param name string The name for the command.
--- @param description string The description for the command.
--- @param inst table The instance you want to have the callback be the instance function of. Like: `inst:callback(args)`
--- @param callback fun(args: string) The callback function that is called when the command is executed.
function Console.Register(group, name, description, inst, callback) end

--- ChatFilter global table.
--- @class ChatFilter
ChatFilter = {}

--- Clears all blocked phrases & regex.
function ChatFilter.Clear() end

--- Clears all blocked phrases.
function ChatFilter.ClearBlockedPhrases() end

--- Clears all blocked regex.
function ChatFilter.ClearBlockedRegex() end

--- Enable chat filter filtering messages. Note: Even when disabled, you can still access these table functions.
function ChatFilter.Enable() end

--- Disable chat filter filtering messages. Note: Even when disabled, you can still access these table functions.
function ChatFilter.Disable() end

--- Returns if the chat filter is enabled.
--- @return boolean
function ChatFilter.IsEnabled() end

--- Add blocked phrase to chat filter. Filtering of this type is case insensitive. Returns whether the phrase was added to the list or already existed (false)
--- @param phrase string The phrase you want to add
--- @return boolean
function ChatFilter.AddBlockedPhrase(phrase) end

--- Add blocked regex to chat filter. Returns whether the regex was added to the list or already existed (false)
--- @param phrase string The phrase you want to add
--- @return boolean
function ChatFilter.AddBlockedRegex(phrase) end

--- Sets the chat filter's replacement character. For example, if set to '#', "blah badword" -> "blah #######"
--- @param char string The character you want to set
function ChatFilter.SetFilterCharacter(char) end

--- Gets the chat filter's replacement character.
--- @return string character
function ChatFilter.GetFilterCharacter() end

--- PlayerManager global table.
--- @class PlayerManager
PlayerManager = {}

--- Gets all players online (both real and AI).
--- @return Player[]
function PlayerManager.GetPlayers() end

--- Gets the player requested.
--- @param playerName string Requested player username
--- @return Player
function PlayerManager.GetPlayer(playerName) end

--- Creates a new bot player with the given name.
--- @param name string The display name for the new bot player.
--- @return Player player The newly created Player instance.
function PlayerManager.CreatePlayer(name) end

--- EntityManager global table.
--- @class EntityManager
EntityManager = {}

--- Create an entity. Experimental!
--- @param dataContainer DataContainer The entity data container. The desired entity is derived from this type.
--- @return Entity
function EntityManager.Create(dataContainer) end

--- Get every entity of a type. Experimental & Very slow!
--- @param entityType string The desired entity type name.
--- @param realm integer The realm you want to search in. Pass in a `Realm` type. Ex: `Realm.Realm_Server`. Anything other than `Realm.Realm_Server` may cause a crash!
--- @return Entity[]
function EntityManager.GetList(entityType, realm) end

--- ResourceManager global table.
--- @class ResourceManager
ResourceManager = {}

--- Get the the Asset of the name provided in ANY loaded bundle. This function is **EXTREMELY SLOW** so if you do need to use it, make it sparingly.
--- @param assetName string The desired Asset name.
--- @return DataContainer
function ResourceManager.LookupDataContainer(assetName) end

--- MapRotation global table.
--- Manages the server's map rotation, including adding, removing, and getting map entries.
--- @class MapRotation
MapRotation = {}

--- Adds a map entry to the end of the rotation.
--- Raises an error if either `level` or `mode` is an empty string.
--- @param level string The level path to add.
--- @param mode string The gamemode id to add.
function MapRotation.AddMap(level, mode) end

--- Clears the entire rotation and resets it with a single required starting entry.
--- Raises an error if either `level` or `mode` is an empty string.
--- @param level string The level path for the first entry after clearing.
--- @param mode string The gamemode id for the first entry after clearing.
function MapRotation.Clear(level, mode) end

--- Returns the next map entry in the rotation without removing it.
--- @return MapRotationEntry entry A table containing `level` and `mode` fields.
function MapRotation.GetNextMap() end

--- Removes the next map entry from the rotation.
function MapRotation.RemoveNextMap() end

--- Returns the current index within the map rotation list.
--- @return integer index The index of the current rotation entry.
function MapRotation.GetCurrentEntryIndex() end

--- Returns the full list of map rotation entries.
--- @return MapRotationEntry[] entries An array of tables, each containing `level` and `mode` fields.
function MapRotation.GetList() end

--- SocketManager global table.
--- @class SocketManager
SocketManager = {}

--- Creates a non-blocking TCP listening socket bound to the given port on all interfaces.
--- The socket is set to non-blocking mode and begins listening immediately.
--- Raises an error if the socket cannot be created, bound, or set to listen.
--- @param port integer The local port number to bind and listen on.
--- @return WinSocket socket The created listening socket.
function SocketManager.Create(port) end

--- Creates a non-blocking TCP socket and connects to it.
--- The URI must be `"127.0.0.1"`. connections to external addresses are not allowed.
--- Raises an error if the URI is not `"127.0.0.1"`, or if the socket cannot be created, bound, or connected.
--- @param uri string The target IP address. Must be `"127.0.0.1"`.
--- @param port integer The target port number to connect to.
--- @return WinSocket socket The created and connected socket.
function SocketManager.CreateConnect(uri, port) end

--#endregion

--#region Types

--- A server player.
--- Represents a server-side player instance.
--- @class Player
--- @field public name string Player's username.
--- @field public playerId integer Player's EA player id.
--- @field public team integer Player's current team.
--- @field public battlepoints integer Player's battlepoint count.
--- @field public score integer The player's current score.
--- @field public kills integer The player's current kill count.
--- @field public assists integer The player's current assist count.
--- @field public deaths integer The player's current death count.
--- @field public afkTime number How long it has been since the player has inputted anything in seconds.
--- @field public characterEntity Entity The character entity the player is currently occupying, or nil if not spawned on foot.
--- @field public vehicleEntity Entity The vehicle entity the player is currently occupying, or nil if not in a vehicle.
--- @field public activeKit DataContainer The active kit/loadout asset for the player, or nil if none is set.
--- @field public isBot boolean If player is a bot.
--- @field public isAlive boolean If player is actively spawned as a character or vehicle.
Player = {}

--- Sets the player's team.
--- @param team integer The team id to set.
function Player:SetTeam(team) end

--- Sets the player's primary weapon by asset name.
--- Does nothing if the player has no soldier extent or the asset cannot be found.
--- @param weaponName string The resource name of the weapon asset to equip.
function Player:SetWeapon(weaponName) end

--- Returns the player's currently equipped primary weapon as a DataContainer asset.
--- Returns nothing if the player has no soldier extent or no weapon assigned.
--- @return DataContainer weapon The weapon asset.
function Player:GetWeapon() end

--- Sets the player's score to an exact amount.
--- @param amount integer The score value to set.
function Player:SetScore(amount) end

--- Sets the player's kill count to an exact amount.
--- @param amount integer The kill count to set.
function Player:SetKills(amount) end

--- Sets the player's assist count to an exact amount.
--- @param amount integer The assist count to set.
function Player:SetAssists(amount) end

--- Sets the player's death count to an exact amount.
--- @param amount integer The death count to set.
function Player:SetDeaths(amount) end

--- Sets player's battlepoints.
--- @param amount integer The amount desired.
function Player:SetBattlepoints(amount) end

--- Give player battlepoints
--- @param amount integer The amount desired.
function Player:GiveBattlepoints(amount) end

--- **[EXPERIMENTAL]** Sets the player's customization asset by resource name.
--- Does nothing if the asset cannot be found.
--- @param assetName string The resource name of the customization asset.
function Player:SetCustomizationAsset(assetName) end

--- Grants or revokes a specific unlock on the player by GUID string.
--- Does nothing if the GUID string or boolean argument is missing.
--- @param assetGuid string The string representation of the unlock's GUID.
--- @param grant boolean `true` to grant the unlock, `false` to revoke it.
function Player:SetUnlock(assetGuid, grant) end

--- Kick server player from the server.
--- @param reason? string Set reason for the kick.
function Player:Kick(reason) end

--- Sets the player's character entity visibility.
--- Does nothing if the player has no character entity.
--- @param invisible boolean `true` to force the player invisible, `false` to restore visibility.
function Player:SetInvisible(invisible) end

--- Sets the player's current health value.
--- Does nothing if the player has no character entity or health component.
--- @param amount integer The health value to set.
function Player:SetHealth(amount) end

--- Sets the player's maximum health value.
--- Only works if the player's health component is a WSServerSoldierHealthComponent.
--- Does nothing if the player has no character entity or the health component is of an incompatible type.
--- @param amount integer The maximum health value to set.
function Player:SetMaxHealth(amount) end

--- Sets the player's character (notably not vehicle) active ability by ability ID.
--- Does nothing if the ability asset cannot be loaded for the given ID.
--- @param abilityId integer The ID of the ability to assign.
function Player:SetAbility(abilityId) end

--- Forces the player to send a chat message on a specified channel.
--- @param message string The message content to send.
--- @param channel? integer The chat channel ID (maps to ChatChannel enum).
function Player:ForceSendChatMessage(message, channel) end

--- Sends chat message to the player.
--- @param message string The message content to send.
function Player:SendChatMessage(message) end

--- Enables or disables a specific input action for the player.
--- @param actionId integer The ID of the input action to control.
--- @param enabled boolean `true` to enable the input, `false` to disable it.
function Player:SetInputEnabled(actionId, enabled) end

--- Resends synced game settings to the player's connection.
--- Useful after modifying server-side settings that need to be re-synced to the client.
function Player:SendSyncedSettings() end

--- Set if the player's character (notably not vehicle) is damageable.
--- @param isImmortal boolean
function Player:SetImmortal(isImmortal) end

--- Set if the player's character (notably not vehicle) is fake damageable.
--- @param isFakeImmortal boolean
function Player:SetFakeImmortal(isFakeImmortal) end

--- Set how much the player's character (notably not vehicle) takes explosion damage 
--- @param modifier number The value multiplied with the damage.
function Player:SetExplosionDamageModifier(modifier) end

--- Set how fast the player's character (notably not vehicle) is.
--- @param modifier number The value to set.
function Player:SetMoveSpeedMultiplier(modifier) end

--- Sets the player's character (notably not vehicle) total cooldown timer is. Higher values is slower, lower values is faster.  
--- @param modifier number The value to set.
function Player:SetCooldownModifier(modifier) end

--- An internal type's description
--- @class TypeInfo
--- @field public name string The type's name
TypeInfo = {}

--- Check if type is a subtype or is the type provided.
--- @param otherTypeName string The type you want to check against.
--- @return boolean
function TypeInfo:IsKindOf(otherTypeName) end

--- A generic DataContainer. The fields of this type are dynamic, so you must know what the names of them are to access them! For example, if I had a `AutoPlayerSettings` type, I could access the bots of team 1 by doing:
--- ```lua
--- local oldValue = autoPlayerSettings.forceFillGameplayBotsTeam1
--- autoPlayerSettings.forceFillGameplayBotsTeam1 = 10
--- ```
--- @class DataContainer
--- @field public typeInfo TypeInfo The DataContainer's type
DataContainer = {}

--- Check if type is the type name provided.
--- @param otherTypeName string The type you want to check against.
--- @return boolean
function DataContainer:Is(otherTypeName) end

--- A generic ValueType. The fields of this type are dynamic, so you must know what the names of them are to access them! For example, if I had a `EventConnection` type, I could access the source connection ValueType by doing:
--- ```lua
--- local oldValue = eventConnection.source
--- eventConnection.source = newDataContainer
--- ```
--- @class ValueType
ValueType = {}

--- A generic Array. This array can hold any type. It can be iterated through via `ipairs(array)` & `pairs(array)`, you can get the length of the array via `#array`, get values via `local value = array[index]`, & set it via `array[index] = newValue`.
--- @class FBArray
FBArray = {}

--- Extend how big the array is by an amount.
--- @param amount integer Extend the array size by this amount.
function FBArray:extend(amount) end

--- An EntityEvent type. Pass this into functions like Entity:Event(entityEvent). 
--- Create with global `EntityEvent("eventName")`. 
--- Usage example: ```lua
--- Entity:Event(EntityEvent("Spawn"))
--- ```
--- @class EntityEvent
EntityEvent = {}

--- An ServerPlayerEvent type. Pass this into functions like Entity:Event(serverPlayerEvent).
--- In places where an EntityEvent is allowed to be passed in, this type will also be allowed.
--- Create with global `ServerPlayerEvent("eventName")`. 
--- Usage example: ```lua
--- Entity:Event(ServerPlayerEvent("Spawn"))
--- ```
--- @class ServerPlayerEvent
ServerPlayerEvent = {}

--- An entity's bus. This is where most entity logic is executed, which can be accessed from the parent Entity
--- @class EntityBus
--- @field public data DataContainer The entity bus's exposed data.
EntityBus = {}

--- A generic Entity container. An entity is what runs all of EBX logic, and is interactable with this API.
--- @class Entity
--- @field public data DataContainer The entity's exposed data.
--- @field public bus EntityBus The entity's bus.
Entity = {}

--- Queue an event to be executed into the context it is in.
--- @param event EntityEvent The event you want to execute.
function Entity:Event(event) end

--- Immediately fire an event to be processed internally in the entity.
--- @param event EntityEvent The event you want to execute.
function Entity:FireEvent(event) end

--- Execute a property write on the entity. These are the **IN** properties.
--- @param fieldName string The field name. Can either be a string or the field hash (like `0x236BA71D`)
--- @param typeName string The name of the type being written.
--- @param value any The value being written.
function Entity:Write(fieldName, typeName, value) end

--- Read a property from the entity. These are the **OUT** properties.
--- @param fieldName string The field name. Can either be a string or the field hash (like `0x236BA71D`)
--- @param typeName string The name of the type you want read.
--- @return any
function Entity:Read(fieldName, typeName) end

--- Represents a single map rotation entry.
--- @class MapRotationEntry
--- @field public level string The level path of the map.
--- @field public mode string The gamemode id of the map.
MapRotationEntry = {}

--- Represents a Windows TCP socket handle returned by SocketManager.
--- The socket is automatically closed when garbage collected.
--- @class WinSocket
WinSocket = {}

--- Accepts an incoming client connection on a listening socket.
--- Returns `nil` if no client is ready (non-blocking, WSAEWOULDBLOCK).
--- Raises an error if the accept call fails for any other reason.
--- @return WinSocket clientSocket The accepted client socket, or nil if no connection is pending.
function WinSocket:Accept() end

--- Receives data from the socket up to `length` bytes.
--- Returns an empty string if the connection was closed gracefully.
--- Raises an error if the recv call fails.
--- @param length number The maximum number of bytes to receive.
--- @return string data The received data.
function WinSocket:Recv(length) end

--- Sends a string of data over the socket.
--- Raises an error if the send call fails.
--- @param data string The data to send.
--- @return number bytesSent The number of bytes successfully sent.
function WinSocket:Send(data) end

--- Specifically for outgoing request sockets. Returns 0 if pending, 1 if successfully connected
--- (and therefore can properly send data), and 2 if failed.
--- @return integer
function WinSocket:PollConnectionStatus() end

--- Specifically for outgoing request sockets. Returns true if specifically after PollConnectionStatus() 
--- returned 1 and therefore had no connection errors.
--- @return boolean
function WinSocket:IsOutgoingConnectionUsable() end

--- Closes the socket connection and releases the handle.
function WinSocket:Close() end

--- Disables sends or receives on a socket. `Recv()` is one of the functionalities that will be disabled if this is used.
function WinSocket:Shutdown() end

--- Disables sends on a socket. `Recv()` will not be disabled and will send any lingering data.
function WinSocket:ShutdownSend() end

--#endregion

--#region Events

--- Ran as soon as the server is fully created. The first event to run. A good place to put initialization logic.
--- @event Server Server:Init()

--- Update event every tick. Ran before the tick logic is executed.
--- @event Server Server:UpdatePre(deltaTime: number)

--- Ran as soon as a level is loaded.
--- @event Server Level:Loaded(level: string, mode: string)

--- Ran when a level is done and before the next one starts loading. Generally good for cleanup from last level.
--- @event Server Level:Complete()

--- Message sent every 10s that notifies the server of its performance statistics.
--- @event Server DedicatedServer:PerformanceStatsMessage(tps: number, avgTickTime: number, worstTickTime: number)

--- Event ran every time a message is filtered.
--- @event Server ChatFilter:Filter(sender: Player, message: string, filteredMessage: string)

--- Event ran every time an EBX asset is loaded. Expensive as a result.
--- @event Server ResourceManager:PartitionLoaded(partitionName: string, instance: DataContainer)

--- Event ran meant to be ran when an entity of a certain type is created.
--- [dynamic] is the EntityData type name of the entity, for example: `EntityFactory:Create:SpatialEntityData` for SpatialEntitys
--- Note: Experimental, may not be ran for every type
--- @event Server EntityFactory:Create:[dynamic](entityData: DataContainer)

--- Ran when a player leaves the server.
--- @event Server ServerPlayer:Disconnect(disconnectedPlayer: Player)

--- Ran when a player spawns. What class they spawned as does not matter.
--- @event Server ServerPlayer:Spawned(player: Player)

--- Ran when a player is killed. Killer player may be nil. 
--- @event Server ServerPlayer:Killed(victim: Player, killer: Player, killerWeaponName: string)

--- Ran every time a player sends a chat message. Cancellable.
--- @event Server ServerPlayer:SendMessage(player: Player, message: string)

--- Ran when a player joins the server.
--- @event Server ServerPlayer:Joined(joiningPlayer: Player)

--#endregion
