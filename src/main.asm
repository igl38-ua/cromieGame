; ===== main.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

; -------------------- WRAM (variables) --------------------
SECTION "GameStateVar", WRAM0
EXPORT wGameState
wGameState: ds 1

; -------------------- ROM0 (código) -----------------------
SECTION "Main", ROM0
EXPORT main

main::
    call Init

    ; Entramos en el menú de inicio
    call Title_Enter 
    xor  a 
    ld   [wGameState], a   ; STATE_TITLE = 0 

.loop
    call ReadInput

    ld   a, [wGameState]
    cp   STATE_TITLE
    jr   z, .doTitle 

    ; --- STATE_PLAY ---
    call UpdateMovement
    call UpdateRender
    jp   .loop

.doTitle:
    call Title_Update
    jp   .loop

; ---------------------------------------------------------------------------
; Copia 20x18 bytes desde _MapaBase a $9800, saltando 12 por fila (32-20)
; ---------------------------------------------------------------------------
SECTION "DrawMapaBase", ROM0
DrawMapaBase::
    ld   hl, _MapaBase        ; origen (definido en mapa_data.asm)
    ld   de, $9800            ; destino (BG map 0)
    ld   b, 18                ; 18 filas
.fila:
    ld   c, 20                ; 20 columnas
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
    jr   nz, .fila
    ret

; ---------------------------------------------------------------------------
; Tiles base mínimos para que el mapa se vea (índices 01, 06 y 07)
; ---------------------------------------------------------------------------
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
; (Alternativa: ds 16, $FF / ds 16, $AA / ds 16, $55)

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

; ---------------------------------------------------------------------------
; Inicialización
; ---------------------------------------------------------------------------
SECTION "Init", ROM0
Init::
    ; 1) LCD OFF antes de tocar VRAM
    call apagar_LCD            ; debe poner bit7(LCDC)=0 y esperar si hace falta

    ; 2) Limpia OAM
    call limpiar_OAM

    ; 3) Paleta de fondo y sprites
    ld   a, %11100100
    ldh  [rBGP], a             ; $FF47
    ldh  [rOBP0], a            ; $FF48
    ldh  [rOBP1], a            ; $FF49

    ; 5) Estas llamadas ahora las hace Play_Enter tras pulsar START:
    ; call LoadBaseTiles
    ; call DrawMapaBase
    ; xor  a
    ; ldh  [rSCX], a
    ; ldh  [rSCY], a
    ; call InitSprites
    ; call UpdateRender
    ret
