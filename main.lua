---@class CHAR_WILL : ModReference
CHAR_WILL = RegisterMod("Will Character Mod", 1)

CHAR_WILL.Scripts = "will"
CHAR_WILL.Name = "Will"
CHAR_WILL.Type = Isaac.GetPlayerTypeByName(CHAR_WILL.Name, false) -- Exactly as in the xml. The second argument is if you want the Tainted variant.

include(CHAR_WILL.Scripts .. ".char_" .. CHAR_WILL.Name)