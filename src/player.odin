package fabrayodin

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

PLAYER_SPEED :: 200.0 

Player :: struct {
    pos: rl.Vector2,
    color: rl.Color,
}

init_player :: proc() -> Player {
    player := Player { 
        pos = { 400, 280 }, 
        color = rl.RED,
    }
    return player
}

draw_player :: proc(p: Player) {
    rl.DrawCircleV(p.pos, 25, p.color)
}

update_player :: proc(p: ^Player) {
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
}