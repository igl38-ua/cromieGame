; ===== src/state_play.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

SECTION "StatePlay", ROM0
EXPORT Play_Enter

; Entra al primer nivel (el que cargabas tras el logo)
Play_Enter::
    call apagar_LCD

    ; Tiles del nivel + mapa base + scroll a 0
    call LoadBaseTiles
    call DrawMapaBase
    xor  a
    ldh  [rSCX], a
    ldh  [rSCY], a

    call InitSprites

    call encender_LCD
    call UpdateRender
    ret
