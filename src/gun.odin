package fabrayodin

// import "core:fmt"
// import "core:math"
// import "core:math/linalg"
// import rl "vendor:raylib"

// BULLET_SPEED :: 300
// BULLET_SPAWN_TIMER :: 5.0
// bullet_count := 0
// global_bullet_spawn_timer: f32 = 0.0

// Gun :: struct {
// 	pos: rl.Vector2,
//     half_size: rl.Vector2,
//     angle: f32,
//     bullet_pos: rl.Vector2,
//     bullet_enemy: int
// }

// init_gun :: proc(car: Car) -> Gun {  
//     return Gun {
//         pos = car.rb.position,
//         // pos = { 32 + 16, 32 + 16 },
//         half_size = { 16, 8 },
//         angle = 0,
//     }
// }

// update_gun :: proc(gun: ^Gun, car: Car, dt: f32) {
//     // Update Pos
//     gun.pos = car.rb.position

//     // Find closest enemy
//     closest_distance := math.max(int)
//     index := -1
//     for enemy, i in active_enemies {
//         direction := rl.Vector2{
//             enemy.pos.x - gun.pos.x,
//             enemy.pos.y - gun.pos.y,
//         }
//         len := math.sqrt(direction.x * direction.x + direction.y * direction.y)

//         if int(len) <= closest_distance {
//             closest_distance = int(len)
//             index = i
//         }
//     }

//     // Update angle
//     if index != -1 {
//         target_enemy := active_enemies[index]
//         direction := rl.Vector2{
//             target_enemy.pos.x - gun.pos.x,
//             target_enemy.pos.y - gun.pos.y,
//         }
//         gun.angle = math.atan2(direction.y, direction.x)
//     }

//     // Spawn bullet
//     global_bullet_spawn_timer += dt
//     if bullet_count < 1 && global_bullet_spawn_timer > BULLET_SPAWN_TIMER {
//         bullet_count += 1
//         global_bullet_spawn_timer = 0.0
//         pos := rl.Vector2 {
//             gun.pos.x + math.cos(gun.angle) * 16,
//             gun.pos.y + math.sin(gun.angle) * 16,
//         };  

//         gun.bullet_enemy = index
//         gun.bullet_pos = pos
//     }

//     // Update bullet
//     if bullet_count > 0 {
//         target_enemy := active_enemies[gun.bullet_enemy]
//         direction := rl.Vector2 {
//             target_enemy.pos.x - gun.bullet_pos.x,
//             target_enemy.pos.y - gun.bullet_pos.y,
//         }
//         direction = linalg.normalize0(direction)
        
//         // update enemy position using the normalized direction
//         gun^.bullet_pos.x += direction.x * BULLET_SPEED * dt
//         gun^.bullet_pos.y += direction.y * BULLET_SPEED * dt

//         enemy_rect := rl.Rectangle {
//             x = target_enemy.pos.x,
//             y = target_enemy.pos.y,
//             width = target_enemy.size.x,
//             height = target_enemy.size.y,
//         }
//         if rl.CheckCollisionCircleRec(gun.bullet_pos, 8, enemy_rect) {
//             ordered_remove(&active_enemies, gun.bullet_enemy)
//             bullet_count = 0
//         }
//     }
// }

// draw_gun :: proc(gun: Gun) {
//     // Draw Rectangle
//     dest_rect_1 := rl.Rectangle{
//         x = gun.pos.x,
//         y = gun.pos.y,
//         width = gun.half_size.x * 2.0,
//         height = gun.half_size.y * 2.0,
//     }
//     rotation_1 := gun.angle * (180.0 / math.PI)  
//     rl.DrawRectanglePro(dest_rect_1, gun.half_size, rotation_1, rl.BLUE)

//     // Draw pointer
//     line_length: f32 = 16;
//     end_point := rl.Vector2 {
//         gun.pos.x + math.cos(gun.angle) * line_length,
//         gun.pos.y + math.sin(gun.angle) * line_length,
//     };
//     rl.DrawLineV(gun.pos, end_point, rl.RED);

//     // Draw bullet
//     if bullet_count > 0 {
//         rl.DrawCircle(i32(gun.bullet_pos.x), i32(gun.bullet_pos.y), 8, rl.RED)
//     }
// }
