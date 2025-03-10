package fabrayodin

import "core:fmt"
import "core:strings"
// import "core:math"
// import "core:math/rand"
import "core:mem"
import vmem "core:mem/virtual"
import rl "vendor:raylib"

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720

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

	rl.InitWindow(1280, 640, "Test")
	defer rl.CloseWindow()   

	rl.SetTargetFPS(60)      

    spatial_grid := init_spatial_grid(SCREEN_WIDTH, SCREEN_HEIGHT, debug = true)
    init_enemies()
    player := init_player()
    walls := init_tilemap()

	for !rl.WindowShouldClose() { 
        free_all(context.temp_allocator)
        mouse_pos := rl.GetMousePosition()
        frame_time := rl.GetFrameTime()

        spawn_enemies(frame_time, &spatial_grid)
        update_enemies(&spatial_grid, mouse_pos, player, frame_time)
        update_player(&player, frame_time, walls)

        rl.BeginDrawing()
        defer rl.EndDrawing()

        draw_spatial_grid(&spatial_grid)
        draw_enemies(&spatial_grid)
        draw_player(player)
        draw_tilemap(walls)

        rl.ClearBackground(rl.RAYWHITE)
	}

    destroy_spatial_grid(&spatial_grid)
    destroy_enemies()
}