##----------LICENSE NOTICE-------------------------------------------------------------------------------------------------------##
##  This file is part of GBTelera: A Gameboy Development Framework                                                               ##
##  Copyright (C) 2024 ronaldo / Cheesetea / ByteRealms (@FranGallegoBR)                                                         ##
##-------------------------------------------------------------------------------------------------------------------------------##

include cfg/gbtelera.mk       # GBTelera general configuration for the project
include cfg/projectpaths.mk   # Local paths and files for the project

##-----------------------------------------
## Project general configuration
PRJNAME  := game
PAD      := 0xFF
INCLUDE  := -Isrc -Iinclude
ASMFLAGS := -E -Weverything
FIXFLAGS := -v
TARGET   := $(PRJNAME).gb
SAV_FILE := $(PRJNAME).sav
MAP_FILE := $(PRJNAME).map 
SYM_FILE := $(PRJNAME).sym

##-----------------------------------------
## Fuentes del proyecto
## Añadimos los nuevos módulos ECS
ASMFILES := \
	src/main.asm \
	src/ecs.asm \
	src/components.asm \
	src/systems.asm \
	src/map.asm \
	src/utils.asm

##-----------------------------------------
## Configuración de recursos
## (por si luego quieres incluir assets de tiles o mapas)
ASSET_DIRS := assets/tiles assets/maps assets/sprites

##-----------------------------------------
## Rutas de salida (GBTelera las gestiona internamente)
OBJDIR := build
OUTDIR := build

##-----------------------------------------
## Enlazado final
## (GBTelera usa reglas genéricas, no necesitas cambiarlas)
include cfg/rules.mk
