local debugMode = os.getenv("KYBER_DEV_MODE") ~= nil or true -- :)
local DebugLog = function(s)
    if (debugMode) or ((os.getenv("KYBER_LOG_LEVEL") or ""):lower() == "debug") then
        print("[Debug] " .. s)
    end
end

require "common/sdk"

if debugMode then
    require "admins"
end

local VanillaGunList = require "vanilla_gun_list"
local BFPlusGunList = require "bfplus_gun_list"
local AllGuns = {}

local GunListEnvName <const> = "KYBER_PLUGIN_SETTING_GUNLIST" -- Base64 -> path|path2|path3
local GunCountEnvName <const> = "KYBER_PLUGIN_SETTING_GUNCOUNT" -- Int32
local UseBFPlusGunListEnvName <const> = "KYBER_PLUGIN_SETTING_USE_BFPLUS_GUNLIST" -- Boolean
local DisableInputBlockEnvName <const> = "KYBER_PLUGIN_SETTING_DISABLE_INPUT_BLOCK" -- Boolean
local BaseGunCount <const> = 7
local MeleeGun <const> = "Gameplay/Equipment/Pistols/PingLauncher/U_DefaultAbility_Assault_ScanDart"

local UseBFPlusGunList = os.getenv(UseBFPlusGunListEnvName) ~= nil
if UseBFPlusGunList then
    AllGuns = BFPlusGunList
else
    AllGuns = VanillaGunList
end

local function getDistinctValues(inputTable)
    local distinctTable = {}
    local seen = {}

    for _, value in ipairs(inputTable) do
        if not seen[value] then
            table.insert(distinctTable, value)
            seen[value] = true
        end
    end

    return distinctTable
end

AllGuns = getDistinctValues(AllGuns)
GunList = {}

if os.getenv(DisableInputBlockEnvName) == nil then
    require "input_blocks"
end

local Broadcast = function(str) Console.Execute("Kyber.Broadcast " .. str) end


GunGameProgram = {
    CompletedSanityCheck = false,
    GameComplete = false,
    Database = {},
    GunCount = 8,
    Anchor = -1,

    HasBeenAnnouncedLastWeapon = {},
    DoneBackupStartGame = false,

    -- Events

    OnKilled = function(self, victim, killer, killerWeapon)
        if killer == nil or victim.playerId == killer.playerId then
            return
        end

        self:IncrementPlayerWeapon(killer)

        if victim == nil then
            return
        end

        victim:GiveBattlepoints(100)
        if (killer.battlepoints >= 100) then
            killer:GiveBattlepoints(-100)
        end

        if string.find(killerWeapon, "U_Melee") then
            self:DecrementPlayerWeapon(victim)
            self:DecrementPlayerWeapon(victim)
        end
    end,

    OnSpawned = function(self, player)
        if player == nil then
            return
        end

        player:SetTeam(self.Anchor)

        GunGameProgram:EnsurePlayerInitialized(player)
        GunGameProgram:UpdatePlayerWeapon(player)

        -- just incase
        local syncedGame = Console.GetSettings("SyncedGame")
        if syncedGame == nil then
            return
        end

        syncedGame.enableFriendlyFire = true
        player:SendSyncedSettings()
    end,
    
    -- Logic

    IncrementPlayerWeapon = function(self, player)
        self:EnsurePlayerInitialized(player)
        
        local completedGunList = self.Database[player.playerId] >= self.GunCount
        if (self.Database[player.playerId] == self.GunCount - 1) and (not table.contains(self.HasBeenAnnouncedLastWeapon, player.playerId)) then
            Broadcast("**[BLASTER MASTER]** **" .. player.name .. "** is on the last gun!")
            table.insert(self.HasBeenAnnouncedLastWeapon, player.playerId)
        end

        if completedGunList and not self.GameComplete then
            local message = "**" .. player.name .. "** wins! Moving to next map..."

            Broadcast(message)
            Broadcast(message)
            Broadcast(message)

            self.GameComplete = true

            SetTimeout(function()
                Console.Execute("endofround")
            end, 5)
        end
        
        self.Database[player.playerId] = (self.Database[player.playerId] % self.GunCount) + 1
        self:UpdatePlayerWeapon(player)
    end,

    DecrementPlayerWeapon = function(self, player)
        if self.Database[player.playerId] == 1 then
            return
        end

        self:EnsurePlayerInitialized(player)
        self.Database[player.playerId] = self.Database[player.playerId] - 1
    end,

    RandomizeAnchor = function(self)
        self.Anchor = math.random(1, 2)
        DebugLog("GunGame anchor set to: " .. self.Anchor)
    end,

    AttemptLoadGameSettings = function(self)
        local function LoadGunList()
            local envData = os.getenv(GunListEnvName)
            if envData == nil or envData:len() <= 1 then
                return
            end

            AllGuns = string.split(base64.decode(envData), "|")
            print("Successfully loaded gun list from environment")
        end

        local function LoadGunListCount()
            local envData = os.getenv(GunCountEnvName)
            if envData ~= nil and envData:len() > 0 then
                local countNum = tonumber(envData)
                if countNum ~= nil and countNum ~= 0 then
                    self.GunCount = countNum
                    return
                end
            end

            -- Then we decide count based on player count
            local playerCount = -1

            -- Attempt to read player count, may fail since we
            -- are reading before the server has fully loaded
            local function getPlayerCount()
                -- Count up the current human players
                local count = 0

                local players = PlayerManager.GetPlayers()
                if players == nil then
                    return 0
                end

                for _, player in ipairs(players) do
                    if player.isBot then
                        goto continue
                    end

                    count = count + 1
                    ::continue::
                end

                return count
            end

            playerCount = getPlayerCount()
            self.GunCount = BaseGunCount + playerCount
        end

        LoadGunList()
        LoadGunListCount()
    end,

    RandomizeGunList = function(self)
        GunList = AllGuns

        local function shuffleTable(t)
            for i = #t, 2, -1 do
                local j = math.random(i)
                t[i], t[j] = t[j], t[i]
            end
        end
        
        local function getSubArray(arr, startIndex, endIndex)
            local subArray = {}

            startIndex = math.max(1, startIndex or 1)
            endIndex = math.min(#arr, endIndex or #arr)

            for i = startIndex, endIndex do
                table.insert(subArray, arr[i])
            end
            return subArray
        end

        self.GunCount = math.min(self.GunCount, #GunList)

        shuffleTable(GunList)
        GunList = getSubArray(GunList, 1, self.GunCount - 1)
        table.insert(GunList, MeleeGun)

        DebugLog("Randomized gun list (" .. #GunList .. "): " .. table.concat(GunList, ", "))
    end,

    -- Accessibility

    ResetDatabase = function(self)
        self.GameComplete = false
        self.Database = {}
        self.HasBeenAnnouncedLastWeapon = {}
        self.DoneBackupStartGame = false
    end,

    EnsurePlayerInitialized = function(self, player)
        self.Database[player.playerId] = (((self.Database[player.playerId] or 1) - 1) % self.GunCount) + 1
    end,

    UpdatePlayerWeapon = function(self, player)
        local gun = GunList[self.Database[player.playerId]]
        if gun == nil then
            DebugLog("ERROR: Tried setting player " .. player.name .. " with database value " .. self.Database[player.playerId] .. " to nil gun")
            return
        end
        
        player:SetWeapon(gun)
    end,

    SanityCheck = function(self)
        if not debugMode or self.CompletedSanityCheck then return end

        local amountFailed = 0
        for _, gun in ipairs(GunList) do
            local data = ResourceManager.LookupDataContainer(gun)
            if data == nil then
                amountFailed = amountFailed + 1
                print("[ERROR] Weapon does not exist: " .. gun)
            end
        end

        print(string.format("Sanity check complete; found %d errors", amountFailed))
        self.CompletedSanityCheck = true
    end
}

local function CompleteReset()
    GunGameProgram:ResetDatabase()
    GunGameProgram:AttemptLoadGameSettings()
    GunGameProgram:RandomizeGunList()
    GunGameProgram:RandomizeAnchor()

    local players = PlayerManager.GetPlayers()
    if players == nil then
        return
    end

    -- Set everyone to new anchor
    for _, player in ipairs(players) do
        if player.isBot then
            goto continue
        end

        player:SetTeam(GunGameProgram.Anchor)
        ::continue::
    end
end

EventManager.Listen("ServerPlayer:Killed", GunGameProgram.OnKilled, GunGameProgram)
EventManager.Listen("ServerPlayer:Spawned", GunGameProgram.OnSpawned, GunGameProgram)

EventManager.Listen("ServerPlayer:Joined", function(player)
    GunGameProgram:SanityCheck()

    -- if for some reason the server takes an absurd amount of time to load in
    if not GunGameProgram.DoneBackupStartGame then
        Console.Execute("startgame")
        GunGameProgram.DoneBackupStartGame = true
    end

    local syncedGame = Console.GetSettings("SyncedGame")
    if syncedGame == nil then
        return
    end

    syncedGame.enableFriendlyFire = true
    player:SendSyncedSettings()

    SetTimeout(function()
        player:SetTeam(GunGameProgram.Anchor)
    end, 0.1)
end)

EventManager.Listen("Level:Loaded", function(level, mode)
    CompleteReset()

    SetTimeout(function()
        Broadcast("**[BLASTER MASTER]** Welcome to Blaster Master! Gun list count for this round: " ..
        GunGameProgram.GunCount)
    end, 5)

    local autoPlayers = Console.GetSettings("AutoPlayers")
    if autoPlayers == nil then
        return
    end

    SetTimeout(function()
        Console.Execute("startgame")
        -- just incase
        SetTimeout(function()
            Console.Execute("startgame")
            SetTimeout(function()
                Console.Execute("startgame")
            end, 10)
        end, 10)
    end, 10)
end)

EventManager.Listen("ResourceManager:PartitionLoaded", function(instanceName, inst)
    if inst.typeInfo.name ~= "LayerData" or not string.find(instanceName, "/TeamDeathmatch_") then
        return
    end

    for _, object in pairs(inst.objects) do
        if object.typeInfo.name ~= "BoolEntityData" then
            goto continue
        end

        if object.defaultValue == false and object.realm == Realm.Realm_Server then
            object.realm = Realm.Realm_None
            object.defaultValue = true
            
            DebugLog("Patched close spawns at the start of rounds")
        end

        ::continue::
    end
end)

EventManager.Listen("ResourceManager:PartitionLoaded", function(instanceName, inst)
    if not inst.typeInfo:isKindOf("PlayerAbilityAsset") then
        return
    end

    inst.ignoreNetworkingErrors = true
end)

if debugMode then
    CompleteReset()
end


------------------------ DEBUG ------------------------

if not debugMode then
    return
end

EventManager.Listen("ServerPlayer:SendMessage", function(player, message)
    if not table.contains(Admins, player.playerId) then return end
    if message:len() < 2 then return end
    local messageSplit = string.split(message)

    if #messageSplit <= 0 then return end
    if messageSplit[1]:len() < 3 then return end
    if messageSplit[1]:sub(1, 1) ~= '/' then return end

    local command = messageSplit[1]:lower():sub(2)

    -- A command is attempted to be executed; dont send to everyone
    EventManager.SetCancelled(true)

    if command == "testeverygun" then
        local i = 1
        local j = #AllGuns
        local function runTest()
            DebugLog("Setting weapon to: " .. AllGuns[i])
            player:SetWeapon(AllGuns[i])
            i = i + 1

            if i < j then
                SetTimeout(runTest, 0.5)
            else
                DebugLog("Done")
            end
        end

        runTest()
    elseif command == "inc" then
        GunGameProgram:IncrementPlayerWeapon(player)

    elseif command == "setscore" then
        if #messageSplit < 2 then return end
        player:SetScore(tonumber(messageSplit[2]))

    elseif command == "setkills" then
        if #messageSplit < 2 then return end
        player:SetKills(tonumber(messageSplit[2]))

    elseif command == "setassists" then
        if #messageSplit < 2 then return end
        player:SetAssists(tonumber(messageSplit[2]))

    elseif command == "setdeaths" then
        if #messageSplit < 2 then return end
        player:SetDeaths(tonumber(messageSplit[2]))

    elseif command == "setinvisible" then
        if #messageSplit < 2 then return end
        player:SetInvisible(tonumber(messageSplit[2]) > 0)

    elseif command == "sethealth" then
        if #messageSplit < 2 then return end
        player:SetHealth(tonumber(messageSplit[2]))

    elseif command == "setmaxhealth" then
        if #messageSplit < 2 then return end
        player:SetMaxHealth(tonumber(messageSplit[2]))

    elseif command == "setammo" then
        if #messageSplit < 2 then return end
        player:SetAmmo(tonumber(messageSplit[2]))

    elseif command == "setability" then
        if #messageSplit < 2 then return end
        player:SetAbility(tonumber(messageSplit[2]))

    elseif command == "sudo" then
        if #messageSplit < 3 then return end
        local playerName = messageSplit[2]
        local target = PlayerManager.GetPlayer(playerName)
        if target == nil then DebugLog("SUDO FAILED TO FIND TARGET") return end
        player:ForceSendChatMessage(table.concat(messageSplit, " ", 3))
        
    elseif command == "testanakin" then
        player:SetCustomizationAsset("Gameplay/Kits/Hero/DarthVader/Kit_Hero_DarthVader")

    else 
        DebugLog("Invalid command ran: " .. command)
    end
end)

------------------------ DEBUG ------------------------
