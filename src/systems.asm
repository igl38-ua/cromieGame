; ===== src/systems.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

INCLUDE "assets/sprites/jewmbo.z80"

SECTION "Systems", ROM0
EXPORT ReadInput, UpdateMovement, UpdateRender, InitSprites

; --- Config tiles en VRAM ---
DEF JEWMBO_VRAM_ADDR EQU $8200
DEF TILE_BASE        EQU ((JEWMBO_VRAM_ADDR - $8000) / 16)
DEF TILE_TL EQU TILE_BASE + 0    ; $20
DEF TILE_TR EQU TILE_BASE + 1    ; $21
DEF TILE_BL EQU TILE_BASE + 2    ; $22
DEF TILE_BR EQU TILE_BASE + 3    ; $23

; Variables de juego
SECTION "Vars", WRAM0
posX:            DS 1
posY:            DS 1
contador:        DS 1
joypadActual:    DS 1
sprites_inited:  DS 1

; -------------------------------------------------
SECTION "SystemsCode", ROM0

; Lee pad (4 direcciones)
ReadInput::
    ld   a, $20
    ldh  [rP1], a       ; seleccionar direccionales
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  %00001111
    ld   [joypadActual], a
    ret

; Movimiento simple sin colisiones
UpdateMovement::
    ld   hl, contador
    inc  [hl]

    ld   a, [joypadActual]
    or   a
    jr   z, .done_move

    ld   a, [contador]
    and  %00000011
    jr   nz, .done_move

    ld   a, [joypadActual]
    bit  0, a          ; derecha
    jr   z, .chkLeft
    ld   hl, posX
    inc  [hl]
    jr   .done_move

.chkLeft:
    bit  1, a          ; izquierda
    jr   z, .chkUp
    ld   hl, posX
    dec  [hl]
    jr   .done_move

.chkUp:
    bit  2, a          ; arriba
    jr   z, .chkDown
    ld   hl, posY
    dec  [hl]
    jr   .done_move

.chkDown:
    bit  3, a          ; abajo
    jr   z, .done_move
    ld   hl, posY
    inc  [hl]

.done_move:
    ret


; -------------------------------------------------
; UpdateRender
; - Calcula posición del jugador
; - Escribe SOLO los 2 sprites en HRAMShadowOAM
; - Copia HRAMShadowOAM -> OAM (rellenando el resto apagado)
; Requiere: LCD ya en modo 8x16 (bit2 de LCDC=1)
; -------------------------------------------------
UpdateRender::
    ; Esperamos al VBlank al principio del frame
    ; para que toda la escritura OAM sea estable
    call wait_vBlank

    ; Calculamos coords en espacio Game Boy (offsets +16 Y, +8 X)
    ld   a, [posY]
    add  16
    ld   d, a          ; D = Y pantalla
    ld   a, [posX]
    add  8
    ld   e, a          ; E = X pantalla

    ; Escribimos al buffer HRAMShadowOAM directamente
    ld   hl, HRAMShadowOAM

    ; --- Sprite 0 (izquierda) ---
    ld   a, d          ; Y
    ld   [hl+], a
    ld   a, e          ; X
    ld   [hl+], a
    ld   a, TILE_TL    ; tile superior izquierda ($20)
    ; En modo 8x16, PPU dibuja este tile y el tile siguiente ($21)
    ld   [hl+], a
    xor  a
    ld   [hl+], a      ; attrs = 0

    ; --- Sprite 1 (derecha) ---
    ld   a, e
    add  8
    ld   e, a
    ld   a, d
    ld   [hl+], a      ; Y
    ld   a, e
    ld   [hl+], a      ; X
    ld   a, TILE_BL    ; tile de la mitad derecha base ($22)
    ; PPU dibuja también $23 debajo automáticamente
    ld   [hl+], a
    xor  a
    ld   [hl+], a      ; attrs = 0

    ; Ahora volcamos a OAM:
    call FlushOAM_HRAM
    ret


; -------------------------------------------------
; InitSprites
; - Apaga LCD, copia tiles de Jewmbo a VRAM, inicializa estado, enciende LCD.
; -------------------------------------------------
InitSprites::
    ; apaga LCD si está ON
    ldh  a, [rLCDC]
    bit  7, a
    jr   z, .lcd_off
    res  7, a
    ldh  [rLCDC], a
.lcd_off:

    ; estado inicial jugador
    ld   a, 80
    ld   [posX], a
    ld   a, 72
    ld   [posY], a
    xor  a
    ld   [contador], a
    ld   [sprites_inited], a  ; 0 -> (no la usamos ya, pero la dejamos limpia)

    ; paletas
    ld   a, %11100100
    ldh  [rBGP], a
    ldh  [rOBP0], a

    ; copiar las 4 tiles (64 bytes) de jewmbo a VRAM $8200
    ld   hl, jewmbo
    ld   de, JEWMBO_VRAM_ADDR
    ld   b, 4          ; 4 tiles
.copy_tile_loop:
    push bc
    ld   c, 16         ; 16 bytes por tile
.copy_tile_bytes:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  c
    jr   nz, .copy_tile_bytes
    pop  bc
    dec  b
    jr   nz, .copy_tile_loop

    ; inicializa HRAMShadowOAM a 0 (por si acaso antes del primer frame)
    ld   hl, HRAMShadowOAM
    ld   b, 8
    xor  a
.init_hram_loop:
    ld   [hl+], a
    dec  b
    jr   nz, .init_hram_loop

    ; enciende LCD en:
    ; bit7 LCD on
    ; bit6 Window tile map (0 = $9800, no usamos window ahora)
    ; bit5 Window enable (0)
    ; bit4 BG tiles from $8000
    ; bit3 BG map $9800
    ; bit2 OBJ size 1=8x16
    ; bit1 OBJ enable
    ; bit0 BG enable
    ld   a, %10010111      ; 1 0 0 1 0 1 1 1  = $97
    ldh  [rLCDC], a

    ret
