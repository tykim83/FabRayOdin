package fabrayodin

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

ENEMY_SPEED :: 100
ENEMY_SIZE :: 10
ENEMY_SPAWN_TIMER :: 0.3
enemy_count := 0
global_spawn_timer: f32 = 0.2

Enemy :: struct {
    pos: Vector2f,
    posDraw : Vector2f,
}

init_enemies :: proc(allocator := context.allocator, loc := #caller_location) -> [dynamic]Enemy {
    enemies := make([dynamic]Enemy, 0, allocator, loc)

    return enemies
}

destroy_enemies :: proc(enemies: [dynamic]Enemy, loc := #caller_location) {
    delete(enemies, loc)
}

spawn_enemies :: proc(enemies: ^[dynamic]Enemy, frame_time: f32, loc := #caller_location) {
    global_spawn_timer += frame_time
    if enemy_count < 1000 && global_spawn_timer > ENEMY_SPAWN_TIMER {
        enemy_count += 1
        global_spawn_timer = 0.0

        enemy := Enemy {
            pos = {70, 70}
        }
        append(enemies, enemy, loc)
    }
}

draw_enemies :: proc(enemies: []Enemy) {
    for enemy in enemies {
        rl.DrawCircle(i32(enemy.posDraw.x), i32(enemy.posDraw.y), ENEMY_SIZE, rl.RED)
    }
}

update_enemies :: proc(enemies: []Enemy, flow_field: Flow_Field, dt: f32) {
    for &enemy in enemies {

        delta := Vector2f {
            flow_field.target.x - enemy.pos.x,
            flow_field.target.y - enemy.pos.y,
        }
        distanceToTarget := math.sqrt(delta.x * delta.x + delta.y * delta.y)
        
        // Determine how far to move this frame.
        distanceMove := ENEMY_SPEED * dt
        if distanceMove > distanceToTarget {
            distanceMove = distanceToTarget
        }

        if flow_dir, ok := get_flow_direction(enemy.pos, flow_field); ok {
            separation := compute_separation_normal(enemy, enemies[:])
            wall_repulsion := compute_wall_repulsion(enemy, flow_field)
            
            // Blend flow and separation
            blended_dir := Vector2f{
                flow_dir.x + separation.x * 5.0 + wall_repulsion.x * 10.0,
                flow_dir.y + separation.y * 5.0 + wall_repulsion.y * 10.0,
            }

            // Normalize the final direction
            mag := math.sqrt(blended_dir.x * blended_dir.x + blended_dir.y * blended_dir.y)
            if mag > 0.01 {
                blended_dir.x /= mag
                blended_dir.y /= mag
            }

            posAdd := Vector2f{
                blended_dir.x * distanceMove,
                blended_dir.y * distanceMove,
            }

            // Store this for the overlap check
            next_pos := enemy.pos + posAdd

            moveOk := true

            for &other_enemy in enemies {
                if &enemy == &other_enemy { 
                    continue
                 }

                if check_overlap(next_pos, other_enemy.pos, ENEMY_SIZE, ENEMY_SIZE) {
                    // Compute vector from this enemy to the other.
                    directionToOther := Vector2f {
                        other_enemy.pos.x - enemy.pos.x,
                        other_enemy.pos.y - enemy.pos.y,
                    }
                    // Calculate the magnitude.
                    mag := math.sqrt(directionToOther.x * directionToOther.x + directionToOther.y * directionToOther.y)
                    if mag > 0.01 {
                        // Normalize directionToOther.
                        norm := Vector2f {
                            directionToOther.x / mag,
                            directionToOther.y / mag,
                        }
                        // Calculate the dot product with the movement direction.
                        dot := norm.x * blended_dir.x + norm.y * blended_dir.y
                        // Clamp dot to the range [-1, 1] (for acos safety).
                        if dot > 1.0 { dot = 1.0 }
                        if dot < -1.0 { dot = -1.0 }
                        // Get the angle between the two directions.
                        angleBtw := math.acos(dot)
                        // If the angle is less than 45° (pi/4), cancel the move.
                        if angleBtw < math.PI/4.0 {
                            moveOk = false
                            break
                        }
                    }
                }
            }

            if moveOk {
                spacing: f32 = GRID_TILE_SIZE / 2.0 // or adjust to your comfort

                // Save original pos
                original_pos := enemy.pos
                
                // X axis
                if posAdd.x != 0.0 {
                    check_x := enemy.pos.x + posAdd.x + math.copy_sign(spacing, posAdd.x)
                    x := int(check_x)
                    y := int(enemy.pos.y)
                    grid_x := x / GRID_TILE_SIZE
                    grid_y := y / GRID_TILE_SIZE
                
                    if flow_field.nodes[grid_y * GRID_COLUMNS + grid_x].is_walkable {
                        enemy.pos.x += posAdd.x * 0.9
                    }
                }
                
                // Y axis
                if posAdd.y != 0.0 {
                    check_y := enemy.pos.y + posAdd.y + math.copy_sign(spacing, posAdd.y)
                    x := int(enemy.pos.x)
                    y := int(check_y)
                    grid_x := x / GRID_TILE_SIZE
                    grid_y := y / GRID_TILE_SIZE
                
                    if flow_field.nodes[grid_y * GRID_COLUMNS + grid_x].is_walkable {
                        enemy.pos.y += posAdd.y * 0.9
                    }
                }
            
                // Smooth draw position
                enemy.posDraw = linalg.lerp(enemy.posDraw, enemy.pos, 0.07)
            }
        }
    }
}

@(private = "file")
compute_wall_repulsion :: proc(enemy: Enemy, flow_field: Flow_Field) -> Vector2f {
    repulsion := Vector2f{0, 0}
    sample_radius: int = 1  // Check one tile in each direction
    center_tile := Vector2i{ int(enemy.pos.x) / GRID_TILE_SIZE, int(enemy.pos.y) / GRID_TILE_SIZE }
    count := 0

    for dy in -sample_radius..=sample_radius+1 {
        for dx in -sample_radius..=sample_radius+1 {
            tile_x := center_tile.x + dx
            tile_y := center_tile.y + dy
            index := tile_y * GRID_COLUMNS + tile_x
            if tile_x >= 0 && tile_y >= 0 && index >= 0 && index < len(flow_field.nodes) {
                if !flow_field.nodes[index].is_walkable {
                    // Calculate the center of this wall tile
                    tile_center := Vector2f{
                        f32(tile_x) * GRID_TILE_SIZE + GRID_TILE_SIZE / 2.0,
                        f32(tile_y) * GRID_TILE_SIZE + GRID_TILE_SIZE / 2.0,
                    }
                    // Compute direction from the wall to the enemy
                    dir := enemy.pos - tile_center
                    dist := math.sqrt(dir.x * dir.x + dir.y * dir.y)
                    if dist > 0.01 {
                        // A stronger force when closer (falloff with distance)
                        repulsion.x += (dir.x / dist) / dist
                        repulsion.y += (dir.y / dist) / dist
                        count += 1
                    }
                }
            }
        }
    }

    // Average the repulsion if multiple walls were detected
    if count > 0 {
        repulsion.x /= f32(count)
        repulsion.y /= f32(count)
    }

    // Normalize the repulsion vector (if it's non-zero)
    mag := math.sqrt(repulsion.x * repulsion.x + repulsion.y * repulsion.y) * 0.9
    if mag > 0.01 {
        repulsion.x /= mag
        repulsion.y /= mag
    }

    return repulsion
}

@(private = "file")
compute_separation_normal :: proc(enemy: Enemy, enemies: []Enemy) -> Vector2f {
    output := Vector2f{0, 0}
    radius_separation: f32 = ENEMY_SIZE * 3

    for &other in enemies {
        if other == enemy {
            continue
        }

        direction := Vector2f {
            other.pos.x - enemy.pos.x,
            other.pos.y - enemy.pos.y,
        }

        distance := math.sqrt(direction.x * direction.x + direction.y * direction.y)

        if distance <= radius_separation && distance > 0.01 {
            // Normalize and invert the direction to push away from other unit
            normal := Vector2f{
                -direction.x / distance,
                -direction.y / distance,
            }
            output.x += normal.x
            output.y += normal.y
        }
    }

    // Normalize the output if it's non-zero
    mag := math.sqrt(output.x * output.x + output.y * output.y)
    if mag > 0.01 {
        output.x /= mag
        output.y /= mag
    }

    return output
}

@(private = "file")
check_overlap :: proc(a, b: rl.Vector2, ra, rb: f32) -> bool {
    delta := b - a
    distance_squared := delta.x * delta.x + delta.y * delta.y
    radius_sum := ra + rb
    return distance_squared <= radius_sum * radius_sum
}
