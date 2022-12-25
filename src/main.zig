const rl = @import("c.zig").raylib;
const std = @import("std");
const cnn = @import("cnn.zig");
const mnist = @import("c.zig").mnist;

pub fn predict(image: *[28 * 28]u8) u8 {
    var prediction: u8 = 0;
    var image_matrix: [28 * 28]f32 = undefined;
    for (image) |pixel, i| {
        image_matrix[i] = (@intToFloat(f32, pixel) / 255.0);
    }
    var image_tensor = mnist.k2c_tensor{
        .array = &image_matrix[0],
        .ndim = 2,
        .numel = 28 * 28,
        .shape = [5]usize{ 28, 28, 1, 1, 1 },
    };
    var dense_matrix: [10]f32 = .{ 0.0 } ** 10;
    var dense_tensor = mnist.k2c_tensor{
        .array = &dense_matrix[0],
        .ndim = 1,
        .numel = 10,
        .shape = [5]usize{ 10, 1, 1, 1, 1 },
    };
    mnist.mnist(&image_tensor, &dense_tensor);
    var max = dense_matrix[0];
    for (dense_matrix) |val, i| {
        if (val > max) {
            max = val;
            prediction = @intCast(u8, i);
        }
    }
    return prediction;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    rl.InitWindow(400, 400, "MNIST");
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

        if (rl.IsMouseButtonReleased(rl.MOUSE_BUTTON_LEFT)) {
            var img = rl.LoadImageFromTexture(target.texture);
            defer rl.UnloadImage(img);
            rl.ImageFlipVertical(&img);
            rl.ImageColorGrayscale(&img);
            rl.ImageColorInvert(&img);
            rl.ImageResize(&img, 28, 28);
            var pixels = @ptrCast([*c]u8, img.data)[0 .. 28 * 28];
            predicted = predict(pixels);
        }

        rl.ClearBackground(rl.RAYWHITE);
        rl.DrawTextureRec(target.texture, .{ .x = 0, .y = 0, .width = @intToFloat(f32, target.texture.width), .height = @intToFloat(f32, -target.texture.height) }, .{ .x = 0, .y = 0 }, rl.WHITE);
        rl.DrawText(rl.TextFormat("predicted = %d", predicted), 20, 20, 20, rl.BLACK);
    }
}
