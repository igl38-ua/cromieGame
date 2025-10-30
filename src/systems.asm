INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"
INCLUDE "assets/sprites/jewmbo.z80"

SECTION "Systems", ROM0
EXPORT ReadInput, UpdateMovement, UpdateRender, InitSprites

; --- Configuración de tiles ---
DEF JEWMBO_VRAM_ADDR EQU $8200
DEF TILE_BASE        EQU ((JEWMBO_VRAM_ADDR - $8000) / 16)

; Cada pose ocupa 4 tiles (2x2)
DEF JEWMBO_SET_SIZE  EQU 4

; Índices para cada animación
DEF TILE_IDLE_BASE   EQU TILE_BASE + (0 * JEWMBO_SET_SIZE)   ; $20–$23
DEF TILE_RUNR1_BASE  EQU TILE_BASE + (1 * JEWMBO_SET_SIZE)   ; $24–$27
DEF TILE_RUNR2_BASE  EQU TILE_BASE + (2 * JEWMBO_SET_SIZE)   ; $28–$2B
DEF TILE_RUNL1_BASE  EQU TILE_BASE + (3 * JEWMBO_SET_SIZE)   ; $2C–$2F
DEF TILE_RUNL2_BASE  EQU TILE_BASE + (4 * JEWMBO_SET_SIZE)   ; $30–$33

; --- Variables (player local a este sistema) ---
SECTION "Vars", WRAM0
posX:            DS 1
posY:            DS 1
contador:        DS 1
joypadActual:    DS 1
animFrame:       DS 1
animDir:         DS 1      ; 0 = quieto, 1 = derecha, 2 = izquierda
velY:           DS 1      ; velocidad vertical (signed)
onGround:       DS 1      ; 0/1 si está tocando el suelo


SECTION "SystemsCode", ROM0
; -----------------------
; Lectura de entrada
ReadInput::
    ld   a, $20
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  %00001111
    ld   [joypadActual], a
    ret

; -----------------------
; Movimiento + animación (solo izquierda/derecha con colisiones)
UpdateMovement::

    ld   hl, contador
    inc  [hl]

    ld   a, [joypadActual]
    or   a
    jp   z, .no_input

    ; animación cada 8 frames
    ld   a, [contador]
    and  %00000111
    jr   nz, .skip_anim
    ld   hl, animFrame
    inc  [hl]
    ld   a, [hl]
    and  1
    ld   [hl], a
.skip_anim:

    ; -------- Horizontal --------
    ld   a, [joypadActual]

    ; ---------------- Derecha ----------------
    bit  0, a
    jr   z, .chkLeft

    ld   a, [posX]
    inc  a
    ld   c, a            ; C = x candidato
    ld   a, [posY]
    ld   b, a            ; B = y actual
    
    call TestAabbRight16
    jr   z, .blockRight  ; Z=1 → hay colisión, no mover
    
    ld   hl, posX
    inc  [hl]            ; mueve 1 px derecha
    ld   a, 1
    ld   [animDir], a
    jr   .done_move
.blockRight:
    ld   a, 1
    ld   [animDir], a
    jr   .done_move

    ; ---------------- Izquierda ----------------
.chkLeft:
    bit  1, a
    jr   z, .no_input

    ld   a, [posX]
    dec  a
    ld   c, a
    ld   a, [posY]
    ld   b, a
    
    call TestAabbLeft16
    jr   z, .blockLeft
    
    ld   hl, posX
    dec  [hl]            ; mueve 1 px izquierda
    ld   a, 2
    ld   [animDir], a
    jr   .done_move
.blockLeft:
    ld   a, 2
    ld   [animDir], a
    jr   .done_move

.no_input:
    xor  a
    ld   [animDir], a

.done_move:
    ret

; Render con animación (sin cambios)
UpdateRender::
    call wait_vBlank

    ; sincronizar variables locales con las globales de render
    ld a, [posX]
    ld [wPlayerX], a
    ld a, [posY]
    ld [wPlayerY], a

    ; posición (ajustes de centrado tal y como tenías)
    ld   a, [wPlayerY]
    add  16
    ld   d, a
    ld   a, [wPlayerX]
    add  8
    ld   e, a

    ; elegir base de tiles
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

    ; HRAMShadowOAM
    ld   hl, HRAMShadowOAM

    ; Sprite 0 (izquierda)
    ld   a, d
    ld   [hl+], a          ; Y
    ld   a, e
    ld   [hl+], a          ; X
    ld   a, b              ; TL tile
    ld   [hl+], a
    xor  a
    ld   [hl+], a

    ; Sprite 1 (derecha)
    ld   a, e
    add  8
    ld   e, a
    ld   a, d
    ld   [hl+], a
    ld   a, e
    ld   [hl+], a
    ld   a, b
    add 2
    ld   [hl+], a
    xor  a
    ld   [hl+], a

    ; volcar HRAM -> OAM
    call FlushOAM_HRAM
    ret

; -------------------------------------------------
; InitSprites (sin cambios)
InitSprites::
    ; apaga LCD
    call apagar_LCD

    ; estado inicial
    ld   a, 40
    ld   [posX], a
    ld   a, 64
    ld   [posY], a
    xor  a
    ld   [contador], a
    ld   [animFrame], a
    ld   [animDir], a
    ld   [velY], a
    ld   [onGround], a

    ; paletas
    ld   a, %11100100
    ldh  [rBGP], a
    ldh  [rOBP0], a

    ; copiar tiles de Jewmbo (5*4 tiles = 20 tiles = 320 bytes)
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

    ; NO encender LCD aquí (lo hace el caller tras escribir VRAM)
    ret


; -------------------------------------------------
; === Helpers de colisión con el BG ===
; AABB de 16x16 px (usa PLAYER_W/H si los cambias)
; Convenciones:
;   - TILE_SOLID ($01) es sólido (pared/suelo).
;   - BG map en $9800. Sin scroll (SCX/SCY = 0).
;   - Si activas scroll, avísame y sumamos SCX/SCY antes del >>3.

; A = x en píxeles (pantalla)
; B = y en píxeles (pantalla)
; Ret: A = id de tile en BG map ($9800), teniendo en cuenta SCX/SCY
; Clobbers: C, D, E, H, L
GetBgTileAtXY::
    ; Guardar x,y en E,D
    ld   e, a            ; E = x
    ld   d, b            ; D = y

    ; x' = x + SCX (wrap 8-bit)
    ldh  a, [rSCX]       ; A = SCX
    add  a, e            ; A = SCX + x
    ld   e, a            ; E = x'

    ; y' = y + SCY (wrap 8-bit)
    ldh  a, [rSCY]       ; A = SCY
    add  a, d            ; A = SCY + y
    ld   d, a            ; D = y'

    ; tileX = x' >> 3  (en C)
    ld   c, e
    srl  c
    srl  c
    srl  c

    ; tileY = y' >> 3  (en A)
    ld   a, d
    srl  a
    srl  a
    srl  a

    ; HL = tileY * 32
    ld   h, 0
    ld   l, a
    add  hl, hl          ; *2
    add  hl, hl          ; *4
    add  hl, hl          ; *8
    add  hl, hl          ; *16
    add  hl, hl          ; *32

    ; HL += tileX
    ld   a, l
    add  a, c
    ld   l, a
    ld   a, h
    adc  a, 0
    ld   h, a

    ; HL += $9800
    ld   de, $9800
    add  hl, de

    ld   a, [hl]         ; A = tile id
    ret


; A = tile id
; Ret: Z=1 si SÓLIDO, Z=0 si NO sólido
IsTileSolid::
    cp   TILE_SOLID
    ret

; === Colisión horizontal 16x16: Borde DERECHO ===
; C = x candidato (esquina sup-izq del hitbox), B = y
; Z=1 si HAY colisión en el borde derecho
TestAabbRight16::
    ; puntos: (x+14,y+2) y (x+14,y+13)  ← si ves bloqueos "antes", cambia 14→13
    ld a, c
    add a, 14
    ld d, a
    ld a, b
    add a, 2
    ld e, a
    ld a, d
    ld b, e
    call GetBgTileAtXY
    call IsTileSolid
    ret z

    ld a, c
    add a, 14
    ld d, a
    ld a, b
    add a, 13
    ld e, a
    ld a, d
    ld b, e
    call GetBgTileAtXY
    call IsTileSolid
    ret z

    or a
    ret

; === Colisión horizontal 16x16: Borde IZQUIERDO ===
; C = x candidato (esquina sup-izq del hitbox), B = y
; Z=1 si HAY colisión en el borde izquierdo
TestAabbLeft16::
    ; puntos: (x+1,y+2) y (x+1,y+13)
    ; (si se cuela 1 px, cambia 1→0 para ser MÁS estricto)
    ld a, c
    add a, 1
    ld d, a
    ld a, b
    add a, 2
    ld e, a
    ld a, d
    ld b, e
    call GetBgTileAtXY
    call IsTileSolid
    ret z

    ld a, c
    add a, 1
    ld d, a
    ld a, b
    add a, 13
    ld e, a
    ld a, d
    ld b, e
    call GetBgTileAtXY
    call IsTileSolid
    ret z

    or a
    ret

