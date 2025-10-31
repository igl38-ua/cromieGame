INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"
INCLUDE "assets/sprites/jewmbo.z80"

SECTION "Systems", ROM0
EXPORT ReadInput, UpdateMovement, UpdateRender, InitSprites


; Configuración de tiles 
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

; Variables 
SECTION "Vars", WRAM0
posX:            DS 1
posY:            DS 1
contador:        DS 1
joypadActual:    DS 1
animFrame:       DS 1
animDir:         DS 1      ; 0 = quieto, 1 = derecha, 2 = izquierda
velY:            DS 1
onGround:        DS 1      ; 0/1 si está tocando el suelo


SECTION "SystemsCode", ROM0

; -------------------- Lectura de entrada --------------------
ReadInput::
    ld   a, $20
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  %00001111
    ld   [joypadActual], a
    ret

; -------------------- Movimiento y física --------------------
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
    ld   a, [joypadActual]
    bit  0, a
    jr   z, .chkLeft

    ld   a, [posX]
    inc  a
    ld   c, a
    ld   a, [posY]
    ld   b, a
    call TestAabbRight16
    jr   z, .blockRight
    ld   hl, posX
    inc  [hl]
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
    dec  [hl]
    ld   a, 2
    ld   [animDir], a
    jr   .after_hmove
.blockLeft:
    ld   a, 2
    ld   [animDir], a
    jr   .after_hmove

.no_input:
    xor  a
    ld   [animDir], a

.after_hmove:

    ;;  Salto + gravedad + integración por píxel 
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

    ld   a, [velY]
    add  a, GRAVITY
    cp   TERMINAL_SPEED + 1
    jr   c, .no_clamp_pos
    ld   a, TERMINAL_SPEED
.no_clamp_pos:
    ld   [velY], a

    ld   a, [velY]
    or   a
    jr   z, .done_vertical

    ld   c, a
    bit  7, c
    jr   z, .falling

.rising:
    ld   a, c
    cpl
    inc  a
    ld   b, a
.rise_step:
    ld   a, [posY]
    dec  a
    ld   d, a
    ld   a, [posX]
    ld   c, a
    ld   b, d
    call TestAabbUp16
    jr   z, .hit_top
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
    ld   b, c
.fall_step:
    ld   a, [posY]
    inc  a
    ld   d, a
    ld   a, [posX]
    ld   c, a
    ld   b, d
    call TestAabbDown16
    jr   z, .hit_floor
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
    ;  detección de puerta, tile $05
    call CheckDoorCollision

.done_move:
    ret

; Detecta si el jugador toca una puerta
CheckDoorCollision::
    ; derecha: (x+14,y+2) y (x+14,y+13)
    ld   a, [posX]
    add  14
    ld   c, a
    ld   a, [posY]
    add  2
    ld   b, a
    ld   a, c
    call GetBgTileAtXY
    cp   TILE_DOOR
    jr   z, .hitDoor
    ld   a, [posY]
    add  13
    ld   b, a
    ld   a, c
    call GetBgTileAtXY
    cp   TILE_DOOR
    jr   z, .hitDoor

    ; izquierda: (x+1,y+2) y (x+1,y+13)
    ld   a, [posX]
    add  1
    ld   c, a
    ld   a, [posY]
    add  2
    ld   b, a
    ld   a, c
    call GetBgTileAtXY
    cp   TILE_DOOR
    jr   z, .hitDoor
    ld   a, [posY]
    add  13
    ld   b, a
    ld   a, c
    call GetBgTileAtXY
    cp   TILE_DOOR
    jr   z, .hitDoor

    ; suelo: (x+2,y+15) y (x+13,y+15)
    ld   a, [posX]
    add  2
    ld   c, a
    ld   a, [posY]
    add  15
    ld   b, a
    ld   a, c
    call GetBgTileAtXY
    cp   TILE_DOOR
    jr   z, .hitDoor
    ld   a, [posX]
    add  13
    ld   c, a
    ld   a, b
    call GetBgTileAtXY
    cp   TILE_DOOR
    jr   z, .hitDoor

    ; techo: (x+2,y+1) y (x+13,y+1)
    ld   a, [posX]
    add  2
    ld   c, a
    ld   a, [posY]
    add  1
    ld   b, a
    ld   a, c
    call GetBgTileAtXY
    cp   TILE_DOOR
    jr   z, .hitDoor
    ld   a, [posX]
    add  13
    ld   c, a
    ld   a, b
    call GetBgTileAtXY
    cp   TILE_DOOR
    ret  nz
.hitDoor:
    call NextLevel
    ret

;  -------------------- Render --------------------
UpdateRender::
    call wait_vBlank

    ld a, [posX]
    ld [wPlayerX], a
    ld a, [posY]
    ld [wPlayerY], a

    ld   a, [wPlayerY]
    add  16
    ld   d, a
    ld   a, [wPlayerX]
    add  8
    ld   e, a

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
    ld   b, a

    ld   hl, HRAMShadowOAM
    ld   a, d
    ld   [hl+], a
    ld   a, e
    ld   [hl+], a
    ld   a, b
    ld   [hl+], a
    xor  a
    ld   [hl+], a

    ld   a, e
    add  8
    ld   e, a
    ld   a, d
    ld   [hl+], a
    ld   a, e
    ld   [hl+], a
    ld   a, b
    add  2
    ld   [hl+], a
    xor  a
    ld   [hl+], a

    call FlushOAM_HRAM
    ret

; InitSprites
InitSprites::
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

    ld   a, %11100100
    ldh  [rBGP], a
    ldh  [rOBP0], a

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

    ld   hl, HRAMShadowOAM
    ld   b, 8
    xor  a
.clear_hram:
    ld   [hl+], a
    dec  b
    jr   nz, .clear_hram
    ret


; Helpers de colisión con el BG 
GetBgTileAtXY::
    ld   e, a
    ld   d, b
    ldh  a, [rSCX]
    add  a, e
    ld   e, a
    ldh  a, [rSCY]
    add  a, d
    ld   d, a
    ld   c, e
    srl  c
    srl  c
    srl  c
    ld   a, d
    srl  a
    srl  a
    srl  a
    ld   h, 0
    ld   l, a
    add  hl, hl
    add  hl, hl
    add  hl, hl
    add  hl, hl
    add  hl, hl
    ld   a, l
    add  a, c
    ld   l, a
    ld   a, h
    adc  a, 0
    ld   h, a
    ld   de, $9800
    add  hl, de
    ld   a, [hl]
    ret

IsTileSolid::
    cp   TILE_SOLID
    ret

; Colisiones 
TestAabbRight16::
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

TestAabbDown16::
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

TestAabbUp16::
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

TestAabbLeft16::
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
