package breakout

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

WINDOW_SIZE :: 1280
SCREEN_SIZE :: 320

PADDLE_WIDTH :: 50
PADDLE_HEIGHT :: 6
PADDLE_POS_Y :: 260
PADDLE_SPEED :: 200

BALL_RADIUS :: 12
BALL_SPEED :: 240

NUM_BRICKS_X :: 10
NUM_BRICKS_Y :: 8
BRICK_WIDTH :: 28
BRICK_HEIGHT :: 10

Block_Color :: enum {
    Yellow,
    Green,
    Orange,
    Red,
}
block_colors := [Block_Color]rl.Color {
    .Yellow = {253, 249, 150, 255},
    .Green  = {180, 245, 190, 255},
    .Orange = {170, 120, 250, 255},
    .Red    = {250, 90, 85, 255},
}
row_colors := [NUM_BRICKS_Y]Block_Color{.Red, .Red, .Orange, .Orange, .Yellow, .Yellow, .Green, .Green}


paddle_pos_x: f32

ball_pos: rl.Vector2
ball_dir: rl.Vector2

bricks: [NUM_BRICKS_X][NUM_BRICKS_Y]bool

game_playing: bool
game_over: bool
score: int

restart :: proc() {
    paddle_pos_x = SCREEN_SIZE / 2 - PADDLE_WIDTH / 2
    ball_pos = {SCREEN_SIZE / 2, 160}

    game_playing = false
    game_over = false
    score = 0

    for x in 0 ..< NUM_BRICKS_X {
        for y in 0 ..< NUM_BRICKS_Y {
            bricks[x][y] = true
        }
    }
}

draw_rect_outline :: proc(rect: ^rl.Rectangle) {
    rl.DrawLineEx({rect.x, rect.y}, {rect.x, rect.y + rect.height}, 1, {255, 255, 150, 100})
    rl.DrawLineEx({rect.x, rect.y}, {rect.x + rect.width, rect.y}, 1, {255, 255, 150, 100})
    rl.DrawLineEx({rect.x + rect.width, rect.y}, {rect.x + rect.width, rect.y + rect.height}, 1, {0, 0, 50, 100})
    rl.DrawLineEx({rect.x, rect.y + rect.height}, {rect.x + rect.width, rect.y + rect.height}, 1, {0, 0, 50, 100})
}

main :: proc() {
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Breakout")
    defer rl.CloseWindow()

    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()

    rl.SetTargetFPS(300)

    hit_block_sound := rl.LoadSound("assets/hit_block.wav")
    hit_paddle_sound := rl.LoadSound("assets/hit_paddle.wav")
    game_over_sound := rl.LoadSound("assets/game_over.wav")

    camera := rl.Camera2D {
        zoom = WINDOW_SIZE / SCREEN_SIZE,
    }

    restart()

    for !rl.WindowShouldClose() {
        defer free_all(context.temp_allocator)
        delta_time := rl.GetFrameTime()

        if !game_playing && !game_over {
            ball_pos = {SCREEN_SIZE / 2 + f32(math.cos(rl.GetTime()) * SCREEN_SIZE / 2.5), ball_pos.y}

            if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
                paddle_middle := rl.Vector2{paddle_pos_x + PADDLE_WIDTH / 2, PADDLE_POS_Y}
                ball_to_paddle := paddle_middle - ball_pos
                ball_dir = linalg.normalize(ball_to_paddle)
                game_playing = true
            }
            delta_time = 0
        } else if game_over {
            if rl.IsKeyPressed(rl.KeyboardKey.R) {
                restart()
            }
            delta_time = 0
        }

        ball_pos += ball_dir * BALL_SPEED * delta_time

        if ball_pos.x - BALL_RADIUS < 0 {
            ball_pos.x = BALL_RADIUS
            ball_dir.x = -ball_dir.x
        } else if ball_pos.x + BALL_RADIUS > SCREEN_SIZE {
            ball_pos.x = SCREEN_SIZE - BALL_RADIUS
            ball_dir.x = -ball_dir.x
        }

        if ball_pos.y - BALL_RADIUS < 0 {
            ball_pos.y = BALL_RADIUS
            ball_dir.y = -ball_dir.y
        } else if ball_pos.y > SCREEN_SIZE + BALL_RADIUS * 6 {
            if !game_over {
                rl.PlaySound(game_over_sound)
                game_over = true
            }
        }

        paddle_move_velocity: f32
        if rl.IsKeyDown(rl.KeyboardKey.RIGHT) || rl.IsKeyDown(rl.KeyboardKey.D) {
            paddle_move_velocity += PADDLE_SPEED
        }
        if rl.IsKeyDown(rl.KeyboardKey.LEFT) || rl.IsKeyDown(rl.KeyboardKey.A) {
            paddle_move_velocity -= PADDLE_SPEED
        }
        paddle_pos_x += paddle_move_velocity * delta_time
        paddle_pos_x = clamp(paddle_pos_x, 0, SCREEN_SIZE - PADDLE_WIDTH)

        paddle_rect := rl.Rectangle {
            x      = paddle_pos_x,
            y      = PADDLE_POS_Y,
            width  = PADDLE_WIDTH,
            height = PADDLE_HEIGHT,
        }

        if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, paddle_rect) {
            ball_dir.y = -ball_dir.y
            ball_pos.y = PADDLE_POS_Y - BALL_RADIUS
            rl.PlaySound(hit_paddle_sound)
        }

        outer: for x in 0 ..< NUM_BRICKS_X {
            for y in 0 ..< NUM_BRICKS_Y {
                if bricks[x][y] {
                    brick_rect := rl.Rectangle {
                        x      = f32(20 + x * BRICK_WIDTH),
                        y      = f32(40 + y * BRICK_HEIGHT),
                        width  = BRICK_WIDTH,
                        height = BRICK_HEIGHT,
                    }
                    if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, brick_rect) {
                        bricks[x][y] = false
                        ball_dir.y = -ball_dir.y
                        score += 10
                        rl.PlaySound(hit_block_sound)
                        if score == NUM_BRICKS_X * NUM_BRICKS_Y * 10 {
                            game_over = true
                        }
                        break outer
                    }
                }
            }
        }

        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground({150, 190, 220, 255})

        rl.BeginMode2D(camera)

        rl.DrawRectangleRec(paddle_rect, {50, 150, 90, 255})
        draw_rect_outline(&paddle_rect)
        rl.DrawCircleV(ball_pos, BALL_RADIUS, {200, 90, 90, 255})

        for x in 0 ..< NUM_BRICKS_X {
            for y in 0 ..< NUM_BRICKS_Y {
                if bricks[x][y] {
                    block_rect := rl.Rectangle {
                        x      = f32(20 + x * BRICK_WIDTH),
                        y      = f32(40 + y * BRICK_HEIGHT),
                        width  = BRICK_WIDTH,
                        height = BRICK_HEIGHT,
                    }

                    rl.DrawRectangleRec(block_rect, block_colors[row_colors[y]])
                    draw_rect_outline(&block_rect)
                }
            }
        }

        rl.EndMode2D()

        if !game_playing && !game_over {
            title_text := fmt.ctprint("Press SPACE to start")
            rl.DrawText(title_text, (WINDOW_SIZE - rl.MeasureText(title_text, 80)) / 2, 60, 80, {255, 255, 255, 255})
        }

        if !game_over {
            score_text := fmt.ctprint("Score: ", score)
            rl.DrawText(score_text, 10, 10, 48, {255, 255, 255, 255})
        } else {
            game_over_text: cstring
            if score == NUM_BRICKS_X * NUM_BRICKS_Y * 10 {
                game_over_text = "You win! Press R to restart"
            } else {
                game_over_text = "Game Over! Press R to restart"
            }
            text_width := rl.MeasureText(game_over_text, 56)
            rl.DrawText(game_over_text, (WINDOW_SIZE - text_width) / 2, 30, 56, {255, 255, 255, 255})
            score_text := fmt.ctprint("Score: ", score)
            rl.DrawText(score_text, (WINDOW_SIZE - rl.MeasureText(score_text, 48)) / 2, 100, 48, {255, 255, 255, 255})
        }
        rl.DrawFPS(WINDOW_SIZE - 100, 10)
    }
}
