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
    dw _MapaBase
    dw _MapaSegundoNivel

; ----------------------------------------------------------
; LoadLevelCurrent
;   Carga tiles base, copia el tilemap del nivel actual a $9800,
;   resetea scroll, reinicializa sprites y enciende LCD.
; ----------------------------------------------------------
LoadLevelCurrent::
    ; 0) LCD OFF para escribir VRAM con seguridad
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

    ; Guarda el puntero del mapa en BC para identificarlo después
    ld   b, h
    ld   c, l

    ; 3) Copiar 20x18 -> $9800
    call CopyTilemap20x18_HL_to_9800

    ; 3.5) Si el mapa cargado es _Mapa1, tapar el hueco
    ld   de, _Mapa1            ; DE = &_Mapa1
    ld   a, c                  ; compara BC con DE (16-bit)
    sub  e
    ld   a, b
    sbc  a, d
    jr   nz, .skip_cover       ; si distinto, no es Mapa1

    ; --- Tapar hueco del Mapa1: columnas 9..10, filas 10..17 con tile $01 ---
    ld   a, $01                ; tile pared/suelo oscuro
    ld   b, 8                  ; alto
    ld   c, 2                  ; ancho
    ld   d, 10                 ; fila inicio
    ld   e, 9                  ; col  inicio
    call RellenaHueco
.skip_cover:

    ; 4) Scroll a 0
    xor  a
    ldh  [rSCX], a
    ldh  [rSCY], a

    ; 5) Reinit sprites
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
