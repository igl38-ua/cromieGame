; ===== src/systems.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

; --- Datos de sprite del jugador (4 tiles TL,TR,BL,BR)
; Asegúrate en assets/sprites/jewmbo.z80 de tener:
;   DEF JEWMBO_TILE_COUNT = (jewmbo_end - jewmbo) / 16
INCLUDE "assets/sprites/jewmbo.z80"    ; jewmbo::, jewmbo_end::, JEWMBO_TILE_COUNT

; --- Exportamos las 3 rutinas llamadas desde main.asm
SECTION "Systems", ROM0
EXPORT ReadInput, UpdateMovement, UpdateRender

; --- Índices de tile en VRAM para el jugador ---
; Cargaremos 'jewmbo' en $8200 => índice base = ($8200-$8000)/16 = $20 (32)
DEF JEWMBO_VRAM_ADDR EQU $8200
DEF TILE_BASE        EQU ((JEWMBO_VRAM_ADDR - $8000) / 16)

DEF TILE_TL      EQU TILE_BASE + 0
DEF TILE_TR      EQU TILE_BASE + 1
DEF TILE_BL      EQU TILE_BASE + 2
DEF TILE_BR      EQU TILE_BASE + 3

; Compat con ejemplo.asm (2 tiles superiores)
DEF TILE_L         EQU TILE_TL
DEF TILE_R         EQU TILE_TR
DEF TILE_RUN1_L    EQU TILE_TL
DEF TILE_RUN1_R    EQU TILE_TR
DEF TILE_RUN2_L    EQU TILE_TL
DEF TILE_RUN2_R    EQU TILE_TR

; --- Variables en WRAM ---
SECTION "Vars", WRAM0
posX:            DS 1
posY:            DS 1
contador:        DS 1
enMovimiento:    DS 1
joypadActual:    DS 1
sprites_inited:  DS 1

; >>> Volvemos a ROM0 para el código <<<
SECTION "SystemsCode", ROM0

; -------------------------------------------------------------------
; Joypad (mismo flujo que tu ejemplo)
ReadInput::
    ld   a, $20
    ldh  [rP1], a
    ldh  a, [rP1]      ; dummy
    ldh  a, [rP1]      ; real
    cpl
    and  %00001111
    ld   [joypadActual], a
    ret

; -------------------------------------------------------------------
; Movimiento básico sin colisiones (1 px cada 4 frames)
UpdateMovement::
    ld   hl, contador
    inc  [hl]

    xor  a
    ld   [enMovimiento], a

    ld   a, [joypadActual]
    or   a
    jr   z, .done_move
    ld   a, 1
    ld   [enMovimiento], a

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
; Render: init perezoso + compone 2×2 + copia ShadowOAM->OAM en VBlank
; -------------------------------------------------------------------
; Render: init perezoso + compone 2×2 + copia ShadowOAM->OAM en VBlank
UpdateRender::
    ; 1ª vez: carga tiles de jewmbo a VRAM, limpia OAM, etc.
    ld   a, [sprites_inited]
    ; or   a
    ; jr   nz, .skip_init
    call InitSprites
.skip_init:

    ; === SIEMPRE sprite base, sin animación ===
    ld   a, TILE_L        ; TL
    ld   b, TILE_R        ; TR
    ld   c, a             ; C = tile izq (TL)

    ; posiciones (GB: y+16, x+8)
    ld   hl, posY
    ld   a, [hl]
    add  16
    ld   d, a

    ld   hl, posX
    ld   a, [hl]
    add  8
    ld   e, a

    ; ---------- ShadowOAM (4 sprites) ----------
    ; TL
    ld   hl, $C000
    ld   a, d
    ld   [hl+], a
    ld   a, e
    ld   [hl+], a
    ld   a, c           ; TILE_L
    ld   [hl+], a
    xor  a
    ld   [hl], a

    ; TR (x+8)
    ld   a, e
    add  8
    ld   e, a
    ld   hl, $C000 + 4
    ld   a, d
    ld   [hl+], a
    ld   a, e
    ld   [hl+], a
    ld   a, b           ; TILE_R
    ld   [hl+], a
    xor  a
    ld   [hl], a

    ; BL (y+8)
    ld   a, d
    add  8
    ld   d, a
    ld   hl, $C000 + 8
    ld   a, d
    ld   [hl+], a
    ld   a, e
    sub  8
    ld   [hl+], a
    ld   a, TILE_BL
    ld   [hl+], a
    xor  a
    ld   [hl], a

    ; BR (x+8)
    ld   a, e
    add  8
    ld   e, a
    ld   hl, $C000 + 12
    ld   a, d
    ld   [hl+], a
    ld   a, e
    ld   [hl+], a
    ld   a, TILE_BR
    ld   [hl+], a
    xor  a
    ld   [hl], a

    ; --- Copia ShadowOAM -> OAM durante VBlank ---
    call wait_vBlank
    call FlushOAM
    ret

; -------------------------------------------------------------------
; Helpers
InitSprites:
    ; pos inicial
    ld   a, 80
    ld   [posX], a
    ld   a, 72
    ld   [posY], a
    xor  a
    ld   [contador], a
    ld   [enMovimiento], a

    ; paletas
    ld   a, %11100100
    ldh  [rBGP], a
    ldh  [rOBP0], a

    ; --- Copia de tiles del jugador a VRAM $8200 (4*16 = 64 bytes) ---
    ; Si LCD está ON, espera VBlank; si está OFF, copia directa
    ldh  a, [rLCDC]
    bit  7, a
    jr   z, .copy_tiles          ; LCD OFF -> copiar sin esperar

    ; LCD ON -> entrar en VBlank
    .waitVB:
        ldh  a, [rLY]
        cp   144
        jr   c, .waitVB

    .copy_tiles:
        ld   hl, jewmbo              ; origen ROM
        ld   de, JEWMBO_VRAM_ADDR    ; destino VRAM ($8200)
        ld   c, JEWMBO_TILE_COUNT * 16   ; 64 bytes
    .copy_loop:
        ld   a, [hl]
        ld   [de], a
        inc  hl
        inc  de
        dec  c
        jr   nz, .copy_loop

        ; --- ShadowOAM limpio (por si acaso) ---
        ld   hl, $C000               ; ShadowOAM
        ld   c, 160
        .clear_oam:
            xor  a
            ld   [hl+], a
            dec  c
            jr   nz, .clear_oam

        ld   a, 1
        ld   [sprites_inited], a
    ret

; Copia 160 bytes de ShadowOAM ($C000) a OAM ($FE00)
FlushOAM:
    ld   hl, $C000          ; ShadowOAM
    ld   de, $FE00          ; OAM
    ld   b, 160
.copy:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  b
    jr   nz, .copy
    ret
