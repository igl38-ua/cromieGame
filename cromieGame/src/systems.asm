; ===== systems.asm =====

UpdateMovement::
    ld b, 0
.loop
    ld a, b
    cp MAX_ENTS
    jr z, .done
    ld hl, comp_mask
    add l
    ld a, [hl]
    and (COMP_POS | COMP_VEL)
    cp (COMP_POS | COMP_VEL)
    jr nz, .next

    ; pos_x[b] += vel_x[b]
    ld hl, vel_x
    add hl, b
    ld a, [hl]
    ld hl, pos_x
    add hl, b
    add [hl]
    ld [hl], a

.next
    inc b
    jr .loop
.done
    ret
