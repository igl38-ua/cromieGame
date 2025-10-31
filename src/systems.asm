INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"
INCLUDE "assets/sprites/jewmbo.z80"

SECTION "Systems", ROM0
EXPORT ReadInput, UpdateMovement, UpdateRender, InitSprites

; -------------------- Configuración de tiles --------------------
DEF JEWMBO_VRAM_ADDR EQU $8200
DEF TILE_BASE        EQU ((JEWMBO_VRAM_ADDR - $8000) / 16)
DEF JEWMBO_SET_SIZE  EQU 4

; Índices para cada animación
DEF TILE_IDLE_BASE   EQU TILE_BASE + (0 * JEWMBO_SET_SIZE)   ; $20–$23
DEF TILE_RUNR1_BASE  EQU TILE_BASE + (1 * JEWMBO_SET_SIZE)   ; $24–$27
DEF TILE_RUNR2_BASE  EQU TILE_BASE + (2 * JEWMBO_SET_SIZE)   ; $28–$2B
DEF TILE_RUNL1_BASE  EQU TILE_BASE + (3 * JEWMBO_SET_SIZE)   ; $2C–$2F
DEF TILE_RUNL2_BASE  EQU TILE_BASE + (4 * JEWMBO_SET_SIZE)   ; $30–$33

; -------------------- Variables --------------------
SECTION "Vars", WRAM0
posX:            DS 1
posY:            DS 1
contador:        DS 1
joypadActual:    DS 1        ; nibble: bit0=Right,1=Left,2=Up,3=Down (1=pressed)
animFrame:       DS 1
animDir:         DS 1        ; 0 = idle, 1 = derecha, 2 = izquierda
velY:            DS 1        ; signed
onGround:        DS 1        ; 0/1
vSteps:          DS 1        ; contador interno integración por píxel

SECTION "SystemsCode", ROM0

; ==============================================================
; ReadInput  (A mapeado a UP para compartir lógica)
; ==============================================================
ReadInput::
    ; --- D-Pad (P14=0) ---
    ld   a, $20
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  %00001111
    ld   b, a

    ; --- Botones (P15=0) ---
    ld   a, $10
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  %00001111           ; bit0 = A
    bit  0, a
    jr   z, .noA
    set  2, b                ; A -> UP
.noA:
    ld   a, $30
    ldh  [rP1], a

    ld   a, b
    ld   [joypadActual], a
    ret

; ==============================================================
; UpdateMovement  (gravedad invertible con UP/A)
; ==============================================================
UpdateMovement::
    ; animación cada 8 frames
    ld   hl, contador
    inc  [hl]
    ld   a, [contador]
    and  %00000111
    jr   nz, .skip_anim
    ld   hl, animFrame
    inc  [hl]
    ld   a, [hl]
    and  1
    ld   [hl], a
.skip_anim:

    ; ---------- Horizontal ----------
    ld   a, [joypadActual]

    ; Right
    bit  0, a
    jr   z, .chkLeft
    ld   a, [posX]
    inc  a
    ld   c, a                 ; x tentativa
    ld   a, [posY]
    ld   b, a                 ; y actual
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

.chkLeft:
    ; Left
    bit  1, a
    jr   z, .no_hmove
    ld   a, [posX]
    dec  a
    ld   c, a                 ; x tentativa
    ld   a, [posY]
    ld   b, a                 ; y actual
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

.no_hmove:
    xor  a
    ld   [animDir], a
.after_hmove:

    ; ---------- Gravedad (invertida con UP/A) ----------
    ld   a, GRAVITY
    ld   d, a                 ; d = +GRAVITY
    ld   a, [joypadActual]
    bit  2, a                 ; UP?
    jr   z, .grav_ok
    ld   a, d
    cpl
    inc  a
    ld   d, a                 ; d = -GRAVITY
.grav_ok:

    ; velY += d  (clamp [-TERM, +TERM])
    ld   a, [velY]
    add  a, d
    ld   c, a                 ; c = nueva vel
    ld   a, TERMINAL_SPEED
    cpl
    inc  a
    ld   e, a                 ; e = -TERM
    bit  7, c
    jr   z, .clamp_pos
    ld   a, c
    cp   e
    jr   nc, .store_vel
    ld   a, e
    jr   .store_vel
.clamp_pos:
    ld   a, c
    cp   TERMINAL_SPEED + 1
    jr   c, .store_vel
    ld   a, TERMINAL_SPEED
.store_vel:
    ld   [velY], a
    bit  7, a
    jr   z, .cont_vert
    xor  a
    ld   [onGround], a
.cont_vert:

    ; ---------- Integración vertical por píxel (usa vSteps) ----------
    ld   a, [velY]
    or   a
    jr   z, .after_vmove

    bit  7, a
    jr   z, .start_fall

    ; --- SUBIR ---
    cpl
    inc  a                   ; a = -velY
    ld   [vSteps], a
.rise_loop:
    ld   a, [vSteps]
    or   a
    jr   z, .after_vmove

    ld   a, [posY]
    dec  a                   ; y tentativa
    ld   d, a
    ld   a, [posX]
    ld   e, a
    ld   b, d                ; B=y
    ld   c, e                ; C=x
    call TestAabbUp16
    jr   z, .hit_top

    ld   hl, posY
    dec  [hl]
    ld   hl, vSteps
    dec  [hl]
    jr   .rise_loop

.hit_top:
    xor  a
    ld   [velY], a
    jr   .after_vmove

    ; --- CAER ---
.start_fall:
    ld   [vSteps], a         ; a=+velY
.fall_loop:
    ld   a, [vSteps]
    or   a
    jr   z, .after_vmove

    ld   a, [posY]
    inc  a                   ; y tentativa
    ld   d, a
    ld   a, [posX]
    ld   e, a
    ld   b, d                ; B=y
    ld   c, e                ; C=x
    call TestAabbDown16
    jr   z, .hit_floor

    ld   hl, posY
    inc  [hl]
    ld   hl, vSteps
    dec  [hl]
    jr   .fall_loop

.hit_floor:
    xor  a
    ld   [velY], a
    inc  a
    ld   [onGround], a

.after_vmove:
    ; Meta (tile $05)
    call CheckDoorCollision
    ret

; ==============================================================
; Detección de puerta / meta
; ==============================================================
CheckDoorCollision::
    ; derecha
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
    ; izquierda
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
    ; suelo
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
    ; techo
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

; ==============================================================
; Render (2 sprites 8x8)
; ==============================================================
UpdateRender::
    call wait_vBlank

    ld   a, [posX]
    ld   [wPlayerX], a
    ld   a, [posY]
    ld   [wPlayerY], a

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

; ==============================================================
; InitSprites
; ==============================================================
InitSprites::
    call apagar_LCD
    
    ldh  a,[rLCDC]
    res  5,a          ; WINDOW OFF
    set  4,a          ; BG/Win tile data = $8000 (unsigned)
    res  3,a          ; BG map = $9800
    ldh  [rLCDC],a

    xor  a
    ldh  [rSCX],a     ; sin scroll
    ldh  [rSCY],a
    ldh  [rWX],a
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
    ld   [vSteps], a

    ; paletas
    ld   a, %11100100
    ldh  [rBGP], a
    ldh  [rOBP0], a

    ; carga tiles del sprite a VRAM
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

    ; limpia HRAM ShadowOAM
    ld   hl, HRAMShadowOAM
    ld   b, 8
    xor  a
.clear_hram:
    ld   [hl+], a
    dec  b
    jr   nz, .clear_hram
    ret

; ==============================================================
; Helpers de colisión con BG ($9800)
;   Entrada: A=x(px), B=y(px) → Salida: A=tile id
; ==============================================================
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
    srl  c                  ; xtile
    ld   a, d
    srl  a
    srl  a
    srl  a                  ; ytile
    ld   h, 0
    ld   l, a
    add  hl, hl             ; *2
    add  hl, hl             ; *4
    add  hl, hl             ; *8
    add  hl, hl             ; *16
    add  hl, hl             ; *32
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

; ==============================================================
; Sólido: TILE_SOLID ($01) → Z=1 si choca
; ==============================================================
IsTileSolid::
    cp   TILE_SOLID
    ret

; --- AABB 16x16 contra BG (Z si BLOQUEA) ---
; IMPORTANTE: GetBgTileAtXY destruye C → hay que preservar BC

TestAabbRight16::
    ; Entrada: C=x, B=y  | Puntos: (x+14, y+2) y (x+14, y+13)
    push bc
    ; 1er punto
    ld   a, c
    add  a, 14
    ld   d, a
    ld   a, b
    add  a, 2
    ld   e, a
    ld   a, d
    ld   b, e
    call GetBgTileAtXY
    call IsTileSolid
    jr   z, .solidR
    ; 2º punto (restaurar BC antes de recalcular)
    pop  bc
    push bc
    ld   a, c
    add  a, 14
    ld   d, a
    ld   a, b
    add  a, 13
    ld   e, a
    ld   a, d
    ld   b, e
    call GetBgTileAtXY
    call IsTileSolid
    jr   z, .solidR
    pop  bc
    or   1            ; libre → Z=0
    ret
.solidR:
    pop  bc
    ret  z

TestAabbLeft16::
    ; Entrada: C=x, B=y  | Puntos: (x+1, y+2) y (x+1, y+13)
    push bc
    ; 1er punto
    ld   a, c
    add  a, 1
    ld   d, a
    ld   a, b
    add  a, 2
    ld   e, a
    ld   a, d
    ld   b, e
    call GetBgTileAtXY
    call IsTileSolid
    jr   z, .solidL
    ; 2º punto
    pop  bc
    push bc
    ld   a, c
    add  a, 1
    ld   d, a
    ld   a, b
    add  a, 13
    ld   e, a
    ld   a, d
    ld   b, e
    call GetBgTileAtXY
    call IsTileSolid
    jr   z, .solidL
    pop  bc
    or   1
    ret
.solidL:
    pop  bc
    ret  z

TestAabbUp16::
    ; Entrada: C=x, B=y  | Puntos: (x+2, y+1) y (x+13, y+1)
    push bc
    ; 1er punto
    ld   a, c
    add  a, 2
    ld   d, a
    ld   a, b
    add  a, 1
    ld   e, a
    ld   a, d
    ld   b, e
    call GetBgTileAtXY
    call IsTileSolid
    jr   z, .solidU
    ; 2º punto
    pop  bc
    push bc
    ld   a, c
    add  a, 13
    ld   d, a
    ld   a, b
    add  a, 1
    ld   e, a
    ld   a, d
    ld   b, e
    call GetBgTileAtXY
    call IsTileSolid
    jr   z, .solidU
    pop  bc
    or   1
    ret
.solidU:
    pop  bc
    ret  z

TestAabbDown16::
    ; Entrada: C=x, B=y  | Puntos: (x+2, y+15) y (x+13, y+15)
    push bc
    ; 1er punto
    ld   a, c
    add  a, 2
    ld   d, a
    ld   a, b
    add  a, 15
    ld   e, a
    ld   a, d
    ld   b, e
    call GetBgTileAtXY
    call IsTileSolid
    jr   z, .solidD
    ; 2º punto
    pop  bc
    push bc
    ld   a, c
    add  a, 13
    ld   d, a
    ld   a, b
    add  a, 15
    ld   e, a
    ld   a, d
    ld   b, e
    call GetBgTileAtXY
    call IsTileSolid
    jr   z, .solidD
    pop  bc
    or   1
    ret
.solidD:
    pop  bc
    ret  z

