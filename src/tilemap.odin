package fabrayodin

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

init_tilemap :: proc() -> [3]rl.Rectangle {
    walls : [3]rl.Rectangle = {
        rl.Rectangle{
            x = SCREEN_WIDTH / 2 + 400,
            y = SCREEN_HEIGHT / 2 - 100,
            width = 32,
            height = 200,
        },
        rl.Rectangle{
            x = SCREEN_WIDTH / 2 - 200,  
            y = SCREEN_HEIGHT / 2 - 250,  
            width = 400,
            height = 32,
        },
        rl.Rectangle{
            x = SCREEN_WIDTH / 2 - 50,
            y = SCREEN_HEIGHT / 2 - 250,
            width = 32,
            height = 450,
        }
    }

    return walls
}

draw_tilemap :: proc(walls: [3]rl.Rectangle) {
    for wall in walls {
        rl.DrawRectangleRec(wall, rl.RED)
    }
}
