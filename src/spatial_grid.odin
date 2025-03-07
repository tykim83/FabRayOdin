package fabrayodin

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

SPATIAL_GRID_TILE_SIZE :: 64
SPATIAL_GRID_FONT_SIZE :: 18

Spatial_Grid_Cell :: struct {
    enemies: []^Enemy
}

Spatial_Grid :: struct {
    cell: []Spatial_Grid_Cell,
    width: int, 
    height: int,
    columns: int,
    rows: int,
    debug: bool,
}

init_spatial_grid :: proc(width: int, height: int, debug := false , allocator := context.allocator, loc := #caller_location) -> Spatial_Grid {
    columns := width / SPATIAL_GRID_TILE_SIZE
    rows := height / SPATIAL_GRID_TILE_SIZE
    grid_size := columns * rows

    return Spatial_Grid {
        cell = make([]Spatial_Grid_Cell, grid_size, allocator, loc),
        width = width,
        height = height,
        columns = columns,
        rows = rows,
        debug = debug
    }
}

update_spatial_grid :: proc(spatial_Grid: Spatial_Grid, allocator := context.allocator, loc := #caller_location) {

    if spatial_Grid.debug {
        draw_spatial_grid_lines(spatial_Grid)
        draw_spatial_grid_labels(spatial_Grid, context.temp_allocator, loc)
    }    
}

draw_spatial_grid_lines :: proc(spatial_Grid: Spatial_Grid) {
    columns := spatial_Grid.columns
    rows := spatial_Grid.rows
    height := spatial_Grid.height
    width := spatial_Grid.width

    for col in 1..<columns {  
        x := f32(col) * SPATIAL_GRID_TILE_SIZE
        rl.DrawLineEx({x, 0}, {x, f32(height)}, 1, rl.LIGHTGRAY)
    }

    for row in 1..<rows {
        y := f32(row) * SPATIAL_GRID_TILE_SIZE
        rl.DrawLineEx({0, y}, {f32(width), y}, 1, rl.LIGHTGRAY)
    }
}

draw_spatial_grid_labels :: proc(spatial_Grid: Spatial_Grid, allocator := context.allocator, loc := #caller_location) {
    columns := spatial_Grid.columns
    rows := spatial_Grid.rows
    height := spatial_Grid.height
    width := spatial_Grid.width

    for row in 0..<rows {
        for col in 0..<columns {
            text := fmt.tprintf("%v,%v", col, row)
            ctext := strings.clone_to_cstring(text, allocator, loc)
            text_width := rl.MeasureText(ctext, SPATIAL_GRID_FONT_SIZE)

            x := f32(col) * f32(SPATIAL_GRID_TILE_SIZE)
            y := f32(row) * f32(SPATIAL_GRID_TILE_SIZE)

            text_x := i32(x) + SPATIAL_GRID_TILE_SIZE / 2 - text_width / 2
            text_y := i32(y) + SPATIAL_GRID_TILE_SIZE / 2 - SPATIAL_GRID_FONT_SIZE / 2
            rl.DrawText(ctext, text_x, text_y, SPATIAL_GRID_FONT_SIZE, rl.LIGHTGRAY)
        }
    }
}
