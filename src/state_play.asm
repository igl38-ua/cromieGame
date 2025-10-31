INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

; -------------------- Variables de input para PLAY --------------------
SECTION "Play Input Vars", WRAM0
wPlayBtnsCur:  ds 1
wPlayBtnsPrev: ds 1
wPlayBtnsJP:   ds 1

; -------------------- Código del estado PLAY --------------------
SECTION "StatePlay", ROM0
EXPORT Play_Enter, Play_Update, Play_HandleSelect

Play_Enter::
    call LoadLevelCurrent
    ret

Play_Update::
    call ReadInput
    call UpdateMovement
    call UpdateRender
    ret

Play_HandleSelect::
    ld   a, $10
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl
    and  %00001111

    ld   hl, wPlayBtnsPrev
    ld   d, [hl]
    ld   [hl], a
    ld   [wPlayBtnsCur], a

    ld   a, d
    cpl
    ld   hl, wPlayBtnsCur
    and  [hl]
    ld   [wPlayBtnsJP], a

    ld   a, $30
    ldh  [rP1], a

    ld   a, [wPlayBtnsJP]
    and  KEY_SELECT
    ret  z

    call NextLevel
    ret
