INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

; -------------------- WRAM (variables) --------------------
SECTION "GameStateVar", WRAM0
EXPORT wGameState, wLevelIdx
wGameState: ds 1
wLevelIdx:  ds 1

; -------------------- ROM0 (código) -----------------------
SECTION "Main", ROM0
EXPORT main

main::
    call Init

    ; Menú de inicio
    call Title_Enter 
    xor  a 
    ld   [wGameState], a

.loop
    call ReadInput

    ld   a, [wGameState]
    cp   STATE_TITLE
    jr   z, .doTitle 

    call Play_HandleSelect
    call Play_Update

.doTitle:
    call Title_Update
    jp   .loop

SECTION "DrawMapaBase", ROM0
DrawMapaBase::
    ld   hl, _MapaBase
    ld   de, $9800
    ld   b, 18
.fila:
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
    jr   nz, .fila
    ret


; Tiles base mínimos para que el mapa se vea (índices 01, 06 y 07)
SECTION "DummyBGTiles", ROM0
Tile01::
REPT 16
    db $FF
ENDR

Tile06::
REPT 16
    db $AA
ENDR

Tile07::
REPT 16
    db $55
ENDR

SECTION "LoadBaseTiles", ROM0
LoadBaseTiles::
    ; Tile 01 -> $8000 + 16*1
    ld  hl, Tile01
    ld  de, $8000 + 16*1
    ld  b, 16
.copy01:
    ld  a,[hl+]
    ld  [de],a
    inc de
    dec b
    jr  nz,.copy01

    ; Tile 06 -> $8000 + 16*6
    ld  hl, Tile06
    ld  de, $8000 + 16*6
    ld  b, 16
.copy06:
    ld  a,[hl+]
    ld  [de],a
    inc de
    dec b
    jr  nz,.copy06

    ; Tile 07 -> $8000 + 16*7
    ld  hl, Tile07
    ld  de, $8000 + 16*7
    ld  b, 16
.copy07:
    ld  a,[hl+]
    ld  [de],a
    inc de
    dec b
    jr  nz,.copy07
    ret


;  -------------------- Inicialización --------------------
SECTION "Init", ROM0
Init::
    call apagar_LCD
    call limpiar_OAM

    ld   a, %11100100
    ldh  [rBGP], a             ; $FF47
    ldh  [rOBP0], a            ; $FF48
    ldh  [rOBP1], a            ; $FF49

    ret
