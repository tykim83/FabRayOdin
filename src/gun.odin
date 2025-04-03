package fabrayodin

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

BULLET_SPEED :: 300
BULLET_SPAWN_TIMER :: 5.0

Gun :: struct {
    offset: Vector2f,
	pos: Vector2f,
    half_size: Vector2f,
    angle: f32,
    bullet_count: int,
    bullet_spawn_timer: f32,
    bullet_pos: Vector2f,
    bullet_enemy: ^Enemy,
}

init_gun :: proc(car: Car, offset: Vector2f) -> Gun {  
    return Gun {
        offset = offset,
        pos = car.rb.position + offset,
        half_size = { 16, 8 },
        angle = 0,
        bullet_count = 0,
        bullet_spawn_timer = 0,
    }
}

update_gun :: proc(gun: ^Gun, car: Car, enemies: ^[dynamic]Enemy, dt: f32) {
    // Update Pos
	sin_theta := math.sin(car.rb.angle)
	cos_theta := math.cos(car.rb.angle)

	rotated_offset := Vector2f{
		gun.offset.x * cos_theta - gun.offset.y * sin_theta,
		gun.offset.x * sin_theta + gun.offset.y * cos_theta,
	}

	gun.pos = car.rb.position + rotated_offset

    // Find closest enemy
    current_distance := math.max(f32)
    if gun.bullet_enemy != nil {
        delta := gun.bullet_enemy.pos - gun.pos
        current_distance = length_squared(delta)
    }   
    for &enemy, i in enemies {
        delta := enemy.pos - gun.pos
        dist_sq := length_squared(delta)

        if dist_sq <= current_distance {
            gun.bullet_enemy = &enemy
            current_distance = dist_sq
        }
    }

    // Update angle
    if gun.bullet_enemy != nil && gun.bullet_enemy.is_alive {
        direction := gun.bullet_enemy.pos - gun.pos
        target_angle := math.atan2(direction.y, direction.x)
        gun.angle = math.angle_lerp(gun.angle, target_angle, 0.05) 
    }

    // Spawn bullet
    gun.bullet_spawn_timer += dt
    if gun.bullet_count < 1 && gun.bullet_spawn_timer > BULLET_SPAWN_TIMER {
        gun.bullet_count += 1
        gun.bullet_spawn_timer = 0.0

        forward := Vector2f { math.cos(gun.angle), math.sin(gun.angle) }
        pos := gun.pos + forward * 16

        gun.bullet_pos = pos
    }

    // Update bullet
    if gun.bullet_count > 0 {
        direction := gun.bullet_enemy.pos - gun.bullet_pos
        direction = linalg.normalize0(direction)
        
        // update enemy position using the normalized direction
        gun^.bullet_pos += direction * BULLET_SPEED * dt

        if rl.CheckCollisionCircles(gun.bullet_pos, 8, gun.bullet_enemy.pos, ENEMY_SIZE) {
            damage_enemy(gun.bullet_enemy, 1)
            gun.bullet_count = 0
        }
    }
}

draw_gun :: proc(gun: Gun) {
    // Draw Rectangle
    dest_rect_1 := rl.Rectangle{
        x = gun.pos.x,
        y = gun.pos.y,
        width = gun.half_size.x * 2.0,
        height = gun.half_size.y * 2.0,
    }
    rotation_1 := gun.angle * (180.0 / math.PI)  
    rl.DrawRectanglePro(dest_rect_1, gun.half_size, rotation_1, rl.BLUE)

    // Draw pointer
    line_length: f32 = 16;
    end_point := rl.Vector2 {
        gun.pos.x + math.cos(gun.angle) * line_length,
        gun.pos.y + math.sin(gun.angle) * line_length,
    };
    rl.DrawLineV(gun.pos, end_point, rl.RED);

    // Draw bullet
    if gun.bullet_count > 0 {
        rl.DrawCircle(i32(gun.bullet_pos.x), i32(gun.bullet_pos.y), 8, rl.RED)
    }
}
