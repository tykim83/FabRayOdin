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
	
    // Add torque
	steering_multiplier: f32 = 100.0
	add_rigid_body_torque(&car.rb, steering * steering_multiplier)
	
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

// Resolve collision between the car (as an OBB) and an axis-aligned wall using SAT.
// This function computes the MTV (minimum translation vector) and applies it to the car.
resolve_collision_car_wall_sat :: proc(car: ^Car, wall: rl.Rectangle) {
    // Get the car's oriented bounding box corners.
    carCorners := get_rigid_body_collision_box(car.rb)
    
    // Define the wall's corners (since the wall is axis aligned).
    wallCorners: [4]rl.Vector2 = {
        { wall.x, wall.y },
        { wall.x + wall.width, wall.y },
        { wall.x + wall.width, wall.y + wall.height },
        { wall.x, wall.y + wall.height }
    }
    
    // Determine the axes to test.
    // For the car, we use the normals of its two edges.
    edge1 := carCorners[1] - carCorners[0]
    axis1 := linalg.normalize0(edge1)
    // The normal to edge1:
    axis1_normal := rl.Vector2{ -axis1.y, axis1.x }
    
    edge2 := carCorners[2] - carCorners[1]
    axis2 := linalg.normalize0(edge2)
    // The normal to edge2:
    axis2_normal := rl.Vector2{ -axis2.y, axis2.x }
    
    // For the wall, since it is axis aligned, we can use (1,0) and (0,1).
    axes: []rl.Vector2 = { axis1_normal, axis2_normal, {1, 0}, {0, 1} }
    
    // Initialize MTV (minimum translation vector) parameters.
    mtv_overlap : f32 = 1e9  // a large number
    mtv_axis    : rl.Vector2 = {0, 0}
    collision   : bool = true
    
    // Test each axis.
    for axis in axes {
        car_min, car_max := project_polygon(axis, carCorners)
        wall_min, wall_max := project_polygon(axis, wallCorners)
        
        // Check if there is a separating axis.
        if car_max < wall_min || wall_max < car_min {
            collision = false
            break
        }
        
        // Compute the overlap on this axis.
        overlap := math.min(car_max, wall_max) - math.max(car_min, wall_min)
        if overlap < mtv_overlap {
            mtv_overlap = overlap
            mtv_axis = axis
        }
    }

    if collision {
        // Ensure the MTV pushes the car away from the wall.
        wall_center := rl.Vector2{ wall.x + wall.width/2, wall.y + wall.height/2 }
        diff := car.rb.position - wall_center
        if linalg.dot(diff, mtv_axis) < 0 {
            mtv_axis = mtv_axis * -1.0
        }
        
        // Compute the MTV.
        mtv := mtv_axis * mtv_overlap
        
        // Adjust the car's position.
        car.rb.position = car.rb.position + mtv
        
        // Decompose the velocity into normal and tangent components.
        proj := linalg.dot(car.rb.velocity, mtv_axis)
        normal_component := mtv_axis * proj
        tangent_component := car.rb.velocity - normal_component
    
        // Apply restitution to the normal component for a bounce effect.
        restitution : f32 = 0.3  // 1 = full bounce, adjust as needed
        new_normal := normal_component * -restitution
    
        // Combine the components.
        car.rb.velocity = tangent_component + new_normal
    }
}
