INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

SECTION "Game State Vars", WRAM0
wKeysCur:   ds 1
wKeysPrev:  ds 1
wKeysJP:    ds 1

SECTION "Title State", ROM0
EXPORT Title_Enter, Title_Update
DEF FONT_BASE = $20
DEF T_SPACE   = FONT_BASE + 0
DEF T_A       = FONT_BASE + 1
DEF T_L       = FONT_BASE + 2
DEF T_P       = FONT_BASE + 3
DEF T_R       = FONT_BASE + 4
DEF T_S       = FONT_BASE + 5
DEF T_T       = FONT_BASE + 6
DEF T_U       = FONT_BASE + 7


Title_Enter::
    call apagar_LCD
    call limpiar_OAM

    ; Cargar tiles de fuente en VRAM
    ld   hl, TitleFontData
    ld   de, $8000 + (16 * FONT_BASE)
    ld   bc, TitleFontDataEnd - TitleFontData
.copyFont:
    ld   a, [hli]
    ld   [de], a
    inc  de
    dec  bc
    ld   a, b
    or   c
    jr   nz, .copyFont

    ; Limpiar pantalla ¡
/*     ld   hl, $9800        
    ld   bc, 32*32
    ld   a, $20
.fill_bg:
    ld   [hli], a
    dec  bc
    ld   a, b
    or   c
    jr   nz, .fill_bg */

    ; Limpia el logo de Nintendo

    ld   a, $20 
    ld   d, 5
    ld   e, 15 
    ld   hl, $9800 + (6*32 + 4) 
.clear_row:
    push de
    push hl
    ld   c, e
.clear_col:
    ld   [hli], a
    dec  c
    jr   nz, .clear_col
    pop  hl
    ld   bc, 32
    add  hl, bc 
    pop  de
    dec  d
    jr   nz, .clear_row

    ; Escribir PULSA START 
    ld   hl, $9800 + (8*32 + 4)
    ld   de, TitleString
    ld   c, 11
.writeTxt:
    ld   a, [de]
    inc  de
    ld   [hli], a
    dec  c
    jr   nz, .writeTxt

    call encender_LCD
    ret

; Título, si START pulsado entrar al juego
Title_Update::
    call ReadButtonsJustPressed
    ld   a, [wKeysJP]
    and  KEY_START
    ret  z

    xor  a
    ld   [wLevelIdx], a

    call Play_Enter
    ld   a, STATE_PLAY
    ld   [wGameState], a
    ret


; Lee botones (A/B/SELECT/START) y calcula just-pressed
ReadButtonsJustPressed:
    ; Seleccionar botones (Start/Select/B/A)
    ld   a, $10
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]
    cpl 
    and  %00001111

    ld   hl, wKeysPrev
    ld   d, [hl] 
    ld   [hl], a
    ld   [wKeysCur], a 

    ld   a, d
    cpl
    ld   hl, wKeysCur
    and  [hl]
    ld   [wKeysJP], a

    ld   a, $30
    ldh  [rP1], a
    ret

TitleFontData::
    ; ' ' (espacio)
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

    ; 'A'
    DB $00,$00,$38,$00,$44,$00,$44,$00,$7C,$00,$44,$00,$44,$00,$44,$00

    ; 'L'
    DB $00,$00,$40,$00,$40,$00,$40,$00,$40,$00,$40,$00,$40,$00,$7C,$00

    ; 'P'
    DB $00,$00,$38,$00,$44,$00,$44,$00,$78,$00,$40,$00,$40,$00,$40,$00

    ; 'R'
    DB $00,$00,$78,$00,$44,$00,$44,$00,$78,$00,$50,$00,$48,$00,$44,$00

    ; 'S'
    DB $00,$00,$3C,$00,$40,$00,$40,$00,$38,$00,$04,$00,$04,$00,$78,$00

    ; 'T'
    DB $00,$00,$7C,$00,$10,$00,$10,$00,$10,$00,$10,$00,$10,$00,$10,$00

    ; 'U'
    DB $00,$00,$44,$00,$44,$00,$44,$00,$44,$00,$44,$00,$44,$00,$38,$00
TitleFontDataEnd::

; "PULSA START"
TitleString::
    DB T_P, T_U, T_L, T_S, T_A, T_SPACE, T_S, T_T, T_A, T_R, T_T
