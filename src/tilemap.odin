package fabrayodin

import "core:fmt"
import "core:os"
import path "core:path/slashpath"
import json "core:encoding/json"
import "core:math"
import rl "vendor:raylib"

TILEMAP_WIDTH :: SCREEN_WIDTH / 32
TILEMAP_HEIGHT :: SCREEN_HEIGHT / 32

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

init_tilemap :: proc(allocator := context.allocator, loc := #caller_location) -> [3]rl.Rectangle {
    tilemap: Tilemap

    dir := os.get_current_directory()
    full_path := path.join({dir, "src/Assets/Tilemap/tilemap_test.json"})

    if json_data, ok := os.read_entire_file(full_path, context.temp_allocator, loc); ok {    
        json.unmarshal(json_data, &tilemap)
    } 

    fmt.println(tilemap)

    walls : [3]rl.Rectangle = {
        rl.Rectangle{
            x = SCREEN_WIDTH / 2 + 400,
            y = SCREEN_HEIGHT / 2 - 100,
            width = 32,
            height = 200,
        },
        rl.Rectangle{
            x = SCREEN_WIDTH / 2 - 200,  
            y = SCREEN_HEIGHT / 2 - 250,  
            width = 400,
            height = 32,
        },
        rl.Rectangle{
            x = SCREEN_WIDTH / 2 - 50,
            y = SCREEN_HEIGHT / 2 - 250,
            width = 32,
            height = 450,
        }
    }

    return walls
}

draw_tilemap :: proc(walls: [3]rl.Rectangle) {
    for wall in walls {
        rl.DrawRectangleRec(wall, rl.RED)
    }
}
