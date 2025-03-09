package fabrayodin

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Enemy :: struct {
    pos: rl.Vector2,
    size: rl.Vector2,
    color: rl.Color,
}

add_enemy_to_spatial_grid :: proc(enemy: ^Enemy, grid: ^Spatial_Grid, loc := #caller_location) {
    enemy_col, enemy_row := get_spatial_grid_pos(enemy.pos)
    index := enemy_row * grid.columns + enemy_col

    if index >= 0 && index < len(grid.cells) { 
        enemies := &grid.cells[index].enemies
        append(enemies, enemy, loc)
    }
}

update_enemies :: proc(grid: ^Spatial_Grid, mouse_pos: rl.Vector2) {
    selected_enemy_col, selected_enemy_row: int
    enemy_found: bool

    outer: for cell, i in grid.cells {
        for &enemy in cell.enemies {
            if enemy == nil { continue }

            if rl.CheckCollisionPointRec(mouse_pos, get_enemy_rect(enemy^)) {
                selected_enemy_col, selected_enemy_row = get_spatial_grid_pos(enemy^.pos)
                enemy_found = true
                break outer 
            } 
        }
    }

    for cell, i in grid.cells {
        for &enemy in cell.enemies {
            if enemy == nil { continue }

            if rl.CheckCollisionPointRec(mouse_pos, get_enemy_rect(enemy^)) {
                enemy^.color = rl.RED
                continue
            } 
            
            if enemy_found {
                enemy_col, enemy_row := get_spatial_grid_pos(enemy^.pos)
                if math.abs(enemy_col - selected_enemy_col) <= 1 && math.abs(enemy_row - selected_enemy_row) <= 1 {
                    enemy^.color = rl.ORANGE
                }
                continue
            }

            enemy^.color = rl.BLUE      
        }
    }
}

draw_enemies :: proc(grid: ^Spatial_Grid) {
    for cell, i in grid.cells {
        for enemy in cell.enemies {
            if enemy != nil {
                rect := get_enemy_rect(enemy^)
                rl.DrawRectangleRec(rect, enemy^.color)
            }       
        }
    }
}

get_enemy_rect :: proc(e: Enemy) -> rl.Rectangle {
    return rl.Rectangle{
        x = e.pos.x - e.size.x / 2,
        y = e.pos.y - e.size.y / 2,
        width = e.size.x,
        height = e.size.y,
    }
}