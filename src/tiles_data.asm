; ===== src/tiles_data.asm =====
; Carga de datos de tiles/sprites usados por el juego.
; Mantengo Pincho si lo usáis en el mapa, y añado el personaje 'jewmbo'.

INCLUDE "assets/sprites/Pincho.rgbds.asm"
; INCLUDE "assets/sprites/jewmbo.z80"   ; define: jewmbo::, jewmbo_end::, JEWMBO_TILE_COUNT

; No hay código aquí: los datos se usan desde systems.asm (InitSprites)
