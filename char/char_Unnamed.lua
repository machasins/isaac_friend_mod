local json = require("json")
local hidden_items = require(CHAR_UNNAMED.Scripts .. ".hidden_item_manager")
local saveData = {}

local START_WITH_BONE_HEARTS = true

local STARTING_ITEMS = {
    CollectibleType.COLLECTIBLE_ACT_OF_CONTRITION,
}

local SMELTED_TRINKETS = {
    TrinketType.TRINKET_PAY_TO_WIN,
}

hidden_items:Init(CHAR_UNNAMED)

--#region LOCAL FUNCTIONS

---Convert fire delay into TPS
---@param maxFireDelay number
---@return number
local function toTearsPerSecond(maxFireDelay)
    return 30 / (maxFireDelay + 1)
end

---Convert TPS into fire delay
---@param tearsPerSecond number
---@return number
local function toMaxFireDelay(tearsPerSecond)
    return (30 / tearsPerSecond) - 1
end

--#endregion

--#region STAT DEFINITIONS

---@alias STAT_NAME string
---@alias STAT_CALC fun(stat:number, mult:number, add:number):number

---@class STAT_CONTAINER
---@field ADD table<STAT_NAME, number> Additional stats the character should get
---@field MULT table<STAT_NAME, number> Multipliers for stats the character should get
---@field MOD_FUNC table<STAT_NAME, STAT_CALC> How the stat should be calculated
---@field PLAYER_VARS table<STAT_NAME, string> Mapping of player variables to internal stat names
---@field FLAGS table<STAT_NAME, CacheFlag> Mapping of Cache flags to internal stat names
---@field INTERNAL_NAMES STAT_NAME[] The internal names of player's stats
local STATS = {
    ADD = {
        SPEED = 0.0,
        DMG = 0.0,
        TEAR = -0.72,
        RANGE = 0.0,
        SHOT = -0.25,
        LUCK = 2.0,
    },
    MULT = {
        SPEED = 1.0,
        DMG = 1.0,
        TEAR = 1.0,
        RANGE = 1.0,
        SHOT = 1.0,
        LUCK = 1.0,
    },
    MOD_FUNC = {
        SPEED = function (stat, mult, add) return stat * mult + add end,
        DMG = function (stat, mult, add) return stat * mult + add end,
        TEAR = function (stat, mult, add) return toMaxFireDelay(toTearsPerSecond(stat) * mult + add) end,
        RANGE = function (stat, mult, add) return stat * mult + (add * 40) end,
        SHOT = function (stat, mult, add) return stat * mult + add end,
        LUCK = function (stat, mult, add) return stat * mult + add end,
    },
    PLAYER_VARS = {
        SPEED = "MoveSpeed",
        DMG = "Damage",
        TEAR = "MaxFireDelay",
        RANGE = "TearRange",
        SHOT = "ShotSpeed",
        LUCK = "Luck",
    },
    FLAGS = {
        SPEED = CacheFlag.CACHE_SPEED,
        DMG = CacheFlag.CACHE_DAMAGE,
        TEAR = CacheFlag.CACHE_FIREDELAY,
        RANGE = CacheFlag.CACHE_RANGE,
        SHOT = CacheFlag.CACHE_SHOTSPEED,
        LUCK = CacheFlag.CACHE_LUCK,
    },
    INTERNAL_NAMES = {
        "SPEED",
        "DMG",
        "TEAR",
        "RANGE",
        "SHOT",
        "LUCK",
    }
}

--#endregion

--#region STARTING STATS

---Run when evaluating stats
---@param player EntityPlayer
---@param flag CacheFlag
function CHAR_UNNAMED:HandleStartingStats(player, flag)
    if player:GetPlayerType() ~= CHAR_UNNAMED.Type then
        return -- End the function early. The below code doesn't run, as long as the player isn't Unnamed.
    end

    -- Loop through all internal names for stats
    for _, name in ipairs(STATS.INTERNAL_NAMES) do
        -- If the stat is being updated
        if flag == STATS.FLAGS[name] then
            -- Calculate the stat's new value
            player[STATS.PLAYER_VARS[name]] = STATS.MOD_FUNC[name](player[STATS.PLAYER_VARS[name]], STATS.MULT[name], STATS.ADD[name])
        end
    end
end

CHAR_UNNAMED:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, CHAR_UNNAMED.HandleStartingStats)

--#endregion

--#region INNATE ITEMS

---Run when player is initialized
---@param player EntityPlayer
function CHAR_UNNAMED:Init(player)
    if player:GetPlayerType() ~= CHAR_UNNAMED.Type then
        return
    end

    -- Add trinkets
    for _, trinket in pairs(SMELTED_TRINKETS) do
        player:AddSmeltedTrinket(trinket)
    end

    -- Convert starting health to bone hearts
    if START_WITH_BONE_HEARTS then
        local heartAmount = player:GetMaxHearts()
        player:AddMaxHearts(-heartAmount)
        player:AddBoneHearts(heartAmount / 2)
        player:AddHearts(heartAmount)
    end
end

CHAR_UNNAMED:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, CHAR_UNNAMED.Init)

---Run when player effects are updated
---@param player EntityPlayer
function CHAR_UNNAMED:InnateUpdate(player)
    if player:GetPlayerType() ~= CHAR_UNNAMED.Type then
        return
    end

    -- Add innate items
    for _, item in pairs(STARTING_ITEMS) do
        hidden_items:CheckStack(player, item, 1)
        player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(item))
    end
end

CHAR_UNNAMED:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, CHAR_UNNAMED.InnateUpdate)

--#endregion

--#region SAVING AND LOADING

---Save data
function CHAR_UNNAMED:Save()
    saveData.HIDDEN_ITEMS = hidden_items:GetSaveData()
    CHAR_UNNAMED:SaveData(json.encode(saveData))
end

CHAR_UNNAMED:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, CHAR_UNNAMED.Save)

---Load data
function CHAR_UNNAMED:Load()
    if CHAR_UNNAMED:HasData() then
        saveData = json.decode(CHAR_UNNAMED:LoadData())
        hidden_items:LoadData(saveData.HIDDEN_ITEMS)
    end
end

CHAR_UNNAMED:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, CHAR_UNNAMED.Save)

--#endregion