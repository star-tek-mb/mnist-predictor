const std = @import("std");
const mnist = @import("mnist.zig");

pub const NeuralNetworkGradient = extern struct {
    bias_gradients: [10]f32,
    weight_gradients: [10][28 * 28]f32,
};

pub const NeuralNetwork = extern struct {
    biases: [10]f32,
    weights: [10][28 * 28]f32,

    pub fn initFromFile(path: []const u8) !NeuralNetwork {
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        return try file.reader().readStruct(NeuralNetwork);
    }

    pub fn initWithRandomWeights() NeuralNetwork {
        var randomizer = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
        var result: NeuralNetwork = undefined;
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            result.biases[i] = randomizer.random().float(f32);
            var j: usize = 0;
            while (j < 28 * 28) : (j += 1) {
                result.weights[i][j] = randomizer.random().float(f32);
            }
        }
        return result;
    }

    pub fn softmax(activations: []f32) void {
        var max: f32 = activations[0];
        var i: usize = 1;
        while (i < activations.len) : (i += 1) {
            if (activations[i] > max) {
                max = activations[i];
            }
        }

        var sum: f32 = 0.0;
        i = 0;
        while (i < activations.len) : (i += 1) {
            activations[i] = std.math.exp(activations[i] - max);
            sum += activations[i];
        }

        i = 0;
        while (i < activations.len) : (i += 1) {
            activations[i] /= sum;
        }
    }

    pub fn hypothesis(self: *NeuralNetwork, image: *mnist.Image, activations: []f32) void {
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            activations[i] = self.biases[i];
            var j: usize = 0;
            while (j < 28 * 28) : (j += 1) {
                activations[i] += self.weights[i][j] * (@intToFloat(f32, image[j]) / 255.0);
            }
        }
        NeuralNetwork.softmax(activations);
    }

    pub fn gradientUpdate(self: *NeuralNetwork, image: *mnist.Image, gradient: *NeuralNetworkGradient, label: u8) f32 {
        var activations: [10]f32 = undefined;
        var bias_gradient: f32 = 0.0;
        var weight_gradient: f32 = 0.0;

        self.hypothesis(image, &activations);

        var i: usize = 0;
        while (i < 10) : (i += 1) {
            bias_gradient = if (i == label) activations[i] - 1.0 else activations[i];
            var j: usize = 0;
            while (j < 28 * 28) : (j += 1) {
                weight_gradient = bias_gradient * (@intToFloat(f32, image[j]) / 255.0);
                gradient.weight_gradients[i][j] += weight_gradient;
            }
            gradient.bias_gradients[i] += bias_gradient;
        }
        return 0.0 - std.math.log(f32, std.math.e, activations[label]);
    }

    pub fn trainingStep(self: *NeuralNetwork, dataset: *mnist.Dataset, rate: f32) f32 {
        var gradient = std.mem.zeroes(NeuralNetworkGradient);
        var totalLoss: f32 = 0.0;
        var i: usize = 0;
        while (i < dataset.images.len) : (i += 1) {
            totalLoss += self.gradientUpdate(&dataset.images[i], &gradient, dataset.labels[i]);
        }
        i = 0;
        while (i < 10) : (i += 1) {
            self.biases[i] -= rate * gradient.bias_gradients[i] / @intToFloat(f32, dataset.images.len);
            var j: usize = 0;
            while (j < 28 * 28) : (j += 1) {
                self.weights[i][j] -= rate * gradient.weight_gradients[i][j] / @intToFloat(f32, dataset.images.len);
            }
        }
        return totalLoss;
    }

    pub fn saveToFile(self: *NeuralNetwork, path: []const u8) !void {
        var file = try std.fs.cwd().createFile(path, .{});
        defer file.close();
        try file.writer().writeStruct(self.*);
    }
};
