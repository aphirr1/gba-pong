const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.

const emu_binary = "mgba-qt";
const emu_args = "";

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.

    const thumb_feature_set = std.Target.arm.featureSet(&.{.thumb_mode});

    var target = b.standardTargetOptions(.{ .default_target = .{
        .os_tag = .freestanding,
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm7tdmi },
    } });

    target.query.cpu_features_add.addFeatureSet(thumb_feature_set);
    target.result.cpu.features.addFeatureSet(thumb_feature_set);

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).

    const game_name = "gba-pong";

    const exe = b.addExecutable(.{
        .name = game_name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.setLinkerScript(b.path("gba.ld"));

    b.default_step.dependOn(&exe.step);

    const objcopy = exe.addObjCopy(.{ .format = .bin });
    objcopy.step.dependOn(&exe.step);

    const make_gba_file = b.addInstallBinFile(objcopy.getOutput(), game_name ++ ".gba");
    make_gba_file.step.dependOn(&objcopy.step);

    // TODO: run mGba when doing 'zig build run'
    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const emu_cmd = b.addSystemCommand(&.{emu_binary});

    if (b.args) |args| {
        emu_cmd.addArgs(args);
    }
    emu_cmd.addFileArg(objcopy.getOutput());

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    b.default_step.dependOn(&make_gba_file.step);
    run_step.dependOn(&emu_cmd.step);
}
