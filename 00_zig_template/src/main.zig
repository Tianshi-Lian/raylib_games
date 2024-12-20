const rl = @import("raylib");

const screenWidth = 800;
const screenHeight = 450;

pub fn main() anyerror!void {
    rl.initWindow(screenWidth, screenHeight, "raylib-zig");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    const texture = rl.loadTexture("assets/test.png");

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        const texture_x = (screenWidth / 2) - @divFloor(texture.width, 2);
        const texture_y = (screenHeight / 2) - @divFloor(texture.height, 2);
        rl.drawTexture(texture, texture_x, texture_y, rl.Color.white);

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.light_gray);
    }
}
