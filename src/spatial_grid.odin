package fabrayodin

import "core:fmt"
import "core:strings"
import "core:slice"
import sa "core:container/small_array"
import rl "vendor:raylib"

SPATIAL_GRID_TILE_SIZE :: 64
SPATIAL_GRID_FONT_SIZE :: 18

global_neighbors: sa.Small_Array(9, Spatial_Grid_Cell)

Spatial_Grid_Cell :: struct {
    enemies: [dynamic]^Enemy,
    path: ^Path,
}

Spatial_Grid :: struct {
    cells: []Spatial_Grid_Cell,
    width: int, 
    height: int,
    columns: int,
    rows: int,
    player_sg_pos: [2]int,
    debug: bool,
}

add_enemy_to_spatial_grid :: proc(enemy: ^Enemy, grid: ^Spatial_Grid, loc := #caller_location) {
    enemy_col, enemy_row := get_spatial_grid_pos(enemy.pos)
    index := enemy_row * grid.columns + enemy_col

    if index >= 0 && index < len(grid.cells) { 
        enemies := &grid.cells[index].enemies
        enemy^.grid_index = index
        append(enemies, enemy, loc)
        fmt.println(enemy)
    }
}

update_astar_path :: proc(car: Car, grid: ^Spatial_Grid, astar: Grid, loc := #caller_location) {
    current_car_col, current_car_row := get_spatial_grid_pos(car.rb.position)
    if grid.player_sg_pos == {current_car_col, current_car_row} {
        return
    }

    grid.player_sg_pos = {current_car_col, current_car_row}
    fmt.println(grid.player_sg_pos)

    for &cell, i in grid.cells {
        if len(cell.enemies) > 0 {
            if cell.path != nil {
                destroy_path(cell.path)
            }

            enemy_tilemap_pos := get_tilemap_grid_position(cell.enemies[0].pos)
            player_tilemap_pos : Vector2 = { i32(grid.player_sg_pos.x), i32(grid.player_sg_pos.y) }
            fmt.println(enemy_tilemap_pos)
            fmt.println(player_tilemap_pos)
            path, _ := find_path(astar, enemy_tilemap_pos, player_tilemap_pos)
            // cell.path = &path

            // printPath(path.nodes)

            for node in path.nodes {
                rl.DrawRectangle(i32(node.tile.pos.x * 32), i32(node.tile.pos.y * 32), 32, 32, rl.GREEN)
            }

            // for node in path.nodes {
            //     rl.DrawRectangle(i32(node.tile.pos.y) * 32, i32(node.tile.pos.y) * 32, 32, 32, rl.RED)
            // }
            // enemy_col, enemy_row := get_spatial_grid_pos(cell.enemies[0].pos)
            // fmt.printfln("{} {}", enemy_col, enemy_row)

            //fmt.println(cell.path)
        }
    }
}

update_enemy_position_spatial_grid :: proc(current_enemy: ^Enemy, grid: ^Spatial_Grid, loc := #caller_location) {
    enemy_col, enemy_row := get_spatial_grid_pos(current_enemy.pos)
    index := enemy_row * grid.columns + enemy_col

    if index == current_enemy.grid_index { return }

    old_index := current_enemy.grid_index
    current_enemy^.grid_index = index

    // Remove from previous index
    for &enemy, i in grid.cells[old_index].enemies {
        if current_enemy == enemy {
            unordered_remove(&grid.cells[old_index].enemies, i, loc)
        }
    }

    // Add to new index
    append(&grid.cells[index].enemies, current_enemy, loc)
}

get_enemy_neighbors_spatial_grid :: proc(current_enemy: Enemy, grid: Spatial_Grid, allocator := context.allocator, loc := #caller_location) -> []Spatial_Grid_Cell {
    sa.clear(&global_neighbors)
    
    indexes : [9]int
    i := 0
    for col in -1..<2 { 
        for row in -1..<2 {
            temp_index := current_enemy.grid_index + col + (grid.columns * row) 

            if temp_index < 0 || temp_index > (grid.columns * grid.rows) { continue }

            indexes[i] = temp_index
            i += 1
        }
    }

    for grid_index in indexes {
        sa.append(&global_neighbors, grid.cells[grid_index])
    }

    return sa.slice(&global_neighbors)
}

get_spatial_grid_pos :: proc(pos: rl.Vector2) -> (col: int, row: int) {
    col = int(pos.x) / SPATIAL_GRID_TILE_SIZE
    row = int(pos.y) / SPATIAL_GRID_TILE_SIZE
    return col, row
}

init_spatial_grid :: proc(width: int, height: int, debug := false, allocator := context.allocator, loc := #caller_location) -> Spatial_Grid {
    columns := width / SPATIAL_GRID_TILE_SIZE
    rows := height / SPATIAL_GRID_TILE_SIZE
    grid_size := columns * rows

    grid := Spatial_Grid {
        cells = make([]Spatial_Grid_Cell, grid_size, allocator, loc),
        width = width,
        height = height,
        columns = columns,
        rows = rows,
        player_sg_pos = { 0, 0 },
        debug = debug
    }

    for &cell in grid.cells {
        cell.enemies = make([dynamic]^Enemy, 0, allocator, loc)
    }

    return grid
}

destroy_spatial_grid :: proc(grid: ^Spatial_Grid) {
    for &cell, i in grid.cells {
        delete(cell.enemies)
        destroy_path(cell.path)
    }
    delete(grid.cells)
}

draw_spatial_grid :: proc(spatial_Grid: ^Spatial_Grid, allocator := context.allocator, loc := #caller_location) {
    if spatial_Grid.debug {
        draw_spatial_grid_lines(spatial_Grid)
        draw_spatial_grid_labels(spatial_Grid, context.temp_allocator, loc)
    }    
}

draw_spatial_grid_lines :: proc(spatial_Grid: ^Spatial_Grid) {
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

draw_spatial_grid_labels :: proc(spatial_Grid: ^Spatial_Grid, allocator := context.allocator, loc := #caller_location) {
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

printPath :: proc(path: []^AStar_Node) {
    for node, i in path {
        if node.parent != nil {
            fmt.printf("[%d] posX: %.1f, posY: %.1f, fCost: %.2f, gCost: %.2f, hCost: %.2f, parent: (%.1f, %.1f)\n",
                i, node.tile.pos.x, node.tile.pos.y, node.fCost, node.gCost, node.hCost,
                node.parent.tile.pos.x, node.parent.tile.pos.y)
        } else {
            fmt.printf("[%d] posX: %.1f, posY: %.1f, fCost: %.2f, gCost: %.2f, hCost: %.2f, parent: nil\n",
                i, node.tile.pos.x, node.tile.pos.y, node.fCost, node.gCost, node.hCost);
        }
    }
}