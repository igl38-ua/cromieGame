; ===== ecs.asm =====
MAX_ENTS EQU 16

; Máscaras de componentes
COMP_POS  EQU %00000001
COMP_VEL  EQU %00000010
COMP_SPR  EQU %00000100

SECTION "ECS", WRAM0
comp_mask: DS MAX_ENTS
