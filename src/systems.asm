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
    ; ---------------- Derecha ----------------
    ; bit 0 (KEY_RIGHT) en joypadActual
    ld   a, [joypadActual]
    bit  0, a
    jr   z, .chkLeft

    ld   a, [posX]
    inc  a
    ld   c, a            ; C = x candidato
    ld   a, [posY]
    ld   b, a            ; B = y actual
    call TestAabbRight16
    jr   z, .blockRight
    ld   hl, posX
    inc  [hl]            ; mueve 1 px a la derecha
    ld   a, 1
    ld   [animDir], a
    jr   .after_hmove
.blockRight:
    ld   a, 1
    ld   [animDir], a
    jr   .after_hmove

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
    dec  [hl]            ; mueve 1 px a la izquierda
    ld   a, 2
    ld   [animDir], a
    jr   .after_hmove
.blockLeft:
    ld   a, 2
    ld   [animDir], a

.no_input:
    xor  a
    ld   [animDir], a

.after_hmove:

    ;; === Física vertical: salto + gravedad + integración por píxel ===
    ; Jump con Up cuando estamos en el suelo
    ld   a, [joypadActual]
    bit  2, a                ; Up
    jr   z, .no_jump_input
    ld   a, [onGround]
    or   a
    jr   z, .no_jump_input
    ld   a, JUMP_SPEED
    ld   [velY], a
    xor  a
    ld   [onGround], a
.no_jump_input:

    ; v = clamp(v + GRAVITY, -128..TERMINAL_SPEED)
    ld   a, [velY]
    add  a, GRAVITY
    cp   TERMINAL_SPEED + 1
    jr   c, .no_clamp_pos
    ld   a, TERMINAL_SPEED
.no_clamp_pos:
    ld   [velY], a

    ; Integración por pasos de 1 px según el signo de velY
    ld   a, [velY]
    or   a
    jr   z, .done_vertical

    ld   c, a               ; C = velY (signed)
    bit  7, c
    jr   z, .falling        ; si no es negativo, estamos cayendo

.rising:
    ; n = (-velY)
    ld   a, c
    cpl
    inc  a
    ld   b, a               ; B = pasos
.rise_step:
    ; candidato y-1
    ld   a, [posY]
    dec  a
    ld   d, a               ; D = y'
    ld   a, [posX]
    ld   c, a               ; C = x
    ld   b, d               ; B = y'
    call TestAabbUp16
    jr   z, .hit_top
    ; aplicar
    ld   hl, posY
    dec  [hl]
    dec  b
    jr   nz, .rise_step
    jr   .done_vertical
.hit_top:
    xor  a
    ld   [velY], a
    jr   .done_vertical

.falling:
    ld   b, c               ; B = pasos (velY>0)
.fall_step:
    ; candidato y+1
    ld   a, [posY]
    inc  a
    ld   d, a               ; D = y'
    ld   a, [posX]
    ld   c, a               ; C = x
    ld   b, d               ; B = y'
    call TestAabbDown16
    jr   z, .hit_floor
    ; aplicar
    ld   hl, posY
    inc  [hl]
    dec  b
    jr   nz, .fall_step
    jr   .done_vertical
.hit_floor:
    xor  a
    ld   [velY], a
    inc  a
    ld   [onGround], a

.done_vertical:

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
    
    ldh  a,[rLCDC]
    res  5,a          ; WINDOW OFF
    set  4,a          ; BG/Win tile data = $8000 (no modo $8800 firmado)
    res  3,a          ; BG map = $9800 (no $9C00)
    ldh  [rLCDC],a

    xor  a
    ldh  [rSCX],a     ; sin scroll
    ldh  [rSCY],a
    ldh  [rWX],a      ; por si acaso, ventana lejos
    ldh  [rWY],a

    ; estado inicial
    ld   a, 120
    ld   [posX], a
    ld   a, 108
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

; === Colisión vertical 16x16: Borde INFERIOR ===
; C = x candidato (esquina sup-izq del hitbox), B = y
; Z=1 si HAY colisión en el borde inferior
TestAabbDown16::
    ; puntos: (x+2, y+15) y (x+13, y+15)
    ld a, c
    add a, 2
    ld d, a
    ld a, b
    add a, 15
    ld e, a
    ld a, d
    ld b, e
    call GetBgTileAtXY
    call IsTileSolid
    ret z

    ld a, c
    add a, 13
    ld d, a
    ld a, b
    add a, 15
    ld e, a
    ld a, d
    ld b, e
    call GetBgTileAtXY
    call IsTileSolid
    ret z

    or a
    ret

; === Colisión vertical 16x16: Borde SUPERIOR ===
; C = x candidato (esquina sup-izq del hitbox), B = y
; Z=1 si HAY colisión en el borde superior
TestAabbUp16::
    ; puntos: (x+2, y+1) y (x+13, y+1)
    ld a, c
    add a, 2
    ld d, a
    ld a, b
    add a, 1
    ld e, a
    ld a, d
    ld b, e
    call GetBgTileAtXY
    call IsTileSolid
    ret z

    ld a, c
    add a, 13
    ld d, a
    ld a, b
    add a, 1
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

