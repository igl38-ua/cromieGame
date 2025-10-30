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

; Número de niveles que tenemos
DEF LEVEL_COUNT = 2 

DEF MAP_W      EQU 20
DEF MAP_H      EQU 18

; puntos sólidos del jugador (sprite 16x16)
DEF SPR_W      EQU 16
DEF SPR_H      EQU 16