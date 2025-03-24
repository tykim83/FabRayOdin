package fabrayodin

import "core:fmt"
import "core:mem"
import vmem "core:mem/virtual"
import rl "vendor:raylib"

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 704

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
    init_enemies(); defer destroy_enemies()
    car := init_car()
    tilemap := init_tilemap()
    astar_grid := init_pathfinding(tilemap); defer destroy_pathfinding(&astar_grid)

	for !rl.WindowShouldClose() { 
        free_all(context.temp_allocator)
        mouse_pos := rl.GetMousePosition()
        frame_time := rl.GetFrameTime()

        // Update Game
        spawn_enemies(frame_time)
        update_car(&car, frame_time, tilemap)
        update_enemies(mouse_pos, car, frame_time, tilemap, astar_grid)   

        rl.BeginDrawing()
        defer rl.EndDrawing()

        // Draw Game
        draw_tilemap(tilemap)
        draw_enemies()

        // draw_pathfinding(car, astar_grid)
        draw_car(car)

        rl.ClearBackground(rl.RAYWHITE)
	}
}
