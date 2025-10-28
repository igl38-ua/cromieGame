; ===== src/systems.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"
INCLUDE "assets/sprites/jewmbo.z80"

SECTION "Systems", ROM0
EXPORT ReadInput, UpdateMovement, UpdateRender, InitSprites

; --- Configuración de tiles ---
DEF JEWMBO_VRAM_ADDR EQU $8200
DEF TILE_BASE        EQU ((JEWMBO_VRAM_ADDR - $8000) / 16)

; Cada pose ocupa 4 tiles (2x2)
DEF JEWMBO_SET_SIZE EQU 4

; Índices para cada animación
DEF TILE_IDLE_BASE   EQU TILE_BASE + (0 * JEWMBO_SET_SIZE)   ; $20–$23
DEF TILE_RUNR1_BASE  EQU TILE_BASE + (1 * JEWMBO_SET_SIZE)   ; $24–$27
DEF TILE_RUNR2_BASE  EQU TILE_BASE + (2 * JEWMBO_SET_SIZE)   ; $28–$2B
DEF TILE_RUNL1_BASE  EQU TILE_BASE + (3 * JEWMBO_SET_SIZE)   ; $2C–$2F
DEF TILE_RUNL2_BASE  EQU TILE_BASE + (4 * JEWMBO_SET_SIZE)   ; $30–$33

; --- Variables ---
SECTION "Vars", WRAM0
posX:            DS 1
posY:            DS 1
contador:        DS 1
joypadActual:    DS 1
animFrame:       DS 1      ; controla alternancia entre paso 1 y 2
animDir:         DS 1      ; 0 = quieto, 1 = derecha, 2 = izquierda

; -------------------------------------------------
SECTION "SystemsCode", ROM0

; Leer entrada
ReadInput::
    ld   a, $20
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  %00001111
    ld   [joypadActual], a
    ret

; Movimiento + animación
UpdateMovement::
    ld   hl, contador
    inc  [hl]

    ld   a, [joypadActual]
    or   a
    jr   z, .no_input

    ld   a, [contador]
    and  %00000111          ; animación cada 8 frames
    jr   nz, .skip_anim
    ld   hl, animFrame
    inc  [hl]
    ld   a, [hl]
    and  1
    ld   [hl], a
.skip_anim:

    ld   a, [joypadActual]
    bit  0, a               ; derecha
    jr   z, .chkLeft
    ld   hl, posX
    inc  [hl]
    ld   a, 1               ; dir derecha
    ld   [animDir], a
    jr   .done_move

.chkLeft:
    bit  1, a               ; izquierda
    jr   z, .chkUp
    ld   hl, posX
    dec  [hl]
    ld   a, 2               ; dir izquierda
    ld   [animDir], a
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
    jr   .done_move

.no_input:
    xor  a
    ld   [animDir], a       ; quieto
.done_move:
    ret


; -------------------------------------------------
; Render con animación
UpdateRender::
    call wait_vBlank

    ; posición
    ld   a, [posY]
    add  16
    ld   d, a
    ld   a, [posX]
    add  8
    ld   e, a

    ; --- elegir base de tiles según animDir + animFrame ---
    ld   a, [animDir]
    or   a
    jr   z, .idle

    cp   1
    jr   z, .dirRight
    cp   2
    jr   z, .dirLeft
    jr   .idle

.dirRight:
    ld   a, [animFrame]
    and  1
    jr   z, .runR1
    ld   a, TILE_RUNR2_BASE
    jr   .haveTiles
.runR1:
    ld   a, TILE_RUNR1_BASE
    jr   .haveTiles

.dirLeft:
    ld   a, [animFrame]
    and  1
    jr   z, .runL1
    ld   a, TILE_RUNL2_BASE
    jr   .haveTiles
.runL1:
    ld   a, TILE_RUNL1_BASE
    jr   .haveTiles

.idle:
    ld   a, TILE_IDLE_BASE
.haveTiles:
    ld   b, a              ; base TL tile

    ; construimos HRAMShadowOAM
    ld   hl, HRAMShadowOAM

    ; --- Sprite 0 (izquierda) ---
    ld   a, d
    ld   [hl+], a          ; Y
    ld   a, e
    ld   [hl+], a          ; X
    ld   a, b              ; TL tile
    ld   [hl+], a
    xor  a
    ld   [hl+], a

    ; --- Sprite 1 (derecha) ---
    ld   a, e
    add  8
    ld   e, a
    ld   a, d
    ld   [hl+], a
    ld   a, e
    ld   [hl+], a
    ld   a, b
    add 2
    ; inc  a                 ; TR tile (siguiente)
    ld   [hl+], a
    xor  a
    ld   [hl+], a

    ; volcar HRAM -> OAM
    call FlushOAM_HRAM
    ret


; -------------------------------------------------
; InitSprites
InitSprites::
    ; apaga LCD
    ldh  a, [rLCDC]
    bit  7, a
    jr   z, .lcd_off
    res  7, a
    ldh  [rLCDC], a
.lcd_off:

    ; estado inicial
    ld   a, 80
    ld   [posX], a
    ld   a, 72
    ld   [posY], a
    xor  a
    ld   [contador], a
    ld   [animFrame], a
    ld   [animDir], a

    ; paletas
    ld   a, %11100100
    ldh  [rBGP], a
    ldh  [rOBP0], a

    ; --- copiar tiles de Jewmbo ---
    ; 5 poses * 4 tiles = 20 tiles = 320 bytes
    ld   hl, jewmbo
    ld   de, JEWMBO_VRAM_ADDR
    ld   b, 20
.copy_tile_loop:
    push bc
    ld   c, 16
.copy_tile_bytes:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  c
    jr   nz, .copy_tile_bytes
    pop  bc
    dec  b
    jr   nz, .copy_tile_loop

    ; limpia HRAMShadowOAM
    ld   hl, HRAMShadowOAM
    ld   b, 8
    xor  a
.clear_hram:
    ld   [hl+], a
    dec  b
    jr   nz, .clear_hram

    ; enciende LCD (modo 8x16)
    ld   a, %10010111
    ldh  [rLCDC], a
    ret
