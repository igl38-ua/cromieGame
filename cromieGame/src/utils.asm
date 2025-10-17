SECTION "ShadowOAM", WRAM0[$C000]
   ShadowOAM:: ds 160 ; 40 sprites * 4 bytes
   DEF SPR0 = ShadowOAM + 0 ; sprite izquierdo
   DEF SPR1 = ShadowOAM + 4; sprite derecho

SECTION "utils", ROM0
wait_vBlank::
   .loop:
      ldh a, [$FF44]   ; ly
      cp 144
      jr c, .loop
   ret 

limpiar_OAM::
   ld hl, ShadowOAM
   ld b, 160      ; 40 sprites * 4 bytes = 160
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

DoOamDma_template::
   ld a, $C0 ; o HIGH(ShadowOAM)
   ldh [$FF46], a ; inicia el DMA
   ld b, 40
   .wait:
      dec b
      jr nz, .wait 
   ret

apagar_LCD::
   xor a             ; apagar el lcd
   ldh [$FF40], a
   ret

encender_LCD::
   ld a, $97      ; encender el LCD, sprites 8x16 ON, si fuera un sprite de 8x8 sería $93 
   ldh [$FF40], a
   ret
