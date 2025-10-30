SECTION "ShadowOAM", WRAM0[$C000]
   ShadowOAM:: ds 160

SECTION "HRAMShadowOAM", HRAM[$FF80]
   HRAMShadowOAM:: ds 8   ; solo 2 sprites (8 bytes)

SECTION "utils", ROM0

EXPORT wait_vBlank, limpiar_OAM, memcpy, copiar_a_VRAM
EXPORT DoOamDma_template, apagar_LCD, encender_LCD, RellenaHueco

wait_vBlank::
   ; Si el LCD está apagado, no hay LY que avance -> evita bucle en “FalloBlank”
   ldh  a, [$FF40]        ; rLCDC
   bit  7, a
   jr   z, .ret           ; LCD OFF: salir inmediatamente

   ; Si LCD ON: esperar hasta entrar en VBlank (LY >= 144)
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

; -------------------------------------------------
; Copia ShadowOAM WRAM -> HRAM (Solo los primeros 8 bytes, 2 sprites)
; -------------------------------------------------
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

; -------------------------------------------------
; Copia HRAMShadowOAM -> OAM ($FE00) (manual, 8 bytes) y oculta resto
; -------------------------------------------------
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

   ; 2) oculta el resto de las 38 entradas
   ; cada sprite: Y, X, tile, attr
   ; para ocultar basta con Y=0
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
    ; Si ya está apagado, salir
    ldh  a, [$FF40]        ; rLCDC
    bit  7, a
    ret  z

    ; Espera a ENTRAR en VBlank (borde) para no pillar la salida
.wait_to_vblank:
    ldh  a, [$FF44]        ; rLY
    cp   144               ; VBlank empieza en LY>=144
    jr   c, .wait_to_vblank

    ; Asegura que el PPU está en modo VBlank (STAT modo=01)
.wait_mode1:
    ldh  a, [$FF41]        ; rSTAT
    and  %00000011
    cp   1
    jr   nz, .wait_mode1

    ; Ahora sí: apagar
    xor  a
    ldh  [$FF40], a
    ret


encender_LCD::
   ; Enciende LCD en DMG con:
   ;  - BG map en $9800 (bit3=0)
   ;  - Tiles BG/Win en $8000 (bit4=1)
   ;  - Ventana OFF (bit5=0)
   ;  - Sprites ON 8x16 (bit1=1, bit2=1)
   ;  - BG ON (bit0=1)
   ; 1001 0111b = $97
   ld   a, $97
   ldh  [$FF40], a

   ; Tras encender, espera a entrar en VBlank una vez para estabilizar
.wait_vb_after_on:
   ldh  a, [$FF44]      ; rLY
   cp   144
   jr   c, .wait_vb_after_on
   ret

; -------------------------------------------------
; Rellena un rectángulo del BG map con un tile
; Escribe en $9800 y también en $9C00 (por si el LCDC usara BG map 1).
; Úsala con LCD OFF o en VBlank.
; Entradas:
;   A = tile id
;   B = alto (h) en tiles
;   C = ancho (w) en tiles
;   D = fila (row)  0..17
;   E = col  (col)  0..19
; -------------------------------------------------
RellenaHueco::
    ; Guarda parámetros
    push af           ; tile
    push bc           ; alto/ancho
    push de           ; row/col

    ; ---- $9800 ----
    pop  de           ; E=col, D=row
    pop  bc           ; B=alto, C=ancho
    pop  af           ; A=tile
    ld   hl, $9800
    call .DoFill

    ; Vuelve a rellenar con los mismos parámetros en $9C00
    push af
    push bc
    push de
    pop  de
    pop  bc
    pop  af
    ld   hl, $9C00
    ; cae a la misma subrutina
.DoFill:
    ; HL = base + row*32 + col
    push hl                 ; guarda base
    ld   h,0
    ld   l,d                ; L=row
    add  hl,hl              ; *2
    add  hl,hl              ; *4
    add  hl,hl              ; *8
    add  hl,hl              ; *16
    add  hl,hl              ; *32
    ld   a,l
    add  a,e                ; +col
    ld   l,a
    jr   nc, .no_carry_col
    inc  h
.no_carry_col:
    pop  de                 ; DE=base ($9800/$9C00)
    add  hl,de              ; HL=destino inicial

    ; E = width, D = stride = 32 - width
    ld   e,c                ; e=ancho
    push af                 ; guarda tile
    ld   a,32
    sub  e
    ld   d,a                ; d=stride
    pop  af                 ; A=tile

.row_loop:
    ld   c,e                ; ancho por fila
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

    dec  b                  ; siguiente fila
    jr   nz,.row_loop
    ret
