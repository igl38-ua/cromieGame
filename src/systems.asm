; ===== src/systems.asm =====
INCLUDE "hardware.inc"
INCLUDE "include/constants.inc"

SECTION "Systems", ROM0

EXPORT ReadInput, UpdateMovement, UpdateRender

; Lee input del joypad
ReadInput::
    ; Por ahora vacía, implementar después
    ret

; Movimiento: si entidad tiene POS y VEL => pos_x += vel_x
UpdateMovement::
    ld b, 0
.loop
    ld a, b
    cp MAX_ENTS
    jr z, .done
    
    ld a, b
    ld c, a
    ld b, 0
    
    ld hl, comp_mask
    add hl, bc
    ld a, [hl]
    and (COMP_POS | COMP_VEL)
    cp  (COMP_POS | COMP_VEL)
    jr nz, .next
    
    ld hl, vel_x
    add hl, bc
    ld a, [hl]
    ld hl, pos_x
    add hl, bc
    add a, [hl]
    ld [hl], a
.next
    ld a, c
    inc a
    ld b, a
    jr .loop
.done
    ret

; Renderiza sprites
UpdateRender::
    ; Por ahora vacía, implementar después
    ret