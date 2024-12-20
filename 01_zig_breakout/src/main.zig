const std = @import("std");
const rl = @import("raylib");

const screenWidth = 500;
const screenHeight = 600;

const Player = struct {
    rect: rl.Rectangle = std.mem.zeroInit(rl.Rectangle, .{}),
    velocity: f32 = 250.0,
    score: i32 = 0,
    width: f32 = 75.0,
    height: f32 = 10.0,
};

const Ball = struct {
    position: rl.Vector2 = std.mem.zeroInit(rl.Vector2, .{}),
    acceleration: rl.Vector2 = rl.Vector2{ .x = 1.0, .y = 1.0 },
    velocity: f32,
    radius: f32 = 5.0,
};

const Brick = struct {
    rect: rl.Rectangle = std.mem.zeroInit(rl.Rectangle, .{}),
    color: rl.Color = rl.Color.white,
    width: f32 = 50.0,
    height: f32 = 20.0,
};

var background: rl.Texture2D = undefined;
var player: Player = undefined;
var ball: Ball = std.mem.zeroInit(Ball, .{});
var bricks: std.ArrayList(Brick) = undefined;
var brickHitSound: [2]rl.Sound = undefined;
var playerHitSound: rl.Sound = undefined;

fn game_startup() anyerror!void {
    background = rl.loadTexture("assets/background.png");
    brickHitSound[0] = rl.loadSound("assets/brick-hit-1.wav");
    brickHitSound[1] = rl.loadSound("assets/brick-hit-2.wav");
    playerHitSound = rl.loadSound("assets/paddle-hit-1.wav");

    player = std.mem.zeroInit(Player, .{});
    player.rect = rl.Rectangle{ .x = 250.0, .y = 540.0, .width = 75.0, .height = 10.0 };
    player.score = 0;

    ball = std.mem.zeroInit(Ball, .{});
    ball.position = rl.Vector2{ .x = 300.0, .y = 300.0 };
    ball.velocity = 200.0;

    const colors = [7]rl.Color{ rl.Color.red, rl.Color.orange, rl.Color.yellow, rl.Color.green, rl.Color.blue, rl.Color.purple, rl.Color.violet };

    bricks = std.ArrayList(Brick).init(std.heap.page_allocator);
    for (0..8) |i| {
        for (0..8) |j| {
            var new_brick = Brick{};
            new_brick.rect = rl.Rectangle{ .x = (@as(f32, @floatFromInt(i)) * (new_brick.width + 5)) + 30, .y = (@as(f32, @floatFromInt(j)) * (new_brick.height + 5)) + 50, .width = new_brick.width, .height = new_brick.height };
            new_brick.color = colors[@as(usize, @intCast(rl.getRandomValue(0, colors.len - 1)))];
            try bricks.append(new_brick);
        }
    }
}

fn game_update() void {
    const frame_time = rl.getFrameTime();

    if (rl.isKeyDown(rl.KeyboardKey.key_a) or rl.isKeyDown(rl.KeyboardKey.key_left)) {
        player.rect.x -= player.velocity * frame_time;
    }
    if (rl.isKeyDown(rl.KeyboardKey.key_d) or rl.isKeyDown(rl.KeyboardKey.key_right)) {
        player.rect.x += player.velocity * frame_time;
    }

    ball.position.x += ball.acceleration.x * ball.velocity * frame_time;
    ball.position.y += ball.acceleration.y * ball.velocity * frame_time;

    if (player.rect.x < 0) {
        player.rect.x = 0;
    }
    if (player.rect.x + player.rect.width > screenWidth) {
        player.rect.x = screenWidth - player.rect.width;
    }

    if (ball.position.x < 0) {
        ball.position.x = 0;
        ball.acceleration.x *= -1;
    } else if (ball.position.x > screenWidth) {
        ball.position.x = screenWidth;
        ball.acceleration.x *= -1;
    }

    if (ball.position.y < 0) {
        ball.position.y = screenHeight;
        ball.acceleration.y *= -1;
    } else if (ball.position.y > screenHeight) {
        ball.position.y = screenHeight;
        ball.acceleration.y *= -1;
    }

    if (rl.checkCollisionCircleRec(ball.position, ball.radius, player.rect)) {
        ball.acceleration.y *= -1;
        ball.position.y = player.rect.y - ball.radius;
        rl.playSound(playerHitSound);
    }

    for (bricks.items, 0..) |brick, index| {
        if (rl.checkCollisionCircleRec(ball.position, ball.radius, brick.rect)) {
            ball.acceleration.y *= -1;
            rl.playSound(brickHitSound[@as(usize, @intCast(rl.getRandomValue(0, 1)))]);
            _ = bricks.orderedRemove(index);
            player.score += 10;
        }
    }
}

fn game_render() void {
    rl.drawTexture(background, 0, 0, rl.Color.white);
    rl.drawRectangleRec(player.rect, rl.Color.yellow);
    rl.drawCircle(@intFromFloat(ball.position.x), @intFromFloat(ball.position.y), ball.radius, rl.Color.white);

    for (bricks.items) |brick| {
        rl.drawRectangleRec(brick.rect, brick.color);
    }

    rl.drawText(rl.textFormat("Score: %d", .{player.score}), 10, 10, 32, rl.Color.white);
    rl.drawText(rl.textFormat("FPS: %d", .{rl.getFPS()}), 300, 10, 32, rl.Color.white);
}

fn game_shutdown() void {
    rl.unloadTexture(background);
    rl.unloadSound(brickHitSound[0]);
    rl.unloadSound(brickHitSound[1]);
    rl.unloadSound(playerHitSound);

    bricks.deinit();
}

pub fn main() anyerror!void {
    rl.initWindow(screenWidth, screenHeight, "raylib-zig");
    defer rl.closeWindow();

    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    //rl.setTargetFPS(60);

    try game_startup();

    while (!rl.windowShouldClose()) {
        game_update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        game_render();
    }

    game_shutdown();
}
