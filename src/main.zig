const std = @import("std");
const testing = std.testing;

/// Caller must free memory.
pub fn askString(allocator: *std.mem.Allocator, prompt: []const u8, max_size: usize) ![]u8 {
    const in = std.io.getStdIn().inStream();
    const out = std.io.getStdOut().outStream();

    _ = try out.write(prompt);
    _ = try out.write(" ");

    const result = try in.readUntilDelimiterAlloc(allocator, '\n', max_size);
    return if (std.mem.endsWith(u8, result, "\r")) result[0..(result.len - 1)] else result;
}

/// Caller must free memory. Max size is recommended to be a high value, like 512.
pub fn askDirPath(allocator: *std.mem.Allocator, prompt: []const u8, max_size: usize) ![]u8 {
    const out = std.io.getStdOut().outStream();

    while (true) {
        const path = try askString(allocator, prompt, max_size);
        if (!std.fs.path.isAbsolute(path)) {
            _ = try out.write("Error: Invalid directory, please try again.\n\n");
            allocator.free(path);
            continue;
        }
        
        var dir = std.fs.cwd().openDir(path, std.fs.Dir.OpenDirOptions{}) catch {
            _ = try out.write("Error: Invalid directory, please try again.\n\n");
            allocator.free(path);
            continue;
        };

        dir.close();
        return path;
    }
}

pub fn askBool(prompt: []const u8) !bool {
    const in = std.io.getStdIn().inStream();
    const out = std.io.getStdOut().outStream();

    var buffer: [1]u8 = undefined;

    while (true) {
        _ = try out.write(prompt);
        _ = try out.write(" (y/n) ");

        const read = in.read(&buffer) catch continue;
        try in.skipUntilDelimiterOrEof('\n');

        if (read == 0) return error.EndOFStream;

        switch (buffer[0]) {
            'y' => return true,
            'n' => return false,
            else => continue
        }
    }
}

test "basic input functionality" {
    std.debug.warn("\n\n", .{});

    std.debug.warn("Welcome to the ZLS configuration wizard! (insert mage emoji here)\n", .{});

    const stdp = try askDirPath(testing.allocator, "What is your Zig lib path (path that contains the 'std' folder)?", 128);
    const snippet = try askBool("Do you want to enable snippets?");
    const style = try askBool("Do you want to enable style warnings?");

    defer testing.allocator.free(stdp);

    // std.debug.warn("{} {} {}", .{stdp, snippet, style});

    std.debug.warn("\n\n", .{});
}
