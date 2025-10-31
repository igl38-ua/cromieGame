; ===== include/constants.inc =====

DEF MAX_ENTS  = 16
DEF COMP_POS  = %00000001
DEF COMP_VEL  = %00000010
DEF COMP_SPR  = %00000100

; Estados del juego
DEF STATE_TITLE = 0
DEF STATE_PLAY  = 1

; Máscaras del joypad (activo=1 tras invertir)
DEF KEY_A      = %00000001
DEF KEY_B      = %00000010
DEF KEY_SELECT = %00000100
DEF KEY_START  = %00001000

; D-Pad (cuando leemos $20 en rP1)
DEF KEY_RIGHT = %00000001
DEF KEY_LEFT  = %00000010
DEF KEY_UP    = %00000100
DEF KEY_DOWN  = %00001000

; Número de niveles que tenemos
DEF LEVEL_COUNT = 5 

; ==== Collisions / Player ====
DEF TILE_SOLID   EQU $01    ; paredes/suelo en los mapas
DEF TILE_DOOR    EQU $05

; Dimensiones del jugador (hitbox del AABB usado en colisiones)
DEF PLAYER_W     EQU 16
DEF PLAYER_H     EQU 16
; --- wram.asm ---

; ==== Físicas ====
DEF GRAVITY        EQU 1     ; píxeles/frame^2 (aceleración)
DEF JUMP_SPEED     EQU -10    ; velocidad inicial hacia arriba
DEF TERMINAL_SPEED EQU 4     ; límite de caída (+)
