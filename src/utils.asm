SECTION "ShadowOAM", WRAM0[$C000]
   ShadowOAM:: ds 160
   DEF SPR0 = ShadowOAM + 0
   DEF SPR1 = ShadowOAM + 4

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
   ld hl, ShadowOAM
   ld b, 160
   xor a
   .clroam:
      ld [hl+], a
      dec b
      jr nz, .clroam
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
   ld a, $C0
   ldh [$FF46], a
   ld b, 40
   .wait:
      dec b
      jr nz, .wait 
   ret

apagar_LCD::
   xor a
   ldh [$FF40], a
   ret

encender_LCD::
   ld a, $97
   ldh [$FF40], a
   ret