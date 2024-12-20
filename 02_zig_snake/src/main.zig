const std = @import("std");
const rl = @import("raylib");

const cell_size = 30;
const cell_count = 25;
const play_width = cell_size * cell_count;
const play_height = cell_size * cell_count;

const screen_offset_x = cell_size * 2;
const screen_offset_y = cell_size * 2;
const screen_width = play_width + screen_offset_x * 2;
const screen_height = play_height + screen_offset_y * 2;

const color_green: rl.Color = .{ .r = 173, .g = 204, .b = 96, .a = 255 };
const color_dark_green: rl.Color = .{ .r = 43, .g = 51, .b = 24, .a = 255 };

var last_update: f64 = 0;

var snake_body: std.ArrayList(rl.Vector2) = undefined;
var snake_direction: rl.Vector2 = undefined;

var food_position: rl.Vector2 = undefined;
var food_texture: rl.Texture2D = undefined;

var eat_sound: rl.Sound = undefined;
var wall_hit_sound: rl.Sound = undefined;

var score: i32 = 0;

fn init_snake() anyerror!void {
    snake_body = std.ArrayList(rl.Vector2).init(std.heap.page_allocator);
    snake_direction = .{ .x = 1, .y = 0 };

    try snake_body.append(rl.Vector2{ .x = 6, .y = 9 });
    try snake_body.append(rl.Vector2{ .x = 5, .y = 9 });
    try snake_body.append(rl.Vector2{ .x = 4, .y = 9 });
}

fn deinit_snake() void {
    snake_body.deinit();
    snake_body = undefined;
    snake_direction = undefined;
}

fn init_food() anyerror!void {
    food_texture = rl.loadTexture("assets/food.png");
    food_position = .{ .x = 0, .y = 0 };
    reset_food_position();
}

fn deinit_food() void {
    rl.unloadTexture(food_texture);
    food_texture = undefined;
    food_position = undefined;
}

fn reset_food_position() void {
    food_position.x = @floatFromInt(rl.getRandomValue(0, cell_count - 1));
    food_position.y = @floatFromInt(rl.getRandomValue(0, cell_count - 1));

    for (snake_body.items) |body_part| {
        if (body_part.equals(food_position) == 1) {
            reset_food_position();
            break;
        }
    }
}

fn game_tick_passed(interval: f64) bool {
    const current_time = rl.getTime();
    if (current_time - last_update >= interval) {
        last_update = current_time;
        return true;
    }
    return false;
}

pub fn main() anyerror!void {
    std.debug.print("Starting the game...", .{});

    rl.initWindow(screen_width, screen_height, "Snake");
    defer rl.closeWindow();

    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    eat_sound = rl.loadSound("assets/eat.mp3");
    defer rl.unloadSound(eat_sound);

    wall_hit_sound = rl.loadSound("assets/wall.mp3");
    defer rl.unloadSound(wall_hit_sound);

    try init_snake();
    defer deinit_snake();

    try init_food();
    defer deinit_food();

    rl.setTargetFPS(60);

    var game_over = false;
    var tick_frequency: f32 = 0.2;

    while (!rl.windowShouldClose()) {
        if (!game_over) {
            if (game_tick_passed(tick_frequency)) {
                _ = snake_body.pop();
                try snake_body.insert(0, snake_body.items[0].add(snake_direction));

                for (snake_body.items, 0..) |body_part, index| {
                    if (index != 0 and body_part.equals(snake_body.items[0]) == 1) {
                        game_over = true;
                        break;
                    }
                }

                if (snake_body.items[0].x < 0 or snake_body.items[0].x >= cell_count or snake_body.items[0].y < 0 or snake_body.items[0].y >= cell_count) {
                    game_over = true;
                    rl.playSound(wall_hit_sound);
                }

                if (snake_body.items[0].equals(food_position) == 1) {
                    reset_food_position();
                    try snake_body.append(snake_body.items[0]);
                    score += 10;
                    rl.playSound(eat_sound);
                    tick_frequency -= 0.001;
                }
            }

            if ((rl.isKeyPressed(rl.KeyboardKey.key_right) or rl.isKeyPressed(rl.KeyboardKey.key_d)) and snake_direction.x != -1) {
                snake_direction = .{ .x = 1, .y = 0 };
            } else if ((rl.isKeyPressed(rl.KeyboardKey.key_left) or rl.isKeyPressed(rl.KeyboardKey.key_a)) and snake_direction.x != 1) {
                snake_direction = .{ .x = -1, .y = 0 };
            } else if ((rl.isKeyPressed(rl.KeyboardKey.key_up) or rl.isKeyPressed(rl.KeyboardKey.key_w)) and snake_direction.y != 1) {
                snake_direction = .{ .x = 0, .y = -1 };
            } else if ((rl.isKeyPressed(rl.KeyboardKey.key_down) or rl.isKeyPressed(rl.KeyboardKey.key_s)) and snake_direction.y != -1) {
                snake_direction = .{ .x = 0, .y = 1 };
            }
        } else {
            if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
                game_over = false;
                score = 0;
                try init_snake();
                reset_food_position();
            }
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(color_green);

        if (!game_over) {
            for (snake_body.items) |body_part| {
                const rect = rl.Rectangle{ .x = (body_part.x * cell_size) + screen_offset_x, .y = (body_part.y * cell_size) + screen_offset_y, .width = cell_size, .height = cell_size };
                rl.drawRectangleRounded(rect, 0.5, 6, color_dark_green);
            }

            const x = @as(i32, @intFromFloat(food_position.x)) * cell_size;
            const y = @as(i32, @intFromFloat(food_position.y)) * cell_size;
            rl.drawTexture(food_texture, x + screen_offset_x, y + screen_offset_y, rl.Color.white);

            rl.drawRectangleLines(screen_offset_x, screen_offset_y, play_width, play_height, rl.Color.black);
            rl.drawText(rl.textFormat("Score: %d", .{score}), 10, 10, 32, rl.Color.white);
        } else {
            const game_over_offset_x = @divFloor(rl.measureText("Game Over", 48), 2);
            rl.drawText("Game Over", screen_width / 2 - game_over_offset_x, 80, 48, rl.Color.red);

            const score_offset_x = @divFloor(rl.measureText(rl.textFormat("Score: %d", .{score}), 32), 2);
            rl.drawText(rl.textFormat("Score: %d", .{score}), screen_width / 2 - score_offset_x, 160, 32, rl.Color.yellow);

            const restart_offset_x = @divFloor(rl.measureText("Press R to restart", 32), 2);
            rl.drawText("Press R to restart", screen_width / 2 - restart_offset_x, 200, 32, rl.Color.yellow);
        }
    }
}
