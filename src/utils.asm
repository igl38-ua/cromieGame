SECTION "ShadowOAM", WRAM0[$C000]
   ShadowOAM:: ds 160

SECTION "HRAMShadowOAM", HRAM[$FF80]
   HRAMShadowOAM:: ds 8   ; solo 2 sprites (8 bytes)

SECTION "utils", ROM0

EXPORT wait_vBlank, limpiar_OAM, memcpy, copiar_a_VRAM
EXPORT DoOamDma_template, apagar_LCD, encender_LCD, RellenaHueco

wait_vBlank::
   ldh  a, [$FF40]
   bit  7, a
   jr   z, .ret

.loop:
   ldh  a, [$FF44]        ; rLY
   cp   144
   jr   c, .loop
.ret:
   ret

limpiar_OAM::
   ld hl, $FE00
   ld b, 160
   xor a
.clroam:
   ld [hl+], a
   dec b
   jr nz, .clroam
   ret

; Copia ShadowOAM WRAM -> HRAM (Solo los primeros 8 bytes: 2 sprites)
CopyShadowOAMToHRAM::
    ld   hl, ShadowOAM
    ld   de, HRAMShadowOAM
    ld   b, 8
.copy_loop:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  b
    jr   nz, .copy_loop
    ret


; Copia HRAMShadowOAM -> OAM ($FE00) y oculta resto
FlushOAM_HRAM::
    ld   hl, HRAMShadowOAM
    ld   de, $FE00
    ld   b, 8
.copy:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  b
    jr   nz, .copy

   ; oculta el resto de las 38 entradas
    ;    ld   b, 38
    ; .hide_loop:
    ;    xor  a           ; a = 0 -> Y = 0 (offscreen)
    ;    ld   [de], a     ; Y
    ;    inc  de
    ;    xor  a           ; X = 0 (da igual)
    ;    ld   [de], a
    ;    inc  de
    ;    xor  a           ; tile = 0
    ;    ld   [de], a
    ;    inc  de
    ;    xor  a           ; attr = 0
    ;    ld   [de], a
    ;    inc  de
    ;    dec  b
    ;    jr   nz, .hide_loop

    ld   b, 38
    ld   a, 8
    add  a, e
    ld   e, a
.hide_loop:
    xor  a
    ld   [de], a
    inc  de
    xor  a
    ld   [de], a
    inc  de
    xor  a
    ld   [de], a
    inc  de
    xor  a
    ld   [de], a
    inc  de
    dec  b
    jr   nz, .hide_loop

   ret

memcpy::
.loop:
   ld a, [hl+]
   ld [de], a
   inc de
   dec b
   jr nz, .loop
   ret

copiar_a_VRAM::
    call wait_vBlank
.loop:
    ld a, [hl+]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ret

DoOamDma_template::
   ld a, HIGH(HRAMShadowOAM)
   ldh [$FF46], a
   ld b, 40
.wait:
   dec b
   jr nz, .wait 
   ret

apagar_LCD::
    ldh  a, [$FF40]
    bit  7, a
    ret  z

.wait_to_vblank:
    ldh  a, [$FF44]
    cp   144 
    jr   c, .wait_to_vblank

.wait_mode1:
    ldh  a, [$FF41]
    and  %00000011
    cp   1
    jr   nz, .wait_mode1

    xor  a
    ldh  [$FF40], a
    ret


encender_LCD::
   ld   a, $97
   ldh  [$FF40], a


.wait_vb_after_on:
   ldh  a, [$FF44]
   cp   144
   jr   c, .wait_vb_after_on
   ret


; Rellena un rectángulo del BG map con un tile
RellenaHueco::
    ; Guarda parámetros
    push af  ; tile
    push bc  ; alto/ancho
    push de  ; row/col

    pop  de   ; E=col, D=row
    pop  bc   ; B=alto, C=ancho
    pop  af   ; A=tile
    ld   hl, $9800
    call .DoFill

    push af
    push bc
    push de
    pop  de
    pop  bc
    pop  af
    ld   hl, $9C00

.DoFill:
    push hl
    ld   h,0
    ld   l,d 
    add  hl,hl
    add  hl,hl
    add  hl,hl
    add  hl,hl
    add  hl,hl
    ld   a,l
    add  a,e
    ld   l,a
    jr   nc, .no_carry_col
    inc  h
.no_carry_col:
    pop  de
    add  hl,de 

    ld   e,c 
    push af
    ld   a,32
    sub  e
    ld   d,a
    pop  af

.row_loop:
    ld   c,e 
.col_loop:
    ld   [hl+],a
    dec  c
    jr   nz,.col_loop

    ; HL += stride
    push af
    ld   a,l
    add  a,d
    ld   l,a
    jr   nc,.no_carry_row
    inc  h
.no_carry_row:
    pop  af

    dec  b
    jr   nz,.row_loop
    ret
