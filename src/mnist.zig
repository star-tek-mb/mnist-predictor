const std = @import("std");

pub const Image = [28 * 28]u8;

pub const Dataset = struct {
    images: []Image,
    labels: []const u8,

    pub fn init(allocator: std.mem.Allocator, image_path: []const u8, label_path: []const u8) !Dataset {
        var image_file = try std.fs.cwd().openFile(image_path, .{});
        defer image_file.close();
        var image_reader = std.io.bufferedReader(image_file.reader());
        var images = try Dataset.readImages(allocator, image_reader.reader());
        errdefer allocator.free(images);

        var label_file = try std.fs.cwd().openFile(label_path, .{});
        defer label_file.close();
        var label_reader = std.io.bufferedReader(label_file.reader());
        var labels = try Dataset.readLabels(allocator, label_reader.reader());
        errdefer allocator.free(labels);

        if (labels.len != images.len) {
            return error.DataMismatch;
        }

        return Dataset{ .images = images, .labels = labels };
    }

    pub fn readImages(allocator: std.mem.Allocator, reader: anytype) ![]Image {
        var magic = try reader.readIntBig(u32);
        if (magic != 0x00000803) {
            return error.BadMagic;
        }
        var count = try reader.readIntBig(u32);
        _ = try reader.readIntBig(u32);
        _ = try reader.readIntBig(u32);
        var images = try allocator.alloc(Image, count);
        for (images) |*image| {
            _ = try reader.readAll(image);
        }
        return images;
    }

    pub fn readLabels(allocator: std.mem.Allocator, reader: anytype) ![]const u8 {
        var magic = try reader.readIntBig(u32);
        if (magic != 0x00000801) {
            return error.BadMagic;
        }
        var count = try reader.readIntBig(u32);
        return try reader.readAllAlloc(allocator, count);
    }

    pub fn deinit(self: *Dataset, allocator: std.mem.Allocator) void {
        allocator.free(self.images);
        allocator.free(self.labels);
    }
};
