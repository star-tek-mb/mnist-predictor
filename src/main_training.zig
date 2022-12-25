const std = @import("std");
const mnist = @import("mnist.zig");
const cnn = @import("cnn.zig");

pub fn makeBatch(dataset: *mnist.Dataset, size: usize, number: usize) !mnist.Dataset {
    var batch: mnist.Dataset = undefined;
    var start = size * number;
    if (start > dataset.images.len) {
        return error.IndexOutOfBounds;
    }
    batch.images = dataset.images[start..];
    batch.labels = dataset.labels[start..];
    return batch;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var dataset = try mnist.Dataset.init(gpa.allocator(), "data/train-images-idx3-ubyte", "data/train-labels-idx1-ubyte");
    defer dataset.deinit(gpa.allocator());

    var network = cnn.NeuralNetwork.initWithRandomWeights();
    var begin = std.time.milliTimestamp();
    var i : usize = 0;
    while (i < 1000) : (i += 1) {
        var batch = try makeBatch(&dataset, 100, i % 100);
        _ = network.trainingStep(&batch, 0.5);
    }
    try network.saveToFile("trained.network");

    var end = std.time.milliTimestamp();
    try std.io.getStdOut().writer().print("training took {d}ms\n", .{ end - begin });
}
