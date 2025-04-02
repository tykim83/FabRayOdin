package fabrayodin

import "core:fmt"
import "core:math"
import "core:mem"
import vmem "core:mem/virtual"
import "core:math/linalg"
import queue "core:container/queue"

Vector2i32 :: [2]i32
Vector2i :: [2]int
Vector2f :: [2]f32

CARDINAL_NEIGHBORS :: [4]Vector2i {
    { 1,  0}, // right
    {-1,  0}, // left
    { 0,  1}, // down
    { 0, -1}, // up
}

ALL_NEIGHBORS :: [8]Vector2i {
    { 1,  0}, // right
    {-1,  0}, // left
    { 0,  1}, // down
    { 0, -1}, // up
    { 1,  1}, // right down
    {-1,  1}, // left down
    {-1, -1}, // left up
    { 1, -1}, // right up
}

Flow_Field :: struct {
    target : Vector2f,
    nodes  : []Node,
    allocator : mem.Allocator
}

Node :: struct {
    pos         : Vector2i,
    direction   : Vector2f,
    cost        : f32,
    is_walkable : bool
}

init_flow_field :: proc(region_min, region_max: Vector2i, allocator := context.allocator, loc := #caller_location) -> Flow_Field {
    area := region_max - region_min
    cols := area.x
    rows := area.y
    flow_grid := make([]Node, cols * rows, allocator, loc)

    for &node, i in flow_grid {
        node.pos = { i % cols, i / cols }
        node.cost = math.max(f32)
        node.is_walkable = true
    }

    return Flow_Field {
        nodes = flow_grid,
        target = { 0, 0 },
        allocator = allocator
    }
}

destroy_flow_field :: proc(flow_field: ^Flow_Field, loc := #caller_location) {
    if flow_field == nil { return }
    delete(flow_field.nodes, flow_field.allocator, loc)
}

set_blocked_tile :: proc(flow_field: ^Flow_Field, pos: Vector2i) {
    flow_field.nodes[get_index_from_grid_pos(pos)].is_walkable = false;
}

update_flow_field :: proc(flow_field: ^Flow_Field, target_pos: Vector2f, loc := #caller_location) {
    target_grid_pos : Vector2i = { int(target_pos.x) / GRID_TILE_SIZE, int(target_pos.y) / GRID_TILE_SIZE }
    new_target_index := target_grid_pos.y * GRID_COLUMNS + target_grid_pos.x
    if new_target_index >= len(flow_field.nodes) {
        return
    }

    prev_target_grid_pos : Vector2i = { int(flow_field.target.x) / GRID_TILE_SIZE, int(flow_field.target.y) / GRID_TILE_SIZE }
    if target_grid_pos == prev_target_grid_pos || !flow_field.nodes[new_target_index].is_walkable {
        return
    }
    flow_field.target = { f32(target_grid_pos.x * GRID_TILE_SIZE + GRID_TILE_SIZE / 2), f32(target_grid_pos.y * GRID_TILE_SIZE + GRID_TILE_SIZE / 2) }

    calculate_cost(flow_field^, new_target_index, loc)
    calculate_flow(flow_field^)
}


get_flow_direction :: proc(pos: Vector2f, flow_field: Flow_Field) -> (Vector2f, bool) {
    enemy_grid_pos : Vector2i = { int(pos.x) / GRID_TILE_SIZE, int(pos.y) / GRID_TILE_SIZE }

    if enemy_grid_pos.x < 0 || enemy_grid_pos.x >= GRID_COLUMNS ||
       enemy_grid_pos.y < 0 || enemy_grid_pos.y >= GRID_ROWS {
        return {-1, -1}, false
    }

    index := enemy_grid_pos.y * GRID_COLUMNS + enemy_grid_pos.x
    node := flow_field.nodes[index]

    // return direction to center of target
    target_grid_pos : Vector2i = { int(flow_field.target.x) / GRID_TILE_SIZE, int(flow_field.target.y) / GRID_TILE_SIZE }
    if enemy_grid_pos == target_grid_pos {
        return linalg.normalize0(flow_field.target - pos), true
    }

    // return flow field direction
    return linalg.normalize0(flow_field.nodes[index].direction), true
}

@(private = "file")
calculate_cost :: proc(flow_field: Flow_Field, new_target_index: int, loc := #caller_location) {
    grid_arena: vmem.Arena
    grid_arena_allocator := vmem.arena_allocator(&grid_arena)

    flow_grid := flow_field.nodes

    for &node, i in flow_grid {
        node.cost = math.max(f32)
    }

    openSet: queue.Queue(^Node)
    queue.init(&openSet, allocator = grid_arena_allocator)

    node := &flow_grid[new_target_index]
    node^.cost = 0
    queue.push_back(&openSet, node)

    for queue.len(openSet) > 0 {

        current := queue.pop_front(&openSet)
        
        for neighbor in CARDINAL_NEIGHBORS {
            neighbor_pos := current.pos + neighbor
            neighbor_index := neighbor_pos.y * GRID_COLUMNS + neighbor_pos.x
            if neighbor_index < 0 || neighbor_index >= len(flow_grid) || 
               neighbor_pos.x < 0 || neighbor_pos.x >= GRID_COLUMNS || 
               neighbor_pos.y < 0 || neighbor_pos.y >= GRID_ROWS || 
               !flow_grid[neighbor_index].is_walkable{
                continue
            }

            neighbor_node := &flow_grid[neighbor_index]

            if neighbor_node.cost == math.max(f32) {
                neighbor_node.cost = current.cost + 1
                queue.push_back(&openSet, neighbor_node)
            }
        }
    }

    vmem.arena_destroy(&grid_arena, loc)
}

@(private = "file")
calculate_flow :: proc(flow_field: Flow_Field) {
    flow_grid := flow_field.nodes

    for &node, i in flow_grid {

        if node.cost == math.max(f32) {
            continue
        }

        best_cost := node.cost
        
        for neighbor in ALL_NEIGHBORS {
            neighbor_pos := node.pos + neighbor
            neighbor_index := neighbor_pos.y * GRID_COLUMNS + neighbor_pos.x
            if neighbor_index < 0 || neighbor_index >= len(flow_grid) || 
               neighbor_pos.x < 0 || neighbor_pos.x >= GRID_COLUMNS || 
               neighbor_pos.y < 0 || neighbor_pos.y >= GRID_ROWS {
                continue
            }

            if neighbor.x != 0 && neighbor.y != 0 {
                // Check both orthogonal neighbors
                neighbor_x_pos := node.pos + Vector2i{neighbor.x, 0}
                neighbor_y_pos := node.pos + Vector2i{0, neighbor.y}
                neighbor_x_idx := neighbor_x_pos.y * GRID_COLUMNS + neighbor_x_pos.x
                neighbor_y_idx := neighbor_y_pos.y * GRID_COLUMNS + neighbor_y_pos.x
        
                if (neighbor_x_pos.x < 0 || neighbor_x_pos.x >= GRID_COLUMNS ||
                    neighbor_x_pos.y < 0 || neighbor_x_pos.y >= GRID_ROWS ||
                    neighbor_y_pos.x < 0 || neighbor_y_pos.x >= GRID_COLUMNS ||
                    neighbor_y_pos.y < 0 || neighbor_y_pos.y >= GRID_ROWS) ||
                   (!flow_grid[neighbor_x_idx].is_walkable &&
                    !flow_grid[neighbor_y_idx].is_walkable) {
                    // Both sides are blocked – disallow the diagonal
                    continue
                }
            }

            neighbor_node := flow_grid[neighbor_index]
            if neighbor_node.cost < best_cost {
                best_cost = neighbor_node.cost
                flow_grid[i].direction = { f32(neighbor.x), f32(neighbor.y) }
            }
        }
    }
}
