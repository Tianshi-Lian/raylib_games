package project

import rl "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

main :: proc() {
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Project")
    defer rl.CloseWindow()

    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()

    rl.SetTargetFPS(300)

    texture: rl.Texture2D = rl.LoadTexture("assets/test.png")

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground({150, 190, 220, 255})

        rl.DrawTexture(texture, 0, 0, {255, 255, 255, 255})
        rl.DrawFPS(WINDOW_WIDTH - 100, 10)
    }
}
