; ===== src/state_play.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

; --- WRAM: variables de input para PLAY ---
SECTION "Play Input Vars", WRAM0
wPlayBtnsCur:  ds 1
wPlayBtnsPrev: ds 1
wPlayBtnsJP:   ds 1

; --- ROM: código del estado PLAY ---
SECTION "StatePlay", ROM0
EXPORT Play_Enter, Play_Update, Play_HandleSelect

; -----------------------------------
; Se ejecuta una sola vez al entrar al nivel
Play_Enter::
    call LoadLevelCurrent
    ret

; -----------------------------------
; Se ejecuta cada frame durante el juego
Play_Update::
    call ReadInput
    call UpdateMovement
    call UpdateRender
    ret

; -----------------------------------
; Maneja SELECT (flanco) para saltar al siguiente nivel con LCD OFF/ON
Play_HandleSelect::
    ; Seleccionar botones (Start/Select/B/A)
    ld   a, $10
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  %00001111

    ; JP = cur & ~prev
    ld   hl, wPlayBtnsPrev
    ld   d, [hl]          ; d = prev
    ld   [hl], a          ; prev = cur
    ld   [wPlayBtnsCur], a

    ld   a, d
    cpl
    ld   hl, wPlayBtnsCur
    and  [hl]
    ld   [wPlayBtnsJP], a

    ; reposo
    ld   a, $30
    ldh  [rP1], a

    ; Si SELECT (bit 2) se pulsó este frame -> NextLevel
    ld   a, [wPlayBtnsJP]
    and  KEY_SELECT
    ret  z

    call LoadLevelCurrent
    ret
