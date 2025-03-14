package fabrayodin

import "core:os"
import path "core:path/slashpath"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

START_CAR_POSITION : rl.Vector2 : { 400, 280 }
CAR_HALF_SIZE : rl.Vector2 : {32, 16}
car_texture : rl.Texture2D

// Car Movement
CAR_MASS :: 5.0
CAR_ACCELERATION :: 250.0      // How fast the car accelerates
CAR_BRAKE_FORCE :: 250.0       // How strong the car brakes
CAR_STEERING_FORCE :: 100.0    // How strong steering turns the car
CAR_STEERING_SPEED_FACTOR :: 10.0 // Adjusts steering at higher speeds

// 🔄 Collision & Bounce
RESTITUTION :: 0.4         // How much the car bounces off walls
DAMPING :: 0.7             // How much energy is lost after hitting something
REAR_SLOWDOWN_FACTOR :: 0.98 // How much the car slows when the rear barely touches
TORQUE_SCALING :: 2.0      // How much the car spins when hitting walls
LATERAL_TORQUE_FACTOR :: 0.3 // Adjusts spin amount for angled impacts

Car :: struct {
	rb: RigidBody,
}

init_car :: proc() -> Car {  
    car : Car
    car_texture = rl.LoadTexture("src/Assets/Player/car_1.png")

	set_rigid_body_location(&car.rb, START_CAR_POSITION, -math.PI/2)
	init_rigid_body(&car.rb, CAR_HALF_SIZE, CAR_MASS)
    return car
}

update_car :: proc(car: ^Car, dt: f32, tilemap: Tilemap) {
    onRoad : bool = true
    traction : f32 = 1
    throttle: f32 = 0
    steering: f32 = 0

    if rl.IsKeyDown(.W) {
        throttle = CAR_ACCELERATION
    }
    if rl.IsKeyDown(.S) {
        throttle = -CAR_BRAKE_FORCE
    }
    if rl.IsKeyDown(.A) {
        steering = -CAR_STEERING_FORCE
    }
    if rl.IsKeyDown(.D) {
        steering = CAR_STEERING_FORCE
    }
    if rl.IsKeyDown(.R) {
        traction = 1.0
    }
    if rl.IsKeyDown(.F) {
        traction = 0.6
    }

    // Add force
	forward : rl.Vector2 = { math.cos(car.rb.angle), math.sin(car.rb.angle) };
	drive_force := forward * throttle * traction; // Traction can make car slower
	add_rigid_body_force(&car.rb, drive_force)

    // Compute current speed.
    current_speed := linalg.length(car.rb.velocity)
    // Compute a steering factor that scales from 0 to 1 based on speed.
    // Adjust the divisor (here 10.0) as needed for your game.
    steering_factor := math.clamp(current_speed / CAR_STEERING_SPEED_FACTOR, 0.0, 1.0)
    effective_steering := steering * steering_factor
	
    // Add torque
	add_rigid_body_torque(&car.rb, effective_steering * CAR_STEERING_FORCE)
	
    // Update rigid body
	update_rigid_body(&car.rb, dt)

    // Resolve collisions
    walls := get_tilemap_collision_rects(tilemap)

    for wall in walls {
        resolve_collision_car_wall_sat(car, wall)  
    }
}

draw_car :: proc(car: Car) {
    speed_pixels := linalg.length(car.rb.velocity)
    speed_kmh : f32 = speed_pixels
    rl.DrawText(fmt.caprintf("Speed: %.1f km/h", speed_kmh), 5, 10, 20, rl.DARKGRAY)

	draw_rigid_body(car.rb, car_texture)
}

// Project a set of points onto an axis.
// Returns the minimum and maximum projection values.
project_polygon :: proc(axis: rl.Vector2, points: [4]rl.Vector2) -> (f32, f32) {
    min_val := linalg.dot(points[0], axis)
    max_val := min_val
    for point in points {
        p := linalg.dot(point, axis)
        if p < min_val { min_val = p }
        if p > max_val { max_val = p }
    }
    return min_val, max_val
}

resolve_collision_car_wall_sat :: proc(car: ^Car, wall: rl.Rectangle) {
    carCorners := get_rigid_body_collision_box(car.rb)

    wallCorners: [4]rl.Vector2 = {
        { wall.x, wall.y },
        { wall.x + wall.width, wall.y },
        { wall.x + wall.width, wall.y + wall.height },
        { wall.x, wall.y + wall.height }
    }

    edge1 := carCorners[1] - carCorners[0]
    axis1 := linalg.normalize0(edge1)
    axis1_normal := rl.Vector2{ -axis1.y, axis1.x }

    edge2 := carCorners[2] - carCorners[1]
    axis2 := linalg.normalize0(edge2)
    axis2_normal := rl.Vector2{ -axis2.y, axis2.x }

    axes: []rl.Vector2 = { axis1_normal, axis2_normal, {1, 0}, {0, 1} }

    mtv_overlap : f32 = 1e9
    mtv_axis    : rl.Vector2 = {0, 0}
    collision   : bool = true

    for axis in axes {
        car_min, car_max := project_polygon(axis, carCorners)
        wall_min, wall_max := project_polygon(axis, wallCorners)

        if car_max < wall_min || wall_max < car_min {
            collision = false
            break
        }

        overlap := math.min(car_max, wall_max) - math.max(car_min, wall_min)
        if overlap < mtv_overlap {
            mtv_overlap = overlap
            mtv_axis = axis
        }
    }

    if collision {
        wall_center := rl.Vector2{ wall.x + wall.width / 2, wall.y + wall.height / 2 }
        diff := car.rb.position - wall_center
        if linalg.dot(diff, mtv_axis) < 0 {
            mtv_axis = mtv_axis * -1.0
        }

        mtv := mtv_axis * mtv_overlap

        // 🛠️ **Fix: Smooth Rear Contact Slowdown**
        movement_direction := linalg.normalize0(car.rb.velocity)

        contact_point := carCorners[0]
        min_proj := linalg.dot(contact_point, mtv_axis)
        for point in carCorners {
            p_proj := linalg.dot(point, mtv_axis)
            if p_proj < min_proj {
                min_proj = p_proj
                contact_point = point
            }
        }

        is_rear_contact := linalg.dot(movement_direction, contact_point - car.rb.position) < 0

        if is_rear_contact {
            // Smooth slowdown instead of instant stop
            car.rb.velocity *= REAR_SLOWDOWN_FACTOR  // Reduce velocity very slightly to avoid flickering.
            return  // Exit to avoid full collision resolution for rear contacts.
        }

        car.rb.position += mtv

        proj := linalg.dot(car.rb.velocity, mtv_axis)
        normal_component := mtv_axis * proj
        tangent_component := car.rb.velocity - normal_component

        effective_direction : rl.Vector2
        if linalg.length(car.rb.velocity) > 0.1 {
            effective_direction = linalg.normalize0(car.rb.velocity)
        } else {
            effective_direction = rl.Vector2{ math.cos(car.rb.angle), math.sin(car.rb.angle) }
        }

        impact_factor := math.clamp(linalg.dot(effective_direction, -mtv_axis), 0.0, 1.0)

        new_normal := normal_component * -RESTITUTION
        car.rb.velocity = (tangent_component + new_normal) * DAMPING

        lever_arm := contact_point - car.rb.position

        impulse_magnitude := (1 + RESTITUTION) * math.abs(proj) * car.rb.mass * impact_factor
        impulse := mtv_axis * impulse_magnitude

        torque_impulse := (lever_arm.x * impulse.y - lever_arm.y * impulse.x) * TORQUE_SCALING

        lateral_impact_factor := 1.0 - math.abs(linalg.dot(lever_arm, mtv_axis))
        lateral_impact_factor = math.clamp(lateral_impact_factor, LATERAL_TORQUE_FACTOR, 1.0)

        torque_impulse *= lateral_impact_factor

        car.rb.angular_velocity += torque_impulse / car.rb.inertia
    }
}
