SECTION "ShadowOAM", WRAM0[$C000]
   ShadowOAM:: ds 160

SECTION "HRAMShadowOAM", HRAM[$FF80]
   HRAMShadowOAM:: ds 8   ; solo 2 sprites (8 bytes)

SECTION "utils", ROM0

EXPORT wait_vBlank, limpiar_OAM, memcpy, copiar_a_VRAM
EXPORT DoOamDma_template, apagar_LCD, encender_LCD

wait_vBlank::
   .loop:
      ldh a, [$FF44]
      cp 144
      jr c, .loop
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
; Copia ShadowOAM WRAM -> HRAM
; (Solo los primeros 8 bytes, 2 sprites)
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
; Copia HRAMShadowOAM -> OAM ($FE00)
; (manual, 8 bytes)
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
   ld   b, 38
.hide_loop:
   xor  a           ; a = 0 -> Y = 0 (offscreen)
   ld   [de], a     ; Y
   inc  de
   xor  a           ; X = 0 (da igual)
   ld   [de], a
   inc  de
   xor  a           ; tile = 0
   ld   [de], a
   inc  de
   xor  a           ; attr = 0
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
   ; Solo apagar en VBlank y solo si el LCD está encendido
   ldh a, [$FF40]
   bit 7, a
   ret z
   call wait_vBlank
   xor a
   ldh [$FF40], a
   ret

encender_LCD::
   ld a, $97
   ldh [$FF40], a
   ret
