; ===== src/systems.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"
INCLUDE "assets/sprites/jewmbo.z80"

; -------------------------------------------------
; EXPORTS
; -------------------------------------------------
SECTION "SystemsExports", ROM0
EXPORT ReadInput, UpdateMovement, UpdateRender, InitSprites
EXPORT Box16Collides_HL, PointCollides_DE, PlacePlayerOnFreeTile
EXPORT IsHazardPoint_DE

EXPORT joypadActual

; -------------------------------------------------
; CONSTANTES / CONFIG SPRITES
; -------------------------------------------------
DEF JEWMBO_VRAM_ADDR EQU $8200
DEF TILE_BASE        EQU ((JEWMBO_VRAM_ADDR - $8000) / 16)

DEF JEWMBO_SET_SIZE  EQU 4

DEF TILE_IDLE_BASE   EQU TILE_BASE + (0 * JEWMBO_SET_SIZE)
DEF TILE_RUNR1_BASE  EQU TILE_BASE + (1 * JEWMBO_SET_SIZE)
DEF TILE_RUNR2_BASE  EQU TILE_BASE + (2 * JEWMBO_SET_SIZE)
DEF TILE_RUNL1_BASE  EQU TILE_BASE + (3 * JEWMBO_SET_SIZE)
DEF TILE_RUNL2_BASE  EQU TILE_BASE + (4 * JEWMBO_SET_SIZE)

; -------------------------------------------------
; VARIABLES (WRAM) DEL JUGADOR
; -------------------------------------------------
SECTION "SystemsVars", WRAM0
contador:     DS 1
joypadActual: DS 1
animFrame:    DS 1
animDir:      DS 1

; -------------------------------------------------
; CÓDIGO
; -------------------------------------------------
SECTION "SystemsCode", ROM0

; ---------------------------
; LECTURA DE ENTRADA
; ---------------------------
ReadInput::
    ld   a, $20
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  %00001111
    ld   b, a

    ld   a, $10
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  %00001111
    swap a
    or   b
    ld   [joypadActual], a

    ld   a, $30
    ldh  [rP1], a
    ret


; =================================================
;  COLISIÓN POR TILES (contra wCollMap)
; =================================================

; HL <- &wCollMap[ty*20 + tx]  (B=tx, C=ty)
GetCollPtr_BC::
    ld   h, 0
    ld   l, c
    add  hl, hl
    add  hl, hl
    add  hl, hl
    add  hl, hl
    ld   d, 0
    ld   e, c
    add  hl, de
    add  hl, de
    add  hl, de
    add  hl, de
    ld   d, 0
    ld   e, b
    add  hl, de
    ld   de, wCollMap
    add  hl, de
    ret

; D=px, E=py  -> Carry=1 si sólido / Carry=0 si libre
PointCollides_DE::
    ld   a, d
    srl  a
    srl  a
    srl  a
    ld   b, a

    ld   a, e
    srl  a
    srl  a
    srl  a
    ld   c, a

    ld   a, b
    cp   MAP_W
    jr   nc, .solid
    ld   a, c
    cp   MAP_H
    jr   nc, .solid

    call GetCollPtr_BC
    ld   a, [hl]
    or   a
    jr   nz, .solid
    and  a
    ret
.solid:
    scf
    ret

; H=x, L=y (TL de cuadro 16x16) -> Carry=1 si choca. PRESERVA H y L
Box16Collides_HL::
    push hl

; (x+1, y+1)
    ld   a, h
    add  1
    ld   d, a
    ld   a, l
    add  1
    ld   e, a
    call PointCollides_DE
    jr   c, .solid_pop

    ; (x+14, y+1)
    ld   a, h
    add  14
    ld   d, a
    ld   a, l
    add  1
    ld   e, a
    call PointCollides_DE
    jr   c, .solid_pop

    ; (x+1, y+14)
    ld   a, h
    add  1
    ld   d, a
    ld   a, l
    add  14
    ld   e, a
    call PointCollides_DE
    jr   c, .solid_pop

    ; (x+14, y+14)
    ld   a, h
    add  14
    ld   d, a
    ld   a, l
    add  14
    ld   e, a
    call PointCollides_DE
    jr   c, .solid_pop


    pop  hl
    and  a
    ret

.solid_pop:
    pop  hl
.solid:
    scf
    ret


; =================================================
;  (OPCIONAL) LECTURA DE TILE Y DETECCIÓN DE PINCHOS ($06)
;  Requiere: wLevelTilePtr en WRAM
; =================================================

; HL <- &tilemap[ty*20 + tx]  (B=tx, C=ty) usando base en wLevelTilePtr
GetTilePtr_BC::
    ld   h, 0
    ld   l, c
    add  hl, hl
    add  hl, hl
    add  hl, hl
    add  hl, hl
    ld   d, 0
    ld   e, c
    add  hl, de
    add  hl, de
    add  hl, de
    add  hl, de
    ld   d, 0
    ld   e, b
    add  hl, de

    ld   a, [wLevelTilePtr]
    ld   e, a
    ld   a, [wLevelTilePtr+1]
    ld   d, a
    add  hl, de
    ret

; D=px, E=py -> Z=0 si el punto cae en tile $06 (pinchos), Z=1 si no
IsHazardPoint_DE::
    push hl
    push de
    push bc

    ld   a, d
    srl  a
    srl  a
    srl  a
    ld   b, a

    ld   a, e
    srl  a
    srl  a
    srl  a
    ld   c, a

    ld   a, b
    cp   MAP_W
    jr   nc, .no
    ld   a, c
    cp   MAP_H
    jr   nc, .no

    call GetTilePtr_BC
    ld   a, [hl]
    cp   $06
    jr   z, .yes
.no:
    pop  bc
    pop  de
    pop  hl
    or   a           ; Z=1
    ret
.yes:
    pop  bc
    pop  de
    pop  hl
    xor  a
    dec  a           ; Z=0
    ret


; =================================================
;  COLOCAR JUGADOR EN TILE LIBRE (opcional)
; =================================================
; Busca un hueco 2x2 en wCollMap y coloca al jugador ahí
PlacePlayerOnFreeTile::
    ld   c, 2              ; tx = 2 (columna de inicio)
.next_row:
    ld   b, 10             ; ty = 10 (fila de inicio aprox)
.scan_row:
    ; HL = &wCollMap[ty*20 + tx]
    ld   a, b              ; ty
    ld   h, 0
    ld   l, a
    add  hl, hl
    add  hl, hl
    add  hl, hl
    add  hl, hl            ; *16
    ld   d, 0
    ld   e, a
    add  hl, de
    add  hl, de
    add  hl, de
    add  hl, de            ; +4ty => *20
    ld   d, 0
    ld   e, c
    add  hl, de            ; +tx

    ; comprobar 2x2: [0,0], [1,0], [0,1], [1,1]
    ld   a, [hl]           ; (tx,ty)
    or   a
    jr   nz, .next_tx
    ld   a, [hl+]         ; (tx+1,ty)
    or   a
    jr   nz, .next_tx
    ld   de, 20
    add  hl, de            ; (tx,ty+1)
    ld   a, [hl]
    or   a
    jr   nz, .next_tx
    ld   a, [hl+]         ; (tx+1,ty+1)
    or   a
    jr   nz, .next_tx

    ; ¡Hueco encontrado! colocar x,y en píxeles
    ld   a, c
    add  a, a
    add  a, a
    add  a, a              ; *8
    ld   [pos_x], a
    ld   a, b
    add  a, a
    add  a, a
    add  a, a              ; *8
    ld   [pos_y], a
    ret

.next_tx:
    inc  c
    ld   a, c
    cp   17                ; hasta col 17 (17,18 son borde para 2x2)
    jr   c, .scan_row

    ; siguiente fila
    ld   c, 2
    inc  b
    ld   a, b
    cp   16                ; hasta fila 16 (16,17 borde para 2x2)
    jr   c, .next_row

    ; fallback si no hay hueco
    ld   a, 40
    ld   [pos_x], a
    ld   a, 80
    ld   [pos_y], a
    ret



; ---------------------------
; MOVIMIENTO + ANIMACIÓN
; ---------------------------
UpdateMovement::
    ld   hl, contador
    inc  [hl]

    ld   a, [joypadActual]
    or   a
    jr   z, .no_input

    ld   a, [contador]
    and  %00000111
    jr   nz, .skip_anim
    ld   hl, animFrame
    inc  [hl]
    ld   a, [hl]
    and  1
    ld   [hl], a
.skip_anim:

    ld   a, [joypadActual]
    ld   d, 0
    ld   e, 0

    bit  0, a
    jr   z, .chkL
    ld   d, 1
    ld   a, 1
    ld   [animDir], a
.chkL:
    bit  1, a
    jr   z, .chkU
    ld   d, $FF          ; -1
    ld   a, 2
    ld   [animDir], a
.chkU:
    bit  2, a
    jr   z, .chkD
    ld   e, $FF          ; -1
.chkD:
    bit  3, a
    jr   z, .try_move
    ld   e, 1

.try_move:
    ld   a, d
    or   a
    jr   z, .try_y

    ld   a, [pos_x]
    add  d
    ld   h, a
    ld   a, [pos_y]
    ld   l, a

    push de
    call Box16Collides_HL
    pop  de

    jr   c, .try_y
    ld   a, h
    ld   [pos_x], a

.try_y:
    ld   a, e
    or   a
    jr   z, .after_move

    ld   a, [pos_x]
    ld   h, a
    ld   a, [pos_y]
    add  e
    ld   l, a

    call Box16Collides_HL
    jr   c, .after_move
    ld   a, l
    ld   [pos_y], a

.after_move:
    ; Chequeo de pinchos en (x+8, y+15)
    ld   a, [pos_x]
    add  8
    ld   d, a
    ld   a, [pos_y]
    add  15
    ld   e, a
    call IsHazardPoint_DE
    jr   nz, .on_spikes

    jr   .done

.no_input:
    xor  a
    ld   [animDir], a
    jr   .done

.on_spikes:
    ld   a, 120
    ld   [pos_x], a
    ld   a, 90
    ld   [pos_y], a

.done:
    ret


; ---------------------------
; RENDER
; ---------------------------
UpdateRender::
    call wait_vBlank

    ld   a, [pos_y]
    add  16
    ld   d, a
    ld   a, [pos_x]
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


; ---------------------------
; INIT SPRITES / TILES
; ---------------------------
InitSprites::
    xor  a
    ld   [contador], a
    ld   [animFrame], a
    ld   [animDir], a

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
