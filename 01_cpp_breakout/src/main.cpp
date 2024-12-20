#include <raylib.h>

#include <iostream>
#include <vector>

constexpr float scale = 2.0f;
constexpr int screenWidth = 500 * scale;
constexpr int screenHeight = 600 * scale;
constexpr int targetFPS = 60;

struct Player {
    Rectangle rect{};
    float velocity = 250.0f;
    int score = 0;
    float width = 75.0f;
    float height = 10.0f;
};

struct Ball {
    Vector2 position{};
    Vector2 acceleration{1.0f, 1.0f};
    float velocity;
    float radius = 5.0f;
};

struct Brick {
    Rectangle rect{};
    Color color = WHITE;
    float width = 50.0f;
    float height = 20.0f;
};

Texture2D background;
Player player;
Ball ball;
std::vector<Brick> bricks;
Sound brickHitSound[2];
Sound playerHitSound;

void GameStartup() {
    Image backgroundImage = LoadImage("assets/background.png");
    background = LoadTextureFromImage(backgroundImage);
    UnloadImage(backgroundImage);

    brickHitSound[0] = LoadSound("assets/brick-hit-1.wav");
    brickHitSound[1] = LoadSound("assets/brick-hit-2.wav");
    playerHitSound = LoadSound("assets/paddle-hit-1.wav");

    player.rect = {250.0f * scale, 540.0f * scale, player.width * scale, player.height * scale};
    player.score = 0;

    ball.position = {300.0f * scale, 300.0f * scale};
    ball.velocity = 300.0f;

    static const std::vector<Color> colors = {RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE, VIOLET};

    bricks.clear();
    Brick brick;
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            brick.rect = {
                (float)(i * ((brick.width + 5) * scale) + 60), (float)(j * ((brick.height + 5) * scale) + 100),
                brick.width * scale, brick.height * scale
            };
            brick.color = colors[GetRandomValue(0, colors.size() - 1)];
            bricks.push_back(brick);
        }
    }
}

void GameUpdate() {
    float frameTime = GetFrameTime();
    if (IsKeyDown(KEY_A) || IsKeyDown(KEY_LEFT)) {
        player.rect.x -= player.velocity * frameTime;
    }
    if (IsKeyDown(KEY_D) || IsKeyDown(KEY_RIGHT)) {
        player.rect.x += player.velocity * frameTime;
    }

    ball.position.x += ball.acceleration.x * ball.velocity * frameTime;
    ball.position.y += ball.acceleration.y * ball.velocity * frameTime;

    if (player.rect.x < 0) {
        player.rect.x = 0;
    }
    if (player.rect.x + player.rect.width > screenWidth) {
        player.rect.x = screenWidth - player.rect.width;
    }

    if (ball.position.x < 0 || ball.position.x > screenWidth) {
        ball.acceleration.x *= -1;
    }
    if (ball.position.y < 0 || ball.position.y > screenHeight) {
        ball.acceleration.y *= -1;
    }

    if (CheckCollisionCircleRec(ball.position, ball.radius, player.rect)) {
        ball.acceleration.y *= -1;
        ball.position.y = player.rect.y - ball.radius;
        PlaySound(playerHitSound);
    }

    for (auto it = bricks.begin(); it != bricks.end();) {
        if (CheckCollisionCircleRec(ball.position, ball.radius, it->rect)) {
            it->color = GREEN;
            it = bricks.erase(it);
            player.score += 10;
            ball.acceleration.y *= -1;
            PlaySound(brickHitSound[GetRandomValue(0, 1)]);
            break;
        } else {
            ++it;
        }
    }
}

void GameRender() {
    DrawTextureEx(background, {0, 0}, 0.0f, scale, RAYWHITE);

    DrawRectangleRec(player.rect, YELLOW);
    DrawCircle(ball.position.x, ball.position.y, ball.radius * scale, WHITE);

    for (const auto& brick : bricks) {
        DrawRectangleRec(brick.rect, brick.color);
    }

    DrawText(TextFormat("Score: %d", player.score), 10, 10, 32, WHITE);
    DrawText(TextFormat("FPS: %d", GetFPS()), 300, 10, 32, WHITE);
}

void GameShutdown() {
    UnloadSound(brickHitSound[0]);
    UnloadSound(brickHitSound[1]);
    UnloadSound(playerHitSound);

    UnloadTexture(background);

    CloseAudioDevice();
}

int main() {
    std::cout << "Hello, World!\n";
    SetRandomSeed(time(nullptr));

    InitWindow(screenWidth, screenHeight, "Breakout");
    InitAudioDevice();
    SetTargetFPS(targetFPS);

    GameStartup();

    while (!WindowShouldClose()) {
        GameUpdate();

        BeginDrawing();
        ClearBackground(BLUE);

        GameRender();
        EndDrawing();
    }

    GameShutdown();
    CloseWindow();
    return 0;
}
