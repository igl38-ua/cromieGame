; ===== src/level_loader.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

SECTION "LevelLoaderVars", WRAM0
; wLevelIdx lo define y exporta main.asm; aquí solo lo usamos.

SECTION "LevelLoader", ROM0
EXPORT LoadLevelCurrent, NextLevel

; Tabla de mapas (punteros a tilemaps 20x18)
; Asegúrate de que estos labels existen en tus ficheros de mapas.
; En tus nombres: MapaBase.rgbds.asm y MapaSegundoNivel.rgbds.asm
; Suelen definirse como: _MapaBase y _MapaSegundoNivel
SECTION "LevelTable", ROM0
LevelMaps:
    dw _MapaBase
    dw _MapaSegundoNivel
    ; Cambiar los nombres y para añadir más mapas hacer: 
    ; dw _Mapa3
    ; dw _Mapa4
    ; ...

; ----------------------------------------------------------
; LoadLevelCurrent
;   Carga tiles base, copia el tilemap del nivel actual a $9800,
;   resetea scroll, reinicializa sprites y enciende LCD.
; ----------------------------------------------------------
LoadLevelCurrent::
    ; 0) Apagar LCD para escribir VRAM sin riesgo
    call apagar_LCD

    ; 1) Tiles (si todos los niveles comparten tileset, con esto basta)
    call LoadBaseTiles

    ; 2) Obtener puntero HL al tilemap del nivel [wLevelIdx]
    ; HL = LevelMaps + (wLevelIdx * 2)
    ld   hl, LevelMaps
    ld   a, [wLevelIdx]
    add  a, a              ; *2
    ld   e, a
    ld   d, 0
    add  hl, de
    ; HL apunta a la entrada; cargar puntero del tilemap a HL
    ld   e, [hl]
    inc  hl
    ld   d, [hl]
    ld   h, d
    ld   l, e              ; HL = ptr tilemap 20x18

    ; 3) Copiar 20x18 desde HL a $9800 (saltando 12 por fila)
    call CopyTilemap20x18_HL_to_9800

    ; 4) Scroll a 0
    xor  a
    ldh  [rSCX], a
    ldh  [rSCY], a

    ; 5) Reinit sprites (como hacías en Play_Enter original)
    call InitSprites

    ; 6) LCD ON y render
    call encender_LCD
    call UpdateRender
    ret

; ----------------------------------------------------------
; NextLevel
;   Avanza wLevelIdx = (wLevelIdx+1) % LEVEL_COUNT y carga.
; ----------------------------------------------------------
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
; CopyTilemap20x18_HL_to_9800
;   Copia 20x18 bytes desde [HL] a $9800, saltando 12 por fila.
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

    ; saltar 12 posiciones hasta inicio de la siguiente fila de BG
    ld   a, e
    add  a, 12
    ld   e, a
    jr   nc, .noCarry
    inc  d
.noCarry:
    dec  b
    jr   nz, .row
    ret
