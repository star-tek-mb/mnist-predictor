const std = @import("std");
const raylib = @import("raylib/src/build.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86_64,
            .os_tag = .windows,
            .abi = .gnu,
        },
    });
    const mode = b.standardReleaseOptions();

    const rl = raylib.addRaylib(b, target);
    rl.setBuildMode(mode);

    const exe = b.addExecutable("rayzig", "src/main.zig");
    exe.addCSourceFiles(&.{
        "src/mnist/mnist.c",
        "src/mnist/include/k2c_activations.c",
        "src/mnist/include/k2c_convolution_layers.c",
        "src/mnist/include/k2c_core_layers.c",
        "src/mnist/include/k2c_embedding_layers.c",
        "src/mnist/include/k2c_helper_functions.c",
        "src/mnist/include/k2c_merge_layers.c",
        "src/mnist/include/k2c_normalization_layers.c",
        "src/mnist/include/k2c_pooling_layers.c",
        "src/mnist/include/k2c_recurrent_layers.c",
    }, &.{"-std=c99"});
    exe.addIncludePath("src/mnist");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addIncludePath("raylib/src");
    exe.linkLibrary(rl);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
