const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const heap = std.heap;
const mem = std.mem;
const Target = std.Target;

pub fn build(b: *std.Build) !void {
    var target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const minimal = b.option(bool, "minimal", "Build libsodium with minimal features. (default: false)") orelse false;

    const currentPath = b.pathFromRoot(".");
    var currentDir = try fs.openDirAbsolute(currentPath, .{});
    defer currentDir.close();

    const sodiumPath = "src/libsodium";
    const sodiumDir = try fs.Dir.openDir(currentDir, sodiumPath, .{ .iterate = true, .no_follow = true });

    const sodiumSrcPath = "src/libsodium/src/libsodium";
    const sodiumSrcDir = try fs.Dir.openDir(currentDir, sodiumSrcPath, .{ .iterate = true, .no_follow = true });

    switch (target.result.cpu.arch) {
        .aarch64, .aarch64_be => {
            if (target.result.isMinGW()) {
                target.query.cpu_features_add.addFeature(@intFromEnum(Target.aarch64.Feature.neon));
            }
        },
        else => {},
    }

    const sodium = b.addSharedLibrary(.{
        .name = if (target.result.isMinGW()) "libsodium" else "sodium",
        .target = target,
        .optimize = optimize,
        .strip = optimize != .Debug and !target.result.isMinGW(),
    });

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const configurePath = "configure.ac";
    const configureFile = try sodiumDir.openFile(configurePath, .{});
    defer configureFile.close();
    const configureContents = try configureFile.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(configureContents);

    // Extract version from configure.ac
    std.debug.print("Extract version from configure.ac\n", .{});
    var version: []const u8 = undefined;
    var major: []const u8 = undefined;
    var minor: []const u8 = undefined;
    var it = mem.tokenizeAny(u8, configureContents, "\n");
    while (it.next()) |token| {
        if (mem.startsWith(u8, token, "AC_INIT")) {
            const size = mem.replacementSize(u8, token, "AC_INIT([libsodium],[", "])");
            const output = try allocator.alloc(u8, size);
            _ = mem.replace(u8, token, "AC_INIT([libsodium],[", "", output);
            var tmp = mem.splitAny(u8, output, "],[");
            version = tmp.first();
        } else if (mem.startsWith(u8, token, "SODIUM_LIBRARY_VERSION_MAJOR")) {
            const size = mem.replacementSize(u8, token, "SODIUM_LIBRARY_VERSION_MAJOR=", "");
            const output = try allocator.alloc(u8, size);
            _ = mem.replace(u8, token, "SODIUM_LIBRARY_VERSION_MAJOR=", "", output);
            major = output;
        } else if (mem.startsWith(u8, token, "SODIUM_LIBRARY_VERSION_MINOR")) {
            const size = mem.replacementSize(u8, token, "SODIUM_LIBRARY_VERSION_MINOR=", "");
            const output = try allocator.alloc(u8, size);
            _ = mem.replace(u8, token, "SODIUM_LIBRARY_VERSION_MINOR=", "", output);
            minor = output;
        }
    }
    std.debug.print("Start building libsodium {s} [{s}, {s}], Minimal Mode: {}\n", .{ version, major, minor, minimal });

    const versionTemplatePath = "include/sodium/version.h.in";
    const versionTemplateFile = try sodiumSrcDir.openFile(versionTemplatePath, .{});
    defer versionTemplateFile.close();
    const versionTemplateContents = try versionTemplateFile.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(versionTemplateContents);

    const arrReplaceKeys = [_][]const u8{ "@SODIUM_LIBRARY_VERSION_MAJOR@", "@SODIUM_LIBRARY_VERSION_MINOR@", "@VERSION@", "@SODIUM_LIBRARY_MINIMAL_DEF@" };
    const arrReplaceValues = [_][]const u8{ major, minor, version, if (minimal) "#define SODIUM_LIBRARY_MINIMAL 1" else "" };
    var versionFileContents = versionTemplateContents;
    for (0..arrReplaceKeys.len) |i| {
        const size = mem.replacementSize(u8, versionFileContents, arrReplaceKeys[i], arrReplaceValues[i]);
        const output = try allocator.alloc(u8, size);
        _ = mem.replace(u8, versionFileContents, arrReplaceKeys[i], arrReplaceValues[i], output);
        versionFileContents = output;
    }
    std.debug.print("Start creating new version.h\n", .{});
    const versionFilePath = "include/sodium/version.h";
    const versionFile = try sodiumSrcDir.createFile(versionFilePath, .{});
    defer versionFile.close();
    try versionFile.writeAll(versionFileContents);

    b.installArtifact(sodium);
    sodium.installHeader(b.path(sodiumSrcPath ++ "/include/sodium.h"), "sodium.h");
    sodium.installHeadersDirectory(b.path(sodiumSrcPath ++ "/include/sodium"), "sodium", .{});
    sodium.linkLibC();
    sodium.addIncludePath(b.path(sodiumSrcPath ++ "/include/sodium"));
    sodium.defineCMacro("_GNU_SOURCE", "1");
    sodium.defineCMacro("CONFIGURED", "1");
    sodium.defineCMacro("DEV_MODE", "1");
    sodium.defineCMacro("HAVE_ATOMIC_OPS", "1");
    sodium.defineCMacro("HAVE_C11_MEMORY_FENCES", "1");
    sodium.defineCMacro("HAVE_CET_H", "1");
    sodium.defineCMacro("HAVE_GCC_MEMORY_FENCES", "1");
    sodium.defineCMacro("HAVE_INLINE_ASM", "1");
    sodium.defineCMacro("HAVE_INTTYPES_H", "1");
    sodium.defineCMacro("HAVE_STDINT_H", "1");
    sodium.defineCMacro("HAVE_TI_MODE", "1");
    sodium.want_lto = false;

    const endian = target.result.cpu.arch.endian();
    switch (endian) {
        .big => sodium.defineCMacro("NATIVE_BIG_ENDIAN", "1"),
        .little => sodium.defineCMacro("NATIVE_LITTLE_ENDIAN", "1"),
    }
    switch (target.result.os.tag) {
        .linux => {
            sodium.defineCMacro("ASM_HIDE_SYMBOL", ".hidden");
            sodium.defineCMacro("TLS", "_Thread_local");
            sodium.defineCMacro("HAVE_CATCHABLE_ABRT", "1");
            sodium.defineCMacro("HAVE_CATCHABLE_SEGV", "1");
            sodium.defineCMacro("HAVE_CLOCK_GETTIME", "1");
            sodium.defineCMacro("HAVE_GETPID", "1");
            sodium.defineCMacro("HAVE_MADVISE", "1");
            sodium.defineCMacro("HAVE_MLOCK", "1");
            sodium.defineCMacro("HAVE_MMAP", "1");
            sodium.defineCMacro("HAVE_MPROTECT", "1");
            sodium.defineCMacro("HAVE_NANOSLEEP", "1");
            sodium.defineCMacro("HAVE_POSIX_MEMALIGN", "1");
            sodium.defineCMacro("HAVE_PTHREAD_PRIO_INHERIT", "1");
            sodium.defineCMacro("HAVE_PTHREAD", "1");
            sodium.defineCMacro("HAVE_RAISE", "1");
            sodium.defineCMacro("HAVE_SYSCONF", "1");
            sodium.defineCMacro("HAVE_SYS_AUXV_H", "1");
            sodium.defineCMacro("HAVE_SYS_MMAN_H", "1");
            sodium.defineCMacro("HAVE_SYS_PARAM_H", "1");
            sodium.defineCMacro("HAVE_SYS_RANDOM_H", "1");
            sodium.defineCMacro("HAVE_WEAK_SYMBOLS", "1");
        },
        .windows => {
            sodium.defineCMacro("HAVE_RAISE", "1");
            sodium.defineCMacro("HAVE_SYS_PARAM_H", "1");
            // sodium.defineCMacro("SODIUM_STATIC", "1");
        },
        .macos => {
            sodium.defineCMacro("ASM_HIDE_SYMBOL", ".private_extern");
            sodium.defineCMacro("TLS", "_Thread_local");
            sodium.defineCMacro("HAVE_ARC4RANDOM", "1");
            sodium.defineCMacro("HAVE_ARC4RANDOM_BUF", "1");
            sodium.defineCMacro("HAVE_CATCHABLE_ABRT", "1");
            sodium.defineCMacro("HAVE_CATCHABLE_SEGV", "1");
            sodium.defineCMacro("HAVE_CLOCK_GETTIME", "1");
            sodium.defineCMacro("HAVE_GETENTROPY", "1");
            sodium.defineCMacro("HAVE_GETPID", "1");
            sodium.defineCMacro("HAVE_MADVISE", "1");
            sodium.defineCMacro("HAVE_MEMSET_S", "1");
            sodium.defineCMacro("HAVE_MLOCK", "1");
            sodium.defineCMacro("HAVE_MMAP", "1");
            sodium.defineCMacro("HAVE_MPROTECT", "1");
            sodium.defineCMacro("HAVE_NANOSLEEP", "1");
            sodium.defineCMacro("HAVE_POSIX_MEMALIGN", "1");
            sodium.defineCMacro("HAVE_PTHREAD", "1");
            sodium.defineCMacro("HAVE_PTHREAD_PRIO_INHERIT", "1");
            sodium.defineCMacro("HAVE_RAISE", "1");
            sodium.defineCMacro("HAVE_SYSCONF", "1");
            sodium.defineCMacro("HAVE_SYS_MMAN_H", "1");
            sodium.defineCMacro("HAVE_SYS_PARAM_H", "1");
            sodium.defineCMacro("HAVE_SYS_RANDOM_H", "1");
            sodium.defineCMacro("HAVE_WEAK_SYMBOLS", "1");
        },
        else => {},
    }

    switch (target.result.cpu.arch) {
        .x86_64 => {
            switch (target.result.os.tag) {
                .windows => {},
                else => {
                    sodium.defineCMacro("HAVE_AMD64_ASM", "1");
                    sodium.defineCMacro("HAVE_AVX_ASM", "1");
                },
            }
            sodium.defineCMacro("HAVE_CPUID", "1");
            sodium.defineCMacro("HAVE_MMINTRIN_H", "1");
            sodium.defineCMacro("HAVE_EMMINTRIN_H", "1");
            sodium.defineCMacro("HAVE_PMMINTRIN_H", "1");
            sodium.defineCMacro("HAVE_TMMINTRIN_H", "1");
            sodium.defineCMacro("HAVE_SMMINTRIN_H", "1");
            sodium.defineCMacro("HAVE_AVXINTRIN_H", "1");
            sodium.defineCMacro("HAVE_AVX2INTRIN_H", "1");
            sodium.defineCMacro("HAVE_AVX512FINTRIN_H", "1");
            sodium.defineCMacro("HAVE_WMMINTRIN_H", "1");
            sodium.defineCMacro("HAVE_RDRAND", "1");
        },
        .aarch64, .aarch64_be => {
            sodium.defineCMacro("HAVE_ARMCRYPTO", "1");
        },
        else => {},
    }

    const flags = &.{
        "-fvisibility=hidden",
        "-fno-strict-aliasing",
        "-fno-strict-overflow",
        "-fwrapv",
        "-flax-vector-conversions",
        "-Werror=vla",
    };

    var walker = try sodiumSrcDir.walk(allocator);
    while (try walker.next()) |entry| {
        const name = entry.basename;
        if (mem.endsWith(u8, name, ".c")) {
            const cPath = try fmt.allocPrint(allocator, "{s}/{s}", .{ sodiumSrcPath, entry.path });
            sodium.addCSourceFiles(.{
                .files = &.{cPath},
                .flags = flags,
            });
        } else if (mem.endsWith(u8, name, ".S")) {
            const assemblyPath = try fmt.allocPrint(allocator, "{s}/{s}", .{ sodiumSrcPath, entry.path });
            sodium.addAssemblyFile(b.path(assemblyPath));
        }
    }
}
