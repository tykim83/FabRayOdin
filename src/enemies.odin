package fabrayodin

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

active_enemies: []^Enemy

ENEMY_SPAWN_TIMER :: 3.0
global_spawn_timer: f32 = 0.0

Enemy :: struct {
    pos: rl.Vector2,
    size: rl.Vector2,
    color: rl.Color,
}

Spawn_Location :: enum {
    Left,
    Right,
    Top,
    Bottom,
}

add_enemy_to_spatial_grid :: proc(enemy: ^Enemy, grid: ^Spatial_Grid, loc := #caller_location) {
    enemy_col, enemy_row := get_spatial_grid_pos(enemy.pos)
    index := enemy_row * grid.columns + enemy_col

    if index >= 0 && index < len(grid.cells) { 
        enemies := &grid.cells[index].enemies
        append(enemies, enemy, loc)
        fmt.println(enemy)
    }
}

spawn_enemies :: proc(frame_time: f32, spatial_grid: ^Spatial_Grid) {
    global_spawn_timer += frame_time
    if global_spawn_timer > ENEMY_SPAWN_TIMER {
        global_spawn_timer = 0.0
        pos: rl.Vector2

        sp := rand.choice_enum(Spawn_Location)
        switch sp {
            case .Top, .Bottom:
                x := rand.float32() * 800
                y := (f32)(rand.int31_max(2) * 640)
                pos = { x, y }
            case .Left, .Right:
                x := (f32)(rand.int31_max(2) * 1280)
                y := rand.float32() * 450
                pos = { x, y }
        }

        enemy := Enemy {
            pos = pos,
            size = {32, 32},
            color = rl.GRAY,
        }

        enemy_ptr := new(Enemy)
        enemy_ptr^ = enemy 

        add_enemy_to_spatial_grid(enemy_ptr, spatial_grid)
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