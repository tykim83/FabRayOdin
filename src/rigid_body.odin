package fabrayodin

import "core:math"
import rl "vendor:raylib"

vector_add :: proc(a, b: rl.Vector2) -> rl.Vector2 {
    return { a.x + b.x, a.y + b.y }
}

vector_sub :: proc(a, b: rl.Vector2) -> rl.Vector2 {
    return { a.x - b.x, a.y - b.y }
}

vector_mul :: proc(v: rl.Vector2, s: f32) -> rl.Vector2 {
    return { v.x * s, v.y * s }
}

vector_div :: proc(v: rl.Vector2, s: f32) -> rl.Vector2 {
    return { v.x / s, v.y / s }
}

// 2D cross product (returns a scalar, since we're in 2D)
vector_cross :: proc(a, b: rl.Vector2) -> f32 {
    return a.x * b.y - a.y * b.x
}

// RigidBody structure, representing our physics object.
RigidBody :: struct {
    // Linear properties
    position: rl.Vector2,
    velocity: rl.Vector2,
    forces: rl.Vector2,
    mass: f32,

    // Angular properties
    angle: f32,           // in radians
    angular_velocity: f32,
    torque: f32,
    inertia: f32,

    // Graphical properties
    half_size: rl.Vector2,
    // We'll use raylib's Rectangle for drawing.
    rect: rl.Rectangle,
    color: rl.Color,
}

// Setup the rigid body with half_size, mass, and a color.
init_rigid_body :: proc(rb: ^RigidBody, half_size: rl.Vector2, mass: f32, color: rl.Color) {
    rb.half_size = half_size;
    rb.mass = mass;
    rb.color = color;
    // Example inertia formula (you might adjust this)
    rb.inertia = (1.0 / 12.0) * (half_size.x * half_size.x) * (half_size.y * half_size.y) * mass;
    
    // Set up the drawing rectangle. In Odin, we'll assume rect.X, rect.Y is the top-left.
    // Here we center it so that the rectangle goes from -half_size to +half_size.
    rb.rect.x = -rb.half_size.x;
    rb.rect.y = -rb.half_size.y;
    rb.rect.width = rb.half_size.x * 2.0;
    rb.rect.height = rb.half_size.y * 2.0;
}

// Set the location and angle (in radians)
set_location :: proc(rb: ^RigidBody, position: rl.Vector2, angle: f32) {
    rb.position = position;
    rb.angle = angle;
}

// Returns the current position
get_position :: proc(rb: ^RigidBody) -> rl.Vector2 {
    return rb.position
}

// Update the physics simulation
Update :: proc(rb: ^RigidBody, timeStep: f32) {
    // Linear integration:
    acceleration := vector_div(rb.forces, rb.mass)
    rb.velocity = vector_add(rb.velocity, vector_mul(acceleration, timeStep))
    rb.position = vector_add(rb.position, vector_mul(rb.velocity, timeStep))
    rb.forces = { 0, 0 } // reset forces

    // Angular integration:
    angAcc := rb.torque / rb.inertia;
    rb.angular_velocity += angAcc * timeStep;
    rb.angle += rb.angular_velocity * timeStep;
    rb.torque = 0; // reset torque
}

// Draw the rigid body using raylib functions
draw_rigid_body :: proc(rb: RigidBody) {
    // Save the current transform state (if needed)
    // Transform drawing: translate and rotate around rb.position.
    // Here we assume the drawing function uses rb.position as the origin for drawing.
    // In raylib, you might use DrawRectanglePro:
    origin := rb.half_size.xy  // pivot at center
    // Create a destination rectangle at rb.position
    dest_rect: rl.Rectangle = {
        x = rb.position.x - rb.half_size.x,
        y = rb.position.y - rb.half_size.y,
        width = rb.half_size.x * 2,
        height = rb.half_size.y * 2,
    };

    // Draw the rectangle representing the rigid body:
    rl.DrawRectanglePro(dest_rect, origin, rb.angle * (180.0 / math.PI), rb.color);

    // Optionally, draw a line indicating the forward direction:
    // Calculate a forward vector (e.g., 1,0 rotated by rb.angle)
    forward : rl.Vector2 = {
        math.cos(rb.angle),
        math.sin(rb.angle),
    }
    // Draw a line from the center towards the forward direction:
    center : rl.Vector2 = { rb.position.x, rb.position.y }
    end_point : rl.Vector2 =  {
        center.x + forward.x * 20.0, // 20 pixels length, for example
        center.y + forward.y * 20.0,
    };
    rl.DrawLineV(center, end_point, rl.YELLOW);
}

// Convert a relative vector (in the body's coordinate space) to world space.
relative_to_world :: proc(rb: ^RigidBody, relative: rl.Vector2) -> rl.Vector2 {
    cos_theta := math.cos(rb.angle);
    sin_theta := math.sin(rb.angle);
    return {
        relative.x * cos_theta - relative.y * sin_theta,
        relative.x * sin_theta + relative.y * cos_theta,
    }
}

// Convert a world vector to the body's relative coordinate space.
world_to_relative :: proc(rb: ^RigidBody, world: rl.Vector2) -> rl.Vector2 {
    // Inverse rotation is -rb.angle.
    cos_theta := math.cos(-rb.angle);
    sin_theta := math.sin(-rb.angle);
    return {
        world.x * cos_theta - world.y * sin_theta,
        world.x * sin_theta + world.y * cos_theta,
    }
}

// Compute the velocity of a point on the body given an offset in world space.
point_vel :: proc(rb: ^RigidBody, worldOffset: rl.Vector2) -> rl.Vector2 {
    // The tangent vector is perpendicular to worldOffset.
    tangent : rl.Vector2 = { -worldOffset.y, worldOffset.x }
    return vector_add(vector_mul(tangent, rb.angular_velocity), rb.velocity);
}

// Apply a force at a given offset (in world space) to the body.
add_force :: proc(rb: ^RigidBody, worldForce, worldOffset: rl.Vector2) {
    rb.forces = vector_add(rb.forces, worldForce);
    rb.torque += vector_cross(worldOffset, worldForce);
}
