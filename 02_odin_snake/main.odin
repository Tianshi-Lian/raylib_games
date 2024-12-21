package snake

import rl "vendor:raylib"

WINDOW_SIZE :: 1000
GRID_SIZE :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_SIZE * CELL_SIZE
TICK_RATE :: 0.13
MAX_SNAKE_LENGTH :: GRID_SIZE * GRID_SIZE

Vec2i :: [2]i32

tick_timer: f32 = TICK_RATE
snake: [MAX_SNAKE_LENGTH]Vec2i
snake_length: int
move_direction: Vec2i
food_position: Vec2i
score: i32
game_over: bool

restart :: proc() {
    game_over = false
    start_head_position := Vec2i{GRID_SIZE / 2, GRID_SIZE / 2}
    snake[0] = start_head_position
    snake[1] = start_head_position - {0, 1}
    snake[2] = start_head_position - {0, 2}
    snake_length = 3
    move_direction = {0, 1}
    score = 0
    place_food()
}

place_food :: proc() {
    occupied_positions: [GRID_SIZE][GRID_SIZE]bool
    for i in 0 ..< snake_length {
        occupied_positions[snake[i].x][snake[i].y] = true
    }

    for {
        food_position = {rl.GetRandomValue(0, GRID_SIZE - 1), rl.GetRandomValue(0, GRID_SIZE - 1)}
        if !occupied_positions[food_position.x][food_position.y] {
            break
        }
    }
}

main :: proc() {
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Snake")
    defer rl.CloseWindow()

    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()

    eat_sound := rl.LoadSound("assets/eat.wav")
    defer rl.UnloadSound(eat_sound)
    crash_sound := rl.LoadSound("assets/crash.wav")
    defer rl.UnloadSound(crash_sound)

    rl.SetTargetFPS(300)

    camera := rl.Camera2D {
        zoom = f32(WINDOW_SIZE) / CANVAS_SIZE,
    }

    restart()

    for !rl.WindowShouldClose() {
        if (rl.IsKeyDown(.UP) || rl.IsKeyDown(.W)) && move_direction.y != 1 {
            move_direction = {0, -1}
        } else if (rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S)) && move_direction.y != -1 {
            move_direction = {0, 1}
        } else if (rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A)) && move_direction.x != 1 {
            move_direction = {-1, 0}
        } else if (rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D)) && move_direction.x != -1 {
            move_direction = {1, 0}
        }

        if !game_over {
            tick_timer -= rl.GetFrameTime()
        } else {
            if rl.IsKeyDown(.R) {
                restart()
            }
        }

        if tick_timer <= 0 {
            next_part_position := snake[0]
            snake[0] += move_direction

            for i in 1 ..< snake_length {
                current_part_position := snake[i]
                snake[i] = next_part_position
                next_part_position = current_part_position

                if snake[i] == snake[0] {
                    game_over = true
                    rl.PlaySound(crash_sound)
                    break
                }
            }

            if snake[0].x < 0 || snake[0].x >= GRID_SIZE || snake[0].y < 0 || snake[0].y >= GRID_SIZE {
                game_over = true
                rl.PlaySound(crash_sound)
            }

            if snake[0] == food_position {
                snake[snake_length] = snake[snake_length - 1]
                snake_length += 1
                score += 10
                rl.PlaySound(eat_sound)
                place_food()
            }

            tick_timer = TICK_RATE
        }

        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground({76, 53, 83, 255})

        rl.BeginMode2D(camera)

        food_rect := rl.Rectangle {
            x      = f32(food_position.x) * CELL_SIZE,
            y      = f32(food_position.y) * CELL_SIZE,
            width  = CELL_SIZE,
            height = CELL_SIZE,
        }
        rl.DrawRectangleRec(food_rect, {255, 80, 80, 255})

        for i in 0 ..< snake_length {
            snake_part_rect := rl.Rectangle {
                x      = f32(snake[i].x) * CELL_SIZE,
                y      = f32(snake[i].y) * CELL_SIZE,
                width  = CELL_SIZE,
                height = CELL_SIZE,
            }

            rl.DrawRectangleRec(snake_part_rect, {255, 255, 255, 255})
        }

        rl.EndMode2D()


        if !game_over {
            rl.DrawText(rl.TextFormat("Score: %d", score), 10, 10, 24, {255, 255, 255, 255})
        } else {
            game_over_text := rl.TextFormat("Game Over! Score: %d", score)
            rl.DrawText(
                game_over_text,
                WINDOW_SIZE / 2 - rl.MeasureText(game_over_text, 32) / 2,
                WINDOW_SIZE / 2 - 25,
                32,
                {255, 255, 255, 255},
            )
            rl.DrawText(
                "Press R to Restart",
                WINDOW_SIZE / 2 - rl.MeasureText("Press R to Restart", 20) / 2,
                WINDOW_SIZE / 2 + 25,
                20,
                {255, 255, 255, 255},
            )
        }

        rl.DrawFPS(WINDOW_SIZE - 100, 10)
    }
}
