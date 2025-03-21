package fabrayodin

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

active_enemies: [dynamic]^Enemy

ENEMY_SPEED :: 100.0
ENEMY_SPAWN_TIMER :: 3.0
enemy_count := 0
global_spawn_timer: f32 = 2.9

Enemy :: struct {
    pos: rl.Vector2,
    grid_index: int,
    size: rl.Vector2,
    color: rl.Color,
}

Spawn_Location :: enum {
    Left,
    Right,
    Top,
    Bottom,
}

init_enemies :: proc(allocator := context.allocator, loc := #caller_location) {
    active_enemies := make([dynamic]^Enemy, 0, allocator, loc)
}

destroy_enemies :: proc() {
    for &enemy in active_enemies {
        free(enemy) 
    }
    delete(active_enemies)
}

update_enemies :: proc(mouse_pos: rl.Vector2, car: Car, frame_time: f32, tilemap: Tilemap) {

    for &enemy in active_enemies {
        // update enemy position
        move := rl.Vector2 {
            car.rb.position.x - enemy.pos.x,
            car.rb.position.y - enemy.pos.y,
        }

        len: f32 = math.sqrt(move.x * move.x + move.y * move.y)
        if len > 0 {
            move.x /= len
            move.y /= len
        }

        enemy^.pos.x += move.x * ENEMY_SPEED * frame_time
        enemy^.pos.y += move.y * ENEMY_SPEED * frame_time

        // Resolve Enemy collision
        for other_enemy_enemy in active_enemies {
            if enemy == other_enemy_enemy { continue }
            
            resolve_enemy_collision(enemy, other_enemy_enemy)
        }

        // Check tilemap collision
        check_tilemap_collision(enemy, tilemap)
    }
}

draw_enemies :: proc() {
    for enemy in active_enemies {
        if enemy != nil {
            rect := get_rect_from_pos_and_size(enemy^)
            rl.DrawRectangleRec(rect, enemy^.color)
        }       
    }
}

spawn_enemies :: proc(frame_time: f32) {
    global_spawn_timer += frame_time
    if enemy_count < 1 && global_spawn_timer > ENEMY_SPAWN_TIMER {
        enemy_count += 1
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
            color = rl.BLUE,
        }

        enemy_ptr := new(Enemy)
        enemy_ptr^ = enemy 

        append(&active_enemies, enemy_ptr)
    }
}

@(private = "file")
resolve_enemy_collision :: proc(e1: ^Enemy, e2: ^Enemy) {
    r1 := get_rect_from_pos_and_size(e1^)
    r2 := get_rect_from_pos_and_size(e2^)
    
    if !rl.CheckCollisionRecs(r1, r2) { return }
    
    // Calculate overlap.
    left_overlap  := (r1.x + r1.width) - r2.x
    right_overlap := (r2.x + r2.width) - r1.x
    top_overlap    := (r1.y + r1.height) - r2.y
    bottom_overlap := (r2.y + r2.height) - r1.y

    // Determine the minimum overlap in each axis.
    overlap_x := math.min(left_overlap, right_overlap)
    overlap_y := math.min(top_overlap, bottom_overlap)
    
    // Push along the axis with the smaller overlap.
    if overlap_x < overlap_y {
        // Adjust horizontally.
        if e1^.pos.x < e2^.pos.x {
            e1^.pos.x -= overlap_x / 2.0
            e2^.pos.x += overlap_x / 2.0
        } else {
            e1^.pos.x += overlap_x / 2.0
            e2^.pos.x -= overlap_x / 2.0
        }
    } else {
        // Adjust vertically.
        if e1^.pos.y < e2^.pos.y {
            e1^.pos.y -= overlap_y / 2.0
            e2^.pos.y += overlap_y / 2.0
        } else {
            e1^.pos.y += overlap_y / 2.0
            e2^.pos.y -= overlap_y / 2.0
        }
    }
}
