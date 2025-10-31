INCLUDE "include/constants.inc"

SECTION "Components", WRAM0

EXPORT pos_x, pos_y
EXPORT vel_x, vel_y
EXPORT spr_tile

pos_x:     DS MAX_ENTS
pos_y:     DS MAX_ENTS
vel_x:     DS MAX_ENTS
vel_y:     DS MAX_ENTS
spr_tile:  DS MAX_ENTS

SECTION "Player Vars", WRAM0
wPlayerX:   DS 1
wPlayerY:   DS 1
wVelX:      DS 1
wVelY:      DS 1

EXPORT wPlayerX, wPlayerY, wVelX, wVelY