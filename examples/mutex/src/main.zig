const std = @import("std");
const builtin = @import("builtin");
const tracy = @import("tracy");
const windows = std.os.windows;
const io = std.Options.debug_io;

var finalise_threads: std.Io.Event = .unset;
const worker_count = 6;

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

    var shared = SharedState.init();
    defer shared.deinit();

    var threads: [worker_count]std.Thread = undefined;
    var started: usize = 0;
    errdefer {
        finalise_threads.set(io);
        for (threads[0..started]) |thread| thread.join();
    }

    for (&threads, 0..) |*thread, idx| {
        thread.* = try std.Thread.spawn(.{}, worker, .{ &finalise_threads, &shared, idx });
        started += 1;
    }

    finalise_threads.wait(io) catch {};

    for (threads[0..started]) |thread| thread.join();
}

const SharedState = struct {
    mutex: tracy.TracingMutex,
    counter: u64 = 0,

    fn init() SharedState {
        return .{
            .mutex = tracy.TracingMutex.init(@src(), .{
                .name = "Traced mutex",
                .color = 0xFF8844,
            }),
        };
    }

    fn deinit(self: *SharedState) void {
        self.mutex.deinit();
    }

    fn blockingIncrement(self: *SharedState) u64 {
        const zone = tracy.initZone(@src(), .{ .name = "Mutex critical section" });
        defer zone.deinit();

        self.mutex.lock(@src());
        defer self.mutex.unlock();

        self.counter += 1;
        zone.value(self.counter);
        // Hold the lock briefly to force contention to show up in Tracy.
        std.Io.sleep(io, .fromMilliseconds(50), .awake) catch {};
        return self.counter;
    }
};

fn worker(finalise: *std.Io.Event, shared: *SharedState, idx: usize) void {
    tracy.setThreadName("Mutex worker");

    while (!finalise.isSet()) {
        _ = shared.blockingIncrement();

        const pause_ns: u64 = (@as(u64, @intCast(idx)) + 1) * 200 * std.time.ns_per_ms;
        std.Io.sleep(io, .fromNanoseconds(@intCast(pause_ns)), .awake) catch {};
    }
}
