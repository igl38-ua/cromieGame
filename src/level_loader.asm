; ===== src/level_loader.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

SECTION "LevelLoaderVars", WRAM0
; wLevelIdx lo define y exporta main.asm; aquí solo lo usamos.

SECTION "LevelLoader", ROM0
EXPORT LoadLevelCurrent, NextLevel

; Tabla de mapas (punteros a tilemaps 20x18)
SECTION "LevelTable", ROM0
LevelMaps:
    dw _Mapa1
    dw _Mapa2
    dw _Mapa3
    dw _MapaBase
    dw _MapaSegundoNivel

; ----------------------------------------------------------
; LoadLevelCurrent
;   Carga tiles base, copia el tilemap del nivel actual a $9800,
;   resetea scroll, reinicializa sprites y enciende LCD.
; ----------------------------------------------------------
LoadLevelCurrent::
    ; 0) LCD OFF seguro
    call wait_vBlank
    call apagar_LCD

    ; 1) Tiles comunes
    call LoadBaseTiles

    ; 2) HL = &LevelMaps[wLevelIdx*2], HL <- puntero tilemap
    ld   hl, LevelMaps
    ld   a, [wLevelIdx]
    add  a, a                  ; *2
    ld   e, a
    ld   d, 0
    add  hl, de
    ld   e, [hl]
    inc  hl
    ld   d, [hl]
    ld   h, d
    ld   l, e                  ; HL = ptr tilemap (20x18)

    ; 3) Copiar 20x18 -> $9800 (con “tapado” si wLevelIdx==0)
    call CopyTilemap20x18_HL_to_9800

    ; 4) Scroll a 0
    xor  a
    ldh  [rSCX], a
    ldh  [rSCY], a

    ; 5) Reinit sprites (no enciende LCD si ya está ON)
    call InitSprites

    ; 6) LCD ON y render
    call encender_LCD
    call wait_vBlank
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
; CopyTilemap20x18_HL_to_9800 (con tapado integrado para Mapa1)
;   Copia 20x18 bytes desde [HL] a $9800, saltando 12 por fila.
;   Si wLevelIdx==0 (Mapa1), fuerza tile $01 en columnas 9..10 y
;   filas 10..17 (coordenadas 0-based) durante la copia.
; ----------------------------------------------------------
CopyTilemap20x18_HL_to_9800::
    ld   de, $9800
    ld   b, 18                  ; filas
.row:
    ld   c, 20                  ; columnas
.col:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  c
    jr   nz, .col

    ; saltar 12 hasta siguiente fila
    ld   a, e
    add  a, 12
    ld   e, a
    jr   nc, .noCarry
    inc  d
.noCarry:
    dec  b
    jr   nz, .row
    ret
