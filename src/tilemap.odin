package fabrayodin

import "core:fmt"
import "core:os"
import path "core:path/slashpath"
import json "core:encoding/json"
import "core:math"
import rl "vendor:raylib"

TILEMAP_WIDTH :: SCREEN_WIDTH / TILEMAP_TILE_SIZE
TILEMAP_HEIGHT :: SCREEN_HEIGHT / TILEMAP_TILE_SIZE
TILEMAP_TILE_SIZE :: 32

TILEMAP_JSON_DATA :: #load("/Assets/Tilemap/tilemap_test.json")

Layer :: struct {
    name: string,
    tileset: string,
    is_visible: bool,
    is_collision: bool,
    data: []int,
}

Tilemap :: struct {
    layers: []Layer
}

init_tilemap :: proc(allocator := context.allocator, loc := #caller_location) -> Tilemap {
    tilemap: Tilemap

    // dir := os.get_current_directory()
    // full_path := path.join({dir, "src/Assets/Tilemap/tilemap_test.json"})

    // if json_data, ok := os.read_entire_file(full_path, context.temp_allocator, loc); ok {    
    //     json.unmarshal(json_data, &tilemap)
    // } 

    json.unmarshal(TILEMAP_JSON_DATA, &tilemap)

    return tilemap
}

draw_tilemap :: proc(tilemap: Tilemap) {
    for layer in tilemap.layers {
        if !layer.is_visible { continue }

        for tile, index in layer.data {
            if (tile == -1) { continue }
            row := index / TILEMAP_WIDTH
            col := index % TILEMAP_WIDTH

            tile_x := col * TILEMAP_TILE_SIZE
            tile_y := row * TILEMAP_TILE_SIZE

            rl.DrawRectangle(i32(tile_x), i32(tile_y), TILEMAP_TILE_SIZE, TILEMAP_TILE_SIZE, rl.RED)
        }
    }
}

check_tilemap_collision :: proc(entity: ^$T, tilemap: Tilemap) {
    for layer in tilemap.layers {
        if !layer.is_collision { continue }

        for tile, index in layer.data {
            if (tile == -1) { continue }

            row := index / TILEMAP_WIDTH
            col := index % TILEMAP_WIDTH
            tile_x := col * TILEMAP_TILE_SIZE
            tile_y := row * TILEMAP_TILE_SIZE
            tile_rect := rl.Rectangle { 
                x = f32(tile_x), 
                y = f32(tile_y), 
                width = TILEMAP_TILE_SIZE, 
                height = TILEMAP_TILE_SIZE 
            }

            resolve_collision(entity, tile_rect)
        }
    }
}

resolve_collision :: proc(entity: ^$T, tile: rl.Rectangle) {
    player_rect := get_rect_from_pos_and_size(entity)
    if !rl.CheckCollisionRecs(player_rect, tile) {
        return
    }

    left_overlap  := (player_rect.x + player_rect.width) - tile.x
    right_overlap := (tile.x + tile.width) - player_rect.x
    top_overlap   := (player_rect.y + player_rect.height) - tile.y
    bottom_overlap:= (tile.y + tile.height) - player_rect.y

    // Choose the smallest overlap.
    overlap_x := math.min(left_overlap, right_overlap)
    overlap_y := math.min(top_overlap, bottom_overlap)

    if overlap_x < overlap_y {
        // Adjust horizontally.
        if player_rect.x < tile.x {
            entity^.pos.x -= overlap_x
        } else {
            entity^.pos.x += overlap_x
        }
    } else {
        // Adjust vertically.
        if player_rect.y < tile.y {
            entity^.pos.y -= overlap_y
        } else {
            entity^.pos.y += overlap_y
        }
    }
}
