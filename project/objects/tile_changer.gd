extends Node2D

## TileMapLayer to affect
@export var tilemap: TileMapLayer

## New tile ID to set
@export var new_tile_id := -1

## Orb that should trigger this tile change when smashed
@export var orb: Orb

func _ready() -> void:
	if orb:
		orb.smashed.connect(_on_orb_smashed)

func _on_orb_smashed() -> void:
	activate()

func activate() -> void:
	if not tilemap:
		push_warning("No tilemap set for TileChanger")
		return
	var point_in_tilemap = tilemap.to_local(global_position)
	var tile_coords := tilemap.local_to_map(point_in_tilemap)
	tilemap.set_cell(tile_coords, new_tile_id)
