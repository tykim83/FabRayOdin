package fabrayodin

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:mem"
import rl "vendor:raylib"

BULLET_SPEED :: 300
BULLET_SPAWN_TIMER :: 5.0

GUN_OFFSETS : [Anchor_Point]Vector2f = #partial {
    .Top_Right = {+32, -20},
    .Top_Left = {-32, -20},
    .Bottom_Left = {-32, +20},
    .Bottom_Right = {+32, +20},
}

Gun :: struct {
    offset: Vector2f,
	pos: Vector2f,
    half_size: Vector2f,
    angle: f32,
    // bullet_count: int,
    bullet_spawn_timer: f32,
    // bullet_pos: Vector2f,
    closest_enemy: ^Enemy,
    bullets: [dynamic]Bullet,
}

Bullet :: struct {
    pos: Vector2f,
    direction: Vector2f,
}

init_gun :: proc(car: Car, anchor_point: Anchor_Point, allocator := context.allocator, loc := #caller_location) -> Gun {  
    offset := GUN_OFFSETS[anchor_point]
    bullets := make([dynamic]Bullet, 0, allocator, loc)

    return Gun {
        offset = offset,
        pos = car.rb.position + offset,
        half_size = { 16, 8 },
        angle = 0,
        bullet_spawn_timer = 0,
        bullets = bullets,
    }
}

destroy_gun :: proc(gun: ^Gun, loc := #caller_location) {  
    if gun == nil { return }
    delete(gun.bullets, loc)
}

update_gun :: proc(gun: ^Gun, car: Car, enemies: ^[dynamic]Enemy, dt: f32) {
    // Update gun pos
	sin_theta := math.sin(car.rb.angle)
	cos_theta := math.cos(car.rb.angle)

	rotated_offset := Vector2f{
		gun.offset.x * cos_theta - gun.offset.y * sin_theta,
		gun.offset.x * sin_theta + gun.offset.y * cos_theta,
	}

	gun.pos = car.rb.position + rotated_offset

    // Update gun angle
    closest_direction : Vector2f = { 0, 0 }
    current_distance := math.max(f32)

    for enemy, i in enemies {
        if !enemy.is_alive { continue }

        delta := enemy.pos - gun.pos
        dist_sq := length_squared(delta)

        if dist_sq <= current_distance {
            closest_direction = delta
            current_distance = dist_sq
        }
    }

    target_angle := math.atan2(closest_direction.y, closest_direction.x)
    gun.angle = math.angle_lerp(gun.angle, target_angle, 0.05) 

    // Spawn bullet
    gun.bullet_spawn_timer += dt
    if gun.bullet_spawn_timer > BULLET_SPAWN_TIMER {
        gun.bullet_spawn_timer = 0.0

        forward := Vector2f { math.cos(gun.angle), math.sin(gun.angle) }
        pos := gun.pos + forward * 16

        bullet := Bullet {
            pos = pos,
            direction = forward,
        }
        append(&gun.bullets, bullet)
    }

    // Update bullet
    for &bullet, i in gun.bullets {
        bullet.pos += bullet.direction * BULLET_SPEED * dt

        for &enemy in enemies {
            if rl.CheckCollisionCircles(bullet.pos, 8, enemy.pos, ENEMY_SIZE) {
                damage_enemy(&enemy, 1)
                unordered_remove(&gun.bullets, i)
            }
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
    for bullet in gun.bullets {
        rl.DrawCircle(i32(bullet.pos.x), i32(bullet.pos.y), 4, rl.BLUE)
    }
}
