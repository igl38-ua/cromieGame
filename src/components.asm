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


SECTION "CollisionWRAM", WRAM0
EXPORT wCollMap
wCollMap: DS MAP_W * MAP_H

SECTION "LevelPtr", WRAM0
EXPORT wLevelTilePtr
wLevelTilePtr: DS 2
