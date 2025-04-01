package fabrayodin

import "core:fmt"
import "core:mem"
import vmem "core:mem/virtual"
import rl "vendor:raylib"

SCREEN_WIDTH :: 1600
SCREEN_HEIGHT :: 960
GRID_COLUMNS :: SCREEN_WIDTH / GRID_TILE_SIZE
GRID_ROWS :: SCREEN_HEIGHT / GRID_TILE_SIZE
GRID_TILE_SIZE :: 64

main :: proc() {
    // Tracking memory leaks
    when ODIN_DEBUG { // this is not a real scope
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer { // so this defer will run at the of main
            if len(track.allocation_map) > 0 {
                for _, entry in track.allocation_map {
                    fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
                }
            }
            if len(track.bad_free_array) > 0 {
                for entry in track.bad_free_array {
                    fmt.eprintf("%v bad free at %v\n", entry.location, entry.memory)
                }
            }
            mem.tracking_allocator_destroy(&track)
        }
    }

    // Init Raylib
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Test"); defer rl.CloseWindow()
	rl.SetTargetFPS(60)      

    // Init Game
    // init_enemies(); defer destroy_enemies()
    car := init_car()
    // gun := init_gun(car)
    tilemap := init_tilemap()
    flow_field := init_pathfinding(tilemap); defer destroy_pathfinding(&flow_field)

	for !rl.WindowShouldClose() { 
        free_all(context.temp_allocator)
        mouse_pos := rl.GetMousePosition()
        frame_time := rl.GetFrameTime()

        // Update Game
        // spawn_enemies(frame_time)
        update_car(&car, frame_time, tilemap, &flow_field)
        // update_gun(&gun, car, frame_time)
        // update_enemies(mouse_pos, car, frame_time, tilemap, astar_grid)   

        rl.BeginDrawing()
        defer rl.EndDrawing()
        rl.ClearBackground(rl.RAYWHITE)
        
        // Draw Game
        // draw_tilemap(tilemap)
        // draw_enemies()
        draw_pathfinding(flow_field)
        draw_car(car)
        // draw_gun(gun)

        // Draw Debug
        rl.DrawFPS(200, 10)
        // text := fmt.caprintf("Total enemies: {}", len(active_enemies))
        // rl.DrawText(text, 300, 10, 25, rl.RED)      
	}
}
