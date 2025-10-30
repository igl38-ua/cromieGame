; ===== components.asm =====
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
wPlayerX:   DS 1   ; X en pixeles (0..159) - parte entera
wPlayerY:   DS 1   ; Y en pixeles (0..143) - parte entera
wVelX:      DS 1   ; -1, 0, +1 (o más si quieres velocidad mayor)
wVelY:      DS 1

EXPORT wPlayerX, wPlayerY, wVelX, wVelY