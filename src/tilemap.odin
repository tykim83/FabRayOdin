package fabrayodin

import "core:fmt"
import json "core:encoding/json"
import vmem "core:mem/virtual"
import rl "vendor:raylib"

TILEMAP_JSON_DATA :: #load("/Assets/Tilemap/tilemap_test.json")

Layer :: struct {
    name:         string,
    tileset:      string,
    is_visible:   bool,
    is_collision: bool,
    data:         []int,
}

Tilemap :: struct {
    layers:          []Layer,
    collision_rect : []rl.Rectangle,
    arena: vmem.Arena,
}

init_tilemap :: proc(loc := #caller_location) -> Tilemap {
    tilemap_arena: vmem.Arena
    tilemap_arena_allocator := vmem.arena_allocator(&tilemap_arena)

    tilemap: Tilemap
    json.unmarshal(TILEMAP_JSON_DATA, &tilemap, allocator = tilemap_arena_allocator)

    tilemap.collision_rect = create_tilemap_collision_rects(tilemap, tilemap_arena_allocator, loc)
    tilemap.arena = tilemap_arena

    return tilemap
}

destroy_tilemap :: proc(tilemap: ^Tilemap, loc := #caller_location) {
    vmem.arena_destroy(&tilemap.arena, loc)
}

check_tilemap_collision :: proc(entity: ^$T, tilemap: Tilemap) {
    for layer in tilemap.layers {
        if !layer.is_collision { continue }

        for tile, index in layer.data {
            if (tile == -1) { continue }

            row := index / GRID_COLUMNS
            col := index % GRID_COLUMNS
            tile_x := col * GRID_TILE_SIZE
            tile_y := row * GRID_TILE_SIZE
            tile_rect := rl.Rectangle { 
                x = f32(tile_x), 
                y = f32(tile_y), 
                width = GRID_TILE_SIZE, 
                height = GRID_TILE_SIZE 
            }

            resolve_collision(entity, &tile_rect)
        }
    }
}

@(private = "file")
resolve_collision :: proc(entity: ^$T, tile: ^rl.Rectangle) {
    entity_rect := get_rect_from_centre_world_pos_and_size(entity)
    shrink_amount: f32 = 2.0 // <-- Your grace amount

    tile.x += shrink_amount
    tile.y += shrink_amount
    tile.width -= shrink_amount * 2
    tile.height -= shrink_amount * 2
    if !rl.CheckCollisionRecs(entity_rect, tile^) {
        return
    }

    left_overlap  := (entity_rect.x + entity_rect.width) - tile.x
    right_overlap := (tile.x + tile.width) - entity_rect.x
    top_overlap   := (entity_rect.y + entity_rect.height) - tile.y
    bottom_overlap:= (tile.y + tile.height) - entity_rect.y

    // Choose the smallest overlap.
    overlap_x := math.min(left_overlap, right_overlap)
    overlap_y := math.min(top_overlap, bottom_overlap)

    if overlap_x < overlap_y {
        // Adjust horizontally.
        if entity_rect.x < tile.x {
            entity^.pos.x -= overlap_x
        } else {
            entity^.pos.x += overlap_x
        }
    } else {
        // Adjust vertically.
        if entity_rect.y < tile.y {
            entity^.pos.y -= overlap_y
        } else {
            entity^.pos.y += overlap_y
        }
    }
}

@(private = "file")
create_tilemap_collision_rects :: proc(tilemap: Tilemap, allocator := context.allocator, loc := #caller_location) -> []rl.Rectangle {
    rects := make([dynamic]rl.Rectangle, 0, allocator, loc)

    for layer in tilemap.layers {
        if !layer.is_collision { continue }

        for tile, index in layer.data {
            if (tile == -1) { continue }

            row := index / GRID_COLUMNS
            col := index % GRID_COLUMNS
            tile_x := col * GRID_TILE_SIZE
            tile_y := row * GRID_TILE_SIZE
            tile_rect := rl.Rectangle { 
                x = f32(tile_x), 
                y = f32(tile_y), 
                width = GRID_TILE_SIZE, 
                height = GRID_TILE_SIZE 
            }

            append(&rects, tile_rect, loc)
        }
    }

    return rects[:]
}
