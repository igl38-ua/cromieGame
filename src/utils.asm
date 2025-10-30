; ===== src/utils.asm =====
INCLUDE "include/hw.inc"

SECTION "UtilsExports", ROM0
EXPORT wait_vBlank, limpiar_OAM, memcpy, copiar_a_VRAM
EXPORT DoOamDma_template, apagar_LCD, encender_LCD
EXPORT FlushOAM_HRAM
EXPORT HRAMShadowOAM
EXPORT ShadowOAM

SECTION "ShadowOAM", WRAM0[$C000]
ShadowOAM::     ds 160

SECTION "HRAMShadowOAM", HRAM[$FF80]
HRAMShadowOAM:: ds 8

SECTION "utils", ROM0

wait_vBlank::
.loop:
    ldh  a, [rLY]
    cp   144
    jr   c, .loop
    ret

limpiar_OAM::
    ld   hl, $FE00
    ld   b, 160
    xor  a
.clr:
    ld   [hl+], a
    dec  b
    jr   nz, .clr
    ret

FlushOAM_HRAM::
    ld   hl, HRAMShadowOAM
    ld   de, $FE00
    ld   b, 8
.cpy:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  b
    jr   nz, .cpy

    ld   b, 38
.hide:
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
    jr   nz, .hide
    ret

memcpy::
.loop:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  b
    jr   nz, .loop
    ret

copiar_a_VRAM::
    call wait_vBlank
.v:
    ld   a, [hl+]
    ld   [de], a
    inc  de
    dec  bc
    ld   a, b
    or   c
    jr   nz, .v
    ret

DoOamDma_template::
    ld   a, HIGH(HRAMShadowOAM)
    ldh  [rDMA], a
    ld   b, 40
.w:
    dec  b
    jr   nz, .w
    ret

apagar_LCD::
    ldh  a, [rLCDC]
    bit  7, a
    ret  z
    call wait_vBlank
    xor  a
    ldh  [rLCDC], a
    ret

encender_LCD::
    ld   a, %10010111
    ldh  [rLCDC], a
    ret
