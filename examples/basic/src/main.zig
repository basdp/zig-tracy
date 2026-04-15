const std = @import("std");
const builtin = @import("builtin");
const tracy = @import("tracy");
const windows = std.os.windows;
const io = std.Options.debug_io;

var finalise_threads: std.Io.Event = .unset;

fn handleSigInt(_: std.posix.SIG) callconv(.c) void {
    finalise_threads.set(io);
}

fn handleCtrlEvent(_: windows.DWORD) callconv(windows.WINAPI) windows.BOOL {
    finalise_threads.set(io);
    return windows.TRUE;
}

pub fn main() !void {
    tracy.setThreadName("Main");
    defer tracy.message("Graceful main thread exit");

    if (builtin.os.tag == .windows) {
        _ = windows.kernel32.SetConsoleCtrlHandler(handleCtrlEvent, windows.TRUE);
    } else {
        std.posix.sigaction(std.posix.SIG.INT, &.{
            .handler = .{ .handler = handleSigInt },
            .mask = std.posix.sigemptyset(),
            .flags = 0,
        }, null);
    }

    const other_thread = try std.Thread.spawn(.{}, otherThread, .{});
    defer other_thread.join();

    while (!finalise_threads.isSet()) {
        tracy.frameMark();

        const zone = tracy.initZone(@src(), .{ .name = "Important work" });
        defer zone.deinit();
        std.Io.sleep(io, .fromNanoseconds(100), .awake) catch {};
    }
}

fn otherThread() void {
    tracy.setThreadName("Other");
    defer tracy.message("Graceful other thread exit");

    var os_allocator = tracy.TracingAllocator.init(std.heap.page_allocator);

    var arena = std.heap.ArenaAllocator.init(os_allocator.allocator());
    defer arena.deinit();

    var tracing_allocator = tracy.TracingAllocator.initNamed("arena", arena.allocator());
    var stdin_buffer: [4096]u8 = undefined;
    var stdin = std.Io.File.stdin().reader(io, &stdin_buffer);
    var stdout_buffer: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(io, &stdout_buffer);

    while (!finalise_threads.isSet()) {
        const zone = tracy.initZone(@src(), .{ .name = "IO loop" });
        defer zone.deinit();

        stdout.interface.print("Enter string: ", .{}) catch break;
        stdout.interface.flush() catch break;

        var line = std.Io.Writer.Allocating.init(tracing_allocator.allocator());
        defer line.deinit();

        const stream_zone = tracy.initZone(@src(), .{ .name = "Writer.streamUntilDelimiter" });
        _ = stdin.interface.streamDelimiter(&line.writer, '\n') catch break;
        stream_zone.deinit();

        const toowned_zone = tracy.initZone(@src(), .{ .name = "ArrayList.toOwnedSlice" });
        const str = line.toOwnedSlice() catch break;
        defer tracing_allocator.allocator().free(str);
        toowned_zone.deinit();

        const reverse_zone = tracy.initZone(@src(), .{ .name = "std.mem.reverse" });
        std.mem.reverse(u8, str);
        reverse_zone.deinit();

        stdout.interface.print("Reversed: {s}\n", .{str}) catch break;
        stdout.interface.flush() catch break;
    }
}
