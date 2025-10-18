; ===== main.asm =====
INCLUDE "include/hw.inc"
INCLUDE "src/ecs.asm"

SECTION "Main", ROM0[$0100]
Start::
    call Init
.loop
    call ReadInput
    call UpdateMovement
    call UpdateRender
    jp .loop

Init::
    ; inicializa jugador o variables aquí
    ret
