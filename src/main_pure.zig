const rl = @import("c.zig").raylib;
const std = @import("std");
const cnn = @import("cnn.zig");
const mnist = @import("c.zig").mnist;


pub fn whatIsIt(image: *mnist.Image) u8 {
    var activations: [10]f32 = undefined;
    var predict: u8 = 0;
    network.hypothesis(image, &activations);
    var j: usize = 0;
    var max_activation = activations[0];
    while (j < 10) : (j += 1) {
        if (max_activation < activations[j]) {
            max_activation = activations[j];
            predict = @intCast(u8, j);
        }
    }
    return predict;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var network = try cnn.NeuralNetwork.initFromFile("trained.network");

    rl.InitWindow(400, 400, "VN");
    rl.SetWindowState(rl.FLAG_WINDOW_RESIZABLE);
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    var predicted: u8 = 0;

    var target = rl.LoadRenderTexture(400, 400);
    defer rl.UnloadRenderTexture(target);

    rl.BeginTextureMode(target);
    rl.ClearBackground(rl.WHITE);
    rl.EndTextureMode();

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        var mousePos = rl.GetMousePosition();

        if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT) or rl.GetGestureDetected() == rl.GESTURE_DRAG) {
            rl.BeginTextureMode(target);
            defer rl.EndTextureMode();
            rl.DrawCircle(@floatToInt(c_int, mousePos.x), @floatToInt(c_int, mousePos.y), 20, rl.BLACK);
        }
        if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_RIGHT)) {
            rl.BeginTextureMode(target);
            rl.ClearBackground(rl.WHITE);
            rl.EndTextureMode();
        }

        if (rl.IsKeyPressed(rl.KEY_ENTER)) {
            var img = rl.LoadImageFromTexture(target.texture);
            defer rl.UnloadImage(img);
            rl.ImageFlipVertical(&img);
            rl.ImageResize(&img, 28, 28);
            rl.ImageColorGrayscale(&img);
            rl.ImageColorInvert(&img);
            var pixels = @ptrCast([*c]u8, img.data)[0..28*28];
            predicted = whatIsIt(&network, pixels);
        }

        rl.ClearBackground(rl.RAYWHITE);
        rl.DrawTextureRec(target.texture, .{ .x = 0, .y = 0, .width = @intToFloat(f32, target.texture.width), .height = @intToFloat(f32, -target.texture.height) }, .{ .x = 0, .y = 0 }, rl.WHITE);
        rl.DrawText(rl.TextFormat("predicted = %d", predicted), 20, 20, 20, rl.BLACK);
    }
}
