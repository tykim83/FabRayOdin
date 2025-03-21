package fabrayodin

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

RG_FRICTION_MULTIPLIER :: 0.998 // Reduces velocity over time
RG_ANGULAR_DAMPING :: 0.95    // Reduces rotation over time
RG_MAX_SPEED :: 300.0         // Limits how fast the car can go
RG_LATERAL_FRICTION_COEFF : f32 = 5.0 // Higher value gives stronger grip.

RigidBody :: struct {
	position: rl.Vector2,
	velocity: rl.Vector2,
	forces: rl.Vector2,
	mass: f32,

	angle: f32,              // in radians
	angular_velocity: f32,
	torque: f32,
	inertia: f32,

	half_size: rl.Vector2,
	rect: rl.Rectangle,
}

init_rigid_body :: proc(rb: ^RigidBody, half_size: rl.Vector2, mass: f32) {
	rb.half_size = half_size
	rb.mass = mass
	// Inertia for a rectangle: I = (1/12)*m*(w^2 + h^2)
	w := half_size.x * 2.0
	h := half_size.y * 2.0
	rb.inertia = (1.0/12.0) * mass * (w*w + h*h)

	// Center the rectangle around the origin.
	rb.rect.x = -rb.half_size.x
	rb.rect.y = -rb.half_size.y
	rb.rect.width  = rb.half_size.x * 2.0
	rb.rect.height = rb.half_size.y * 2.0
}

update_rigid_body :: proc(rb: ^RigidBody, dt: f32) {
    // Apply lateral friction to reduce sideways sliding
    // Compute side unit vectors based on current angle.
    side : rl.Vector2 = { -math.sin(rb.angle), math.cos(rb.angle) }
    lateral_speed := linalg.dot(rb.velocity, side)
      
    lateral_correction := side * (-lateral_speed * RG_LATERAL_FRICTION_COEFF)
    // Apply the lateral correction force over dt.
    rb.velocity = rb.velocity + lateral_correction * dt

    // Continue with normal integration
    // Linear integration:
    acceleration := rb.forces * (1.0 / rb.mass)
    rb.velocity = rb.velocity + acceleration * dt
    rb.position = rb.position + rb.velocity * dt
    rb.forces = {0, 0}

    // to remove
    // Update rb.rect to reflect the new position.
    rb.rect.x = rb.position.x - rb.half_size.x
    rb.rect.y = rb.position.y - rb.half_size.y

    // Angular integration:
    angAcc := rb.torque / rb.inertia
    rb.angular_velocity += angAcc * dt
    rb.angle += rb.angular_velocity * dt
    rb.torque = 0

    // Apply damping to stabilize overall motion.
    rb.velocity = rb.velocity * RG_FRICTION_MULTIPLIER
    rb.angular_velocity *= RG_ANGULAR_DAMPING

    // Clamp Top Speed
    speed := linalg.length(rb.velocity)
    unit_velocity := linalg.normalize0(rb.velocity)

    if speed > RG_MAX_SPEED {
        rb.velocity = unit_velocity * RG_MAX_SPEED
    }
}

draw_rigid_body :: proc(rb: RigidBody, texture: rl.Texture2D) {
    src_rect := rl.Rectangle{ x = 0, y = 0, width = f32(texture.width), height = f32(texture.height) }
    dest_rect, origin, rotation := get_rigid_body_draw_params(rb)
    rl.DrawTexturePro(texture, src_rect, dest_rect, origin, rotation, rl.WHITE)

    dest_rect_1 := rl.Rectangle{
        x = rb.position.x,
        y = rb.position.y,
        width = rb.half_size.x * 2.0,
        height = rb.half_size.y * 2.0,
    }
    origin_1 := rb.half_size  // rotate about the center
    rotation_1 := rb.angle * (180.0 / math.PI)  // convert to degrees
    
    rl.DrawRectanglePro(dest_rect_1, origin_1, rotation_1, rl.WHITE)

    corners := get_rigid_body_collision_box(rb)
    rl.DrawLineV(corners[0], corners[1], rl.GREEN)
    rl.DrawLineV(corners[1], corners[2], rl.GREEN)
    rl.DrawLineV(corners[2], corners[3], rl.GREEN)
    rl.DrawLineV(corners[3], corners[0], rl.GREEN)
}

set_rigid_body_location :: proc(rb: ^RigidBody, position: rl.Vector2, angle: f32) {
	rb.position = position
	rb.angle = angle
}

add_rigid_body_force :: proc(rb: ^RigidBody, force: rl.Vector2) {
	rb.forces = rb.forces + force
}

add_rigid_body_torque :: proc(rb: ^RigidBody, torque: f32) {
	rb.torque += torque
}

get_rigid_body_collision_box :: proc(rb: RigidBody) -> [4]rl.Vector2 {
    // Define the local corners of the box relative to its center.
    local_corners: [4]rl.Vector2 = {
        { -rb.half_size.x, -rb.half_size.y }, // bottom-left
        {  rb.half_size.x, -rb.half_size.y }, // bottom-right
        {  rb.half_size.x,  rb.half_size.y }, // top-right
        { -rb.half_size.x,  rb.half_size.y }  // top-left
    };

    // Precompute the cosine and sine of the rotation angle.
    // This defines the rotation matrix:
    // [ cos(angle)  -sin(angle) ]
    // [ sin(angle)   cos(angle) ]
    c := math.cos(rb.angle)
    s := math.sin(rb.angle)

    // Prepare an array to store the world-space corners.
    corners: [4]rl.Vector2

    // For each local corner, rotate it and then translate by the body's position.
    for point, i in local_corners {
        // Using linalg.dot to compute the rotated coordinates.
        rotated_x := linalg.dot(point, rl.Vector2{ c, -s })
        rotated_y := linalg.dot(point, rl.Vector2{ s,  c })

        // The rotated point in object space.
        rotated_point := rl.Vector2{ rotated_x, rotated_y }

        // Translate the rotated point to world space.
        corners[i] = rb.position + rotated_point
    }

    return corners
}

@(private = "file")
get_rigid_body_draw_params :: proc(rb: RigidBody) -> (rl.Rectangle, rl.Vector2, f32) {
    dest_rect : rl.Rectangle = {
        x = rb.position.x - 2,
        y = rb.position.y,
        width  = 70,
        height = 34,
    }
    origin : = rb.half_size
    rotation := rb.angle * (180.0 / math.PI)
    
    return dest_rect, origin, rotation
}
