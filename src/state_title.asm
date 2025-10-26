; ===== src/state_title.asm =====
INCLUDE "include/hw.inc"
INCLUDE "include/constants.inc"

SECTION "Game State Vars", WRAM0
; Variables de entrada para detectar flanco
wKeysCur:   ds 1
wKeysPrev:  ds 1
wKeysJP:    ds 1            ; just pressed

SECTION "Title State", ROM0
EXPORT Title_Enter, Title_Update

; Base para los tiles de la fuente de título
DEF FONT_BASE = $10
DEF T_SPACE   = FONT_BASE + 0
DEF T_A       = FONT_BASE + 1
DEF T_L       = FONT_BASE + 2
DEF T_P       = FONT_BASE + 3
DEF T_R       = FONT_BASE + 4
DEF T_S       = FONT_BASE + 5
DEF T_T       = FONT_BASE + 6
DEF T_U       = FONT_BASE + 7

; ------------------------
; Dibuja "PULSA START" centrado en la fila 8 (0..17) del BG
Title_Enter::
    call apagar_LCD
    call limpiar_OAM

    ; 1) Cargar tiles de fuente en VRAM en $8000 + 16*FONT_BASE
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

    ; 2) Limpiar BG map completo a tile 0 (esto puede causar artefactos)
    ld   hl, $9800
    ld   bc, 32*32
    xor  a
.clrBg:
    ld   [hli], a
    dec  bc
    ld   a, b
    or   c
    jr   nz, .clrBg

    ; 3) Escribir "PULSA START" (11 chars) en fila 8, col 4
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

; ------------------------
; Título: si START pulsado este frame -> entrar al juego
Title_Update::
    call ReadButtonsJustPressed
    ld   a, [wKeysJP]
    and  KEY_START
    ret  z

    ; START en flanco: cargar primer nivel y pasar a PLAY
    call Play_Enter
    ld   a, STATE_PLAY
    ld   [wGameState], a
    ret

; ------------------------
; Lee botones (grupo A/B/SELECT/START) y calcula just-pressed
; Guarda:
;   wKeysCur  = bits activos=1
;   wKeysPrev = anterior
;   wKeysJP   = wKeysCur & ~wKeysPrev
ReadButtonsJustPressed:
    ; Seleccionar botones (Start/Select/B/A)
    ld   a, $10
    ldh  [rP1], a
    ldh  a, [rP1]
    ldh  a, [rP1]           ; 2ª lectura para estabilizar
    cpl                     ; activo-al-alto
    and  %00001111          ; nos quedamos con START..A

    ld   hl, wKeysPrev
    ld   d, [hl]            ; d = prev
    ld   [hl], a            ; wKeysPrev = cur
    ld   [wKeysCur], a      ; wKeysCur = cur

    ; wKeysJP = cur & ~prev
    ld   a, d
    cpl
    ld   hl, wKeysCur
    and  [hl]
    ld   [wKeysJP], a

    ; Dejar el pad en reposo (no seleccionar ninguna fila: P15=1, P14=1)
    ld   a, $30
    ldh  [rP1], a
    ret

; ------------------------
; Datos: tiles 2bpp (plano bajo=1) para las letras que necesitamos
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
