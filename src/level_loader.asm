INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"
SECTION "LevelLoaderVars", WRAM0
SECTION "LevelLoader", ROM0
EXPORT LoadLevelCurrent, NextLevel

; Tabla de mapas (punteros a tilemaps 20x18)
SECTION "LevelTable", ROM0
LevelMaps:
    dw _Mapa1
    dw _Mapa2
    dw _Mapa3
    dw _Mapa4
    ;dw _Mapa5
    dw _MapaBase
    dw _MapaSegundoNivel

; ----------------------------------------------------------
; Carga tiles base, copia el tilemap del nivel actual a $9800,resetea scroll, reinicializa sprites y enciende LCD.
; ----------------------------------------------------------
LoadLevelCurrent::
    call wait_vBlank
    call apagar_LCD

    call LoadBaseTiles

    ld   hl, LevelMaps
    ld   a, [wLevelIdx]
    add  a, a
    ld   e, a
    ld   d, 0
    add  hl, de
    ld   e, [hl]
    inc  hl
    ld   d, [hl]
    ld   h, d
    ld   l, e

    call CopyTilemap20x18_HL_to_9800

    ; Scroll a 0
    xor  a
    ldh  [rSCX], a
    ldh  [rSCY], a

    call InitSprites

    call encender_LCD
    call wait_vBlank
    call UpdateRender
    ret

NextLevel::
    ld   a, [wLevelIdx]
    inc  a
    cp   LEVEL_COUNT
    jr   c, .noWrap
    xor  a
.noWrap:
    ld   [wLevelIdx], a
    call LoadLevelCurrent
    ret

; ----------------------------------------------------------
CopyTilemap20x18_HL_to_9800::
    ld   de, $9800
    ld   b, 18
.row:
    ld   c, 20
.col:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  c
    jr   nz, .col

    ld   a, e
    add  a, 12
    ld   e, a
    jr   nc, .noCarry
    inc  d
.noCarry:
    dec  b
    jr   nz, .row
    ret
