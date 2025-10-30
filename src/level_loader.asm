; ===== src/level_loader.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

SECTION "LevelLoader", ROM0
EXPORT LoadLevelCurrent, NextLevel

; Necesitamos usar wLevelTilePtr (WRAM) exportado desde su módulo (p.ej., components.asm)
; Asegúrate de tener allí:
;   SECTION "LevelPtr", WRAM0
;   EXPORT wLevelTilePtr
;   wLevelTilePtr: DS 2

SECTION "LevelTable", ROM0
; Tabla de niveles: punteros a tilemaps 20x18
; Debes tener definidos _MapaBase y _MapaSegundoNivel en tus assets
LevelMaps:
    dw _MapaBase
    dw _MapaSegundoNivel


; -----------------------------------------
; Carga el nivel actual (índice en wLevelIdx)
; - Apaga LCD
; - Carga tiles base (fon/tileset)               [LoadBaseTiles -> debes tenerla en otro módulo]
; - Resuelve puntero a tilemap y lo guarda en wLevelTilePtr
; - Copia tilemap a $9800
; - Construye wCollMap
; - InitSprites y coloca jugador
; - Enciende LCD y primer render
; -----------------------------------------
LoadLevelCurrent::
    call apagar_LCD
    call LoadBaseTiles

    ; HL = puntero tilemap del nivel [wLevelIdx]
    ld   hl, LevelMaps
    ld   a, [wLevelIdx]      ; (exportada en main.asm)
    add  a, a                ; *2
    ld   e, a
    ld   d, 0
    add  hl, de
    ld   e, [hl]
    inc  hl
    ld   d, [hl]
    ld   h, d
    ld   l, e                ; HL = ptr tilemap 20x18

    ; --- Guardar puntero del tilemap en WRAM (para lectura directa de tiles, p.ej. pinchos)
    ld   a, l
    ld   [wLevelTilePtr], a
    ld   a, h
    ld   [wLevelTilePtr+1], a

    ; --- Copiar tilemap 20x18 a BG Map 0 ($9800)
    push hl
    call CopyTilemap20x18_HL_to_9800
    pop  hl

    ; --- Construir mapa de colisión (0 libre / 1 sólido)
    call BuildCollisionMap_HL
    ; Scroll a 0
    xor  a
    ldh  [rSCX], a
    ldh  [rSCY], a

    ; IMPORTANTE: InitSprites ANTES de PlacePlayerOnFreeTile
    call InitSprites
    call PlacePlayerOnFreeTile

    call encender_LCD
    call UpdateRender
    ret


; -----------------------------------------
; Avanza al siguiente nivel (cíclico) y carga
; -----------------------------------------
NextLevel::
    ld   a, [wLevelIdx]
    inc  a
    cp   LEVEL_COUNT
    jr   c, .ok
    xor  a
.ok:
    ld   [wLevelIdx], a
    call LoadLevelCurrent
    ret


; -----------------------------------------
SECTION "LevelCopy", ROM0
; HL -> tilemap 20x18, copia en $9800 con stride de 32 (salta 12 por fila)
CopyTilemap20x18_HL_to_9800::
    ld   de, $9800
    ld   b, MAP_H          ; 18 filas
.row:
    ld   c, MAP_W          ; 20 columnas
.col:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  c
    jr   nz, .col
    ld   a, e
    add  a, 12             ; saltar 12 hasta siguiente fila
    ld   e, a
    jr   nc, .noCarry
    inc  d
.noCarry:
    dec  b
    jr   nz, .row
    ret

SECTION "BuildColl", ROM0
BuildCollisionMap_HL::
    ld   de, wCollMap
    ld   b, MAP_H
.r:
    ld   c, MAP_W
.c:
    ld   a, [hl+]          ; tile id

    or   a                 ; ¿$00?
    jr   z, .free          ; $00 => libre
    ld   a, 1              ; !=$00 => sólido ($01, $02..$06, etc.)
    jr   .store
.free:
    xor  a                 ; 0 = libre
.store:
    ld   [de], a
    inc  de
    dec  c
    jr   nz, .c
    dec  b
    jr   nz, .r
    ret

