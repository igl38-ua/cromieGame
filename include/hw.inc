; ===== hw.inc =====
; Direcciones básicas del hardware Game Boy

rP1   EQU $FF00
rLCDC EQU $FF40
rSTAT EQU $FF41
rSCY  EQU $FF42
rSCX  EQU $FF43
rLY   EQU $FF44
rBGP  EQU $FF47
rOBP0 EQU $FF48
rOBP1 EQU $FF49
rWY   EQU $FF4A
rWX   EQU $FF4B

; Espera VBlank (simple)
WAIT_VBLANK:
    ld a, [rLY]
    cp 144
    jr c, WAIT_VBLANK
    ret
