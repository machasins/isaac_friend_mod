---@class CHAR_UNNAMED : ModReference
CHAR_UNNAMED = RegisterMod("Character Mod", 1)

CHAR_UNNAMED.Scripts = "char"
CHAR_UNNAMED.Name = "Unnamed"
CHAR_UNNAMED.Type = Isaac.GetPlayerTypeByName(CHAR_UNNAMED.Name, false) -- Exactly as in the xml. The second argument is if you want the Tainted variant.

include(CHAR_UNNAMED.Scripts .. ".char_" .. CHAR_UNNAMED.Name)