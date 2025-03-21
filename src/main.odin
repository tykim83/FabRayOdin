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
    spatial_grid := init_spatial_grid(SCREEN_WIDTH, SCREEN_HEIGHT, debug = true); defer destroy_spatial_grid(&spatial_grid)
    init_enemies(); defer destroy_enemies()
    car := init_car()
    tilemap := init_tilemap()

    // Pathfinder test
    path_min : Vector2 = {0, 0}
	path_max : Vector2 = {TILEMAP_WIDTH - 1, TILEMAP_HEIGHT - 1}
    astar := init_grid(path_min, path_max)
    defer destroy_grid(&astar)

    for layer in tilemap.layers {
        if !layer.is_visible { continue }

        for tile, index in layer.data {
            if (tile == -1) { continue }
            row := index / TILEMAP_WIDTH
            col := index % TILEMAP_WIDTH
            set_blocked_tile(&astar, {i32(col),i32(row)})
        }
    }

	for !rl.WindowShouldClose() { 
        free_all(context.temp_allocator)
        mouse_pos := rl.GetMousePosition()
        frame_time := rl.GetFrameTime()

        // Update Game
        spawn_enemies(frame_time, &spatial_grid)
        update_car(&car, frame_time, tilemap)
        update_enemies(&spatial_grid, mouse_pos, car, frame_time, tilemap)   
        update_astar_path(car, &spatial_grid, astar)

        rl.BeginDrawing()
        defer rl.EndDrawing()

        // Draw Game
        draw_spatial_grid(&spatial_grid)
        draw_enemies(&spatial_grid)
        draw_car(car)
        draw_tilemap(tilemap)

        rl.ClearBackground(rl.RAYWHITE)
	}
}
