EXPORT _PinchoTiles, _PinchoTilesEnd

SECTION "Pincho", ROM0
_PinchoTiles::
    ; Tile 0: Vacío/Transparente (negro)
    DB $00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00
    
    ; Tile 1: Cuadrado completo blanco
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    
    ; Tile 2: Borde superior
    DB $FF,$FF,$FF,$FF,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00
    
    ; Tile 3: Borde inferior
    DB $00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$FF,$FF,$FF,$FF
    
    ; Tile 4: Borde izquierdo
    DB $C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0
    DB $C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0
    
    ; Tile 5: Borde derecho
    DB $03,$03,$03,$03,$03,$03,$03,$03
    DB $03,$03,$03,$03,$03,$03,$03,$03
    
    ; Tile 6: Diagonal \
    DB $80,$80,$40,$40,$20,$20,$10,$10
    DB $08,$08,$04,$04,$02,$02,$01,$01
    
    ; Tile 7: Diagonal /
    DB $01,$01,$02,$02,$04,$04,$08,$08
    DB $10,$10,$20,$20,$40,$40,$80,$80
    
    ; Tile 8: Damero (patrón ajedrez)
    DB $AA,$AA,$55,$55,$AA,$AA,$55,$55
    DB $AA,$AA,$55,$55,$AA,$AA,$55,$55
    
    ; Tile 9: Puntos
    DB $00,$00,$24,$24,$00,$00,$24,$24
    DB $00,$00,$24,$24,$00,$00,$24,$24
    
    ; Tile 10: Cruz
    DB $18,$18,$18,$18,$FF,$FF,$18,$18
    DB $18,$18,$18,$18,$18,$18,$18,$18
    
    ; Tile 11: Círculo (aproximado)
    DB $3C,$3C,$7E,$7E,$FF,$FF,$FF,$FF
    DB $FF,$FF,$7E,$7E,$3C,$3C,$00,$00
    
_PinchoTilesEnd::