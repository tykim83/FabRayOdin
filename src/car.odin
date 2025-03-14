package fabrayodin

import "core:os"
import path "core:path/slashpath"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

START_CAR_POSITION : rl.Vector2 : { 400, 280 }
CAR_HALF_SIZE : rl.Vector2 : {32, 16}
CAR_MASS :: 5.0

car_texture : rl.Texture2D

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
        throttle = 250.0
    }
    if rl.IsKeyDown(.S) {
        throttle = -250.0
    }
    if rl.IsKeyDown(.A) {
        steering = -100.0 
    }
    if rl.IsKeyDown(.D) {
        steering = 100.0
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
    steering_factor := math.clamp(current_speed / 10.0, 0.0, 1.0)
    effective_steering := steering * steering_factor
	
    // Add torque
	steering_multiplier: f32 = 100.0
	add_rigid_body_torque(&car.rb, effective_steering * steering_multiplier)
	
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
    // Get car's oriented bounding box corners.
    carCorners := get_rigid_body_collision_box(car.rb)
    
    // Define the wall's corners (axis aligned).
    wallCorners: [4]rl.Vector2 = {
        { wall.x, wall.y },
        { wall.x + wall.width, wall.y },
        { wall.x + wall.width, wall.y + wall.height },
        { wall.x, wall.y + wall.height }
    }
    
    // Determine collision axes using SAT.
    edge1 := carCorners[1] - carCorners[0]
    axis1 := linalg.normalize0(edge1)
    axis1_normal := rl.Vector2{ -axis1.y, axis1.x }
    
    edge2 := carCorners[2] - carCorners[1]
    axis2 := linalg.normalize0(edge2)
    axis2_normal := rl.Vector2{ -axis2.y, axis2.x }
    
    // For the wall (axis aligned), we use (1,0) and (0,1).
    axes: []rl.Vector2 = { axis1_normal, axis2_normal, {1, 0}, {0, 1} }
    
    // Compute the MTV (minimum translation vector) along the axis with the smallest overlap.
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
        // Make sure the MTV pushes the car away from the wall.
        wall_center := rl.Vector2{ wall.x + wall.width / 2, wall.y + wall.height / 2 }
        diff := car.rb.position - wall_center
        if linalg.dot(diff, mtv_axis) < 0 {
            mtv_axis = mtv_axis * -1.0
        }
        
        mtv := mtv_axis * mtv_overlap
        
        // Adjust the car's position.
        car.rb.position += mtv
        
        // Decompose velocity into normal and tangential components.
        proj := linalg.dot(car.rb.velocity, mtv_axis)
        normal_component := mtv_axis * proj
        tangent_component := car.rb.velocity - normal_component
        
        restitution : f32 = 0.2  // Bounce factor.
        new_normal := normal_component * -restitution
        
        // Combine and add some damping (energy loss).
        car.rb.velocity = (tangent_component + new_normal) * 0.6
        
        // --- Calculate contact point on the car ---
        // Choose the car corner that is deepest along the collision normal.
        contact_point := carCorners[0]
        min_proj := linalg.dot(contact_point, mtv_axis)
        for point in carCorners {
            p_proj := linalg.dot(point, mtv_axis)
            if p_proj < min_proj {
                min_proj = p_proj
                contact_point = point
            }
        }
        
        // Compute the lever arm from the car's center to the contact point.
        lever_arm := contact_point - car.rb.position
        
        // --- Compute impulse and torque ---
        // Use the magnitude of the car's velocity along the collision normal.
        impulse_magnitude := (1 + restitution) * math.abs(proj) * car.rb.mass
        impulse := mtv_axis * impulse_magnitude
        
        // 2D cross product (scalar) gives the torque contribution.
        torque_impulse := lever_arm.x * impulse.y - lever_arm.y * impulse.x
        
        // --- Factor in the car's driving direction ---
        // Get the car's forward vector.
        forward := rl.Vector2{ math.cos(car.rb.angle), math.sin(car.rb.angle) }
        // Compute a front impact factor: if the car is driving toward the wall head‑on,
        // dot(forward, -mtv_axis) will be high.
        front_dot := linalg.dot(forward, mtv_axis * -1.0)
        // Clamp between 0 and 1.
        front_factor := math.max(0.0, math.min(front_dot, 1.0))
        torque_impulse *= front_factor
        
        // Apply the torque impulse to modify angular velocity.
        car.rb.angular_velocity += torque_impulse / car.rb.inertia
    }
}
