package fabrayodin

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

PLAYER_SPEED :: 200.0 

Player :: struct {
    pos: rl.Vector2,
    size: rl.Vector2,
    color: rl.Color,
}

init_player :: proc() -> Player {
    player := Player { 
        pos = { 400, 280 }, 
        size = {32, 32},
        color = rl.GREEN,
    }
    return player
}

draw_player :: proc(p: Player) {
    player_rect := get_player_rect(p)
    rl.DrawRectangleRec(player_rect, p.color)
}

update_player :: proc(p: ^Player, dt: f32, walls: [3]rl.Rectangle) {
    // Update player
    dt := rl.GetFrameTime()
    move := rl.Vector2 { 0, 0 }
    
    if rl.IsKeyDown(.W) {
        move.y -= 1
    }
    if rl.IsKeyDown(.S) {
        move.y += 1
    }
    if rl.IsKeyDown(.A) {
        move.x -= 1
    }
    if rl.IsKeyDown(.D) {
        move.x += 1
    }

    len: f32 = math.sqrt(move.x * move.x + move.y * move.y)
    if len > 0 {
        move.x /= len
        move.y /= len
    }

    p^.pos.x += move.x * PLAYER_SPEED * dt
    p^.pos.y += move.y * PLAYER_SPEED * dt

    // Resove collisions
    for wall in walls {
        resolve_collision(p, wall)
    }
}

resolve_collision :: proc(p: ^Player, wall: rl.Rectangle) {
    player_rect := get_player_rect(p^)
    if !rl.CheckCollisionRecs(player_rect, wall) {
        return
    }

    left_overlap  := (player_rect.x + player_rect.width) - wall.x
    right_overlap := (wall.x + wall.width) - player_rect.x
    top_overlap   := (player_rect.y + player_rect.height) - wall.y
    bottom_overlap:= (wall.y + wall.height) - player_rect.y

    // Choose the smallest overlap.
    overlap_x := math.min(left_overlap, right_overlap)
    overlap_y := math.min(top_overlap, bottom_overlap)

    if overlap_x < overlap_y {
        // Adjust horizontally.
        if player_rect.x < wall.x {
            p^.pos.x -= overlap_x
        } else {
            p^.pos.x += overlap_x
        }
    } else {
        // Adjust vertically.
        if player_rect.y < wall.y {
            p^.pos.y -= overlap_y
        } else {
            p^.pos.y += overlap_y
        }
    }
}

get_player_rect :: proc(p: Player) -> rl.Rectangle {
    return rl.Rectangle{
        x = p.pos.x - p.size.x / 2,
        y = p.pos.y - p.size.y / 2,
        width = p.size.x,
        height = p.size.y,
    }
}
