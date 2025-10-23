; ===== src/systems.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

; --- Datos de sprite del jugador (4 tiles TL,TR,BL,BR)
INCLUDE "assets/sprites/jewmbo.z80"    ; jewmbo::, jewmbo_end::, JEWMBO_TILE_COUNT

; --- Exportamos las 3 rutinas llamadas desde main.asm
SECTION "Systems", ROM0
EXPORT ReadInput, UpdateMovement, UpdateRender, InitSprites

; --- Configuración de tiles ---
; Cargaremos 'jewmbo' en $8200 => índice base = ($8200-$8000)/16 = $20
DEF JEWMBO_VRAM_ADDR EQU $8200
DEF TILE_BASE        EQU ((JEWMBO_VRAM_ADDR - $8000) / 16)

; Tile indices para sprite base (20–23)
DEF TILE_TL EQU TILE_BASE + 0    ; $20
DEF TILE_TR EQU TILE_BASE + 1    ; $21
DEF TILE_BL EQU TILE_BASE + 2    ; $22
DEF TILE_BR EQU TILE_BASE + 3    ; $23

; --- Variables en WRAM ---
SECTION "Vars", WRAM0
posX:            DS 1
posY:            DS 1
contador:        DS 1
joypadActual:    DS 1
sprites_inited:  DS 1

; -------------------------------------------------------------------
SECTION "SystemsCode", ROM0

; -------------------------------------------------------------------
; Leer entrada del pad (igual que en ejemplo.asm)
ReadInput::
    ld   a, $20
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  %00001111
    ld   [joypadActual], a
    ret

; -------------------------------------------------------------------
; Movimiento básico (sin colisiones)
UpdateMovement::
    ld   hl, contador
    inc  [hl]

    ld   a, [joypadActual]
    or   a
    jr   z, .done_move

    ; movimiento cada 4 frames
    ld   a, [contador]
    and  %00000011
    jr   nz, .done_move

    ld   a, [joypadActual]
    bit  0, a
    jr   z, .chkLeft
    ld   hl, posX
    inc  [hl]
    jr   .done_move

.chkLeft:
    bit  1, a
    jr   z, .chkUp
    ld   hl, posX
    dec  [hl]
    jr   .done_move

.chkUp:
    bit  2, a
    jr   z, .chkDown
    ld   hl, posY
    dec  [hl]
    jr   .done_move

.chkDown:
    bit  3, a
    jr   z, .done_move
    ld   hl, posY
    inc  [hl]

.done_move:
    ret

; -------------------------------------------------------------------
; Render del sprite base de Jewmbo (2x2 tiles fijas: 20–23)
; === JEWMBO render 8x16 ===
;   Sprite 0: Left half (TL=$20, BL=$22)
;   Sprite 1: Right half (TR=$21, BR=$23)

UpdateRender::
    call wait_vBlank

    ; --- Cargar posición base ---
    ld   a, [posY]
    add  16                  ; ajustar coordenada GB
    ld   d, a                ; D = Y
    ld   a, [posX]
    add  8
    ld   e, a                ; E = X

    ld   hl, $C000           ; ShadowOAM base

    ; --- Sprite 0: izquierda (TL=$20, BL=$22) ---
    ld   a, d
    ld   [hl+], a            ; Y
    ld   a, e
    ld   [hl+], a            ; X
    ld   a, $20              ; tile superior izquierda
    ld   [hl+], a
    xor  a
    ld   [hl+], a            ; atributos

    ; --- Sprite 1: derecha (TR=$21, BR=$23) ---
    ld   a, e
    add  8
    ld   e, a
    ld   a, d
    ld   [hl+], a            ; Y
    ld   a, e
    ld   [hl+], a            ; X
    ld   a, $22              ; tile superior derecha
    ld   [hl+], a
    xor  a
    ld   [hl+], a            ; atributos

    
    ld   hl, $C000 + 8
    ld   b, 38
    .hide_loop:
        xor  a                 ; a = 0 -> Y=0 (fuera de pantalla)
        ld   [hl], a
        ld   de, 4
        add  hl, de            ; avanzar a la siguiente entrada (Y del próximo sprite)
        dec  b
        jr   nz, .hide_loop

    ; --- Copia ShadowOAM -> OAM durante VBlank ---
    call FlushOAM
    ret

; -------------------------------------------------------------------
; Inicializa VRAM/OAM (solo una vez)
InitSprites:
    ; apaga LCD si está encendido
    ldh  a, [rLCDC]
    bit  7, a
    jr   z, .lcd_off
    res  7, a
    ldh  [rLCDC], a
    .lcd_off:

        ; posición inicial
        ld   a, 80
        ld   [posX], a
        ld   a, 72
        ld   [posY], a
        xor  a
        ld   [contador], a

        ; paletas
        ld   a, %11100100
        ldh  [rBGP], a
        ldh  [rOBP0], a

        ; copiar tiles de Jewmbo (4 tiles = 64 bytes)
        ld   hl, jewmbo
        ld   de, JEWMBO_VRAM_ADDR
        ld   b, 4
    .copy_tile_loop:
        push bc
        ld   c, 16
    .copy_one_tile:
        ld   a, [hl+]
        ld   [de], a
        inc  de
        dec  c
        jr   nz, .copy_one_tile
        pop  bc
        dec  b
        jr   nz, .copy_tile_loop

        ; limpiar ShadowOAM
        ld   hl, $C000
        ld   c, 160
    .clear_oam:
        xor  a
        ld   [hl+], a
        dec  c
        jr   nz, .clear_oam

        ld   a, 1
        ld   [sprites_inited], a

        ; reactivar LCD
        ld   a, %10010111   ; LCD ON + BG ON + OBJ ON + OBJ 8x16 + map $9800
        ldh  [rLCDC], a
        ret

; -------------------------------------------------------------------
; Copia ShadowOAM ($C000) a OAM ($FE00)
FlushOAM:
    ld   hl, $C000
    ld   de, $FE00
    ld   b, 160
.copy:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  b
    jr   nz, .copy
    ret
