local LeftPlayerActionId <const> = 871087120
local MiddlePlayerActionId <const> = 871087121
local RightPlayerActionId <const> = 871087126

--#region Data

local BlockMiddleList <const> = {
    "Assault",
    "Heavy",
    "Specialist",
    "Kit_Special_B2",
    "Kit_Special_Gunner",
    "Kit_Special_JumpCop",
    "JumpTrooper",
    "Kit_Special_ResistanceSpy",
    "Kit_Special_WookieWarrior"
}

local BlockLeftList <const> = {
    "Kit_Special_B2",
    "Kit_Special_Gunner"
}

local BlockRightList <const> = {
    "Kit_Special_CloneCommando"
}

--#endregion

local function applyBlockLists(player, activeKitName)
    -- Middle
    for _, searchValue in ipairs(BlockMiddleList) do
        if string.find(activeKitName, searchValue) then
            player:SetInputEnabled(MiddlePlayerActionId, false)
            break
        end
    end

    -- Left
    for _, searchValue in ipairs(BlockLeftList) do
        if string.find(activeKitName, searchValue) then
            player:SetInputEnabled(LeftPlayerActionId, false)
            break
        end
    end

    -- Right
    for _, searchValue in ipairs(BlockRightList) do
        if string.find(activeKitName, searchValue) then
            player:SetInputEnabled(RightPlayerActionId, false)
            break
        end
    end
end

local function disableBlocking(player)
    player:SetInputEnabled(MiddlePlayerActionId, true)
    player:SetInputEnabled(LeftPlayerActionId, true)
    player:SetInputEnabled(RightPlayerActionId, true)
end

EventManager.Listen("ServerPlayer:Spawned", function(player)
    applyBlockLists(player, player.activeKit.name)
end)

EventManager.Listen("ServerPlayer:Killed", function(victim, killer)
    disableBlocking(victim)
end)
