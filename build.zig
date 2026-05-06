const std = @import("std");
const digits2 = std.fmt.digits2;

const TracyConfig = struct {
    enable: bool,
    on_demand: bool,
    callstack: ?u8,
    no_callstack: bool,
    no_callstack_inlines: bool,
    only_localhost: bool,
    no_broadcast: bool,
    only_ipv4: bool,
    no_code_transfer: bool,
    no_context_switch: bool,
    no_exit: bool,
    no_sampling: bool,
    no_verify: bool,
    no_vsync_capture: bool,
    no_frame_image: bool,
    no_system_tracing: bool,
    delayed_init: bool,
    manual_lifetime: bool,
    fibers: bool,
    no_crash_handler: bool,
    timer_fallback: bool,
    rpmalloc_dynamic_tls: bool,
    shared: bool,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tracy_enable = b.option(bool, "tracy_enable", "Enable profiling") orelse true;
    const tracy_on_demand = b.option(bool, "tracy_on_demand", "On-demand profiling") orelse false;
    const tracy_callstack: ?u8 = b.option(u8, "tracy_callstack", "Enforce callstack collection for tracy regions");
    const tracy_no_callstack = b.option(bool, "tracy_no_callstack", "Disable all callstack related functionality") orelse false;
    const tracy_no_callstack_inlines = b.option(bool, "tracy_no_callstack_inlines", "Disables the inline functions in callstacks") orelse false;
    const tracy_only_localhost = b.option(bool, "tracy_only_localhost", "Only listen on the localhost interface") orelse false;
    const tracy_no_broadcast = b.option(bool, "tracy_no_broadcast", "Disable client discovery by broadcast to local network") orelse false;
    const tracy_only_ipv4 = b.option(bool, "tracy_only_ipv4", "Tracy will only accept connections on IPv4 addresses (disable IPv6)") orelse false;
    const tracy_no_code_transfer = b.option(bool, "tracy_no_code_transfer", "Disable collection of source code") orelse false;
    const tracy_no_context_switch = b.option(bool, "tracy_no_context_switch", "Disable capture of context switches") orelse false;
    const tracy_no_exit = b.option(bool, "tracy_no_exit", "Client executable does not exit until all profile data is sent to server") orelse false;
    const tracy_no_sampling = b.option(bool, "tracy_no_sampling", "Disable call stack sampling") orelse false;
    const tracy_no_verify = b.option(bool, "tracy_no_verify", "Disable zone validation for C API") orelse false;
    const tracy_no_vsync_capture = b.option(bool, "tracy_no_vsync_capture", "Disable capture of hardware Vsync events") orelse false;
    const tracy_no_frame_image = b.option(bool, "tracy_no_frame_image", "Disable the frame image support and its thread") orelse false;
    // NOTE For some reason system tracing on zig projects crashes tracy, will need to investigate
    const tracy_no_system_tracing = b.option(bool, "tracy_no_system_tracing", "Disable systrace sampling") orelse true;
    const tracy_delayed_init = b.option(bool, "tracy_delayed_init", "Enable delayed initialization of the library (init on first call)") orelse false;
    const tracy_manual_lifetime = b.option(bool, "tracy_manual_lifetime", "Enable the manual lifetime management of the profile") orelse false;
    const tracy_fibers = b.option(bool, "tracy_fibers", "Enable fibers support") orelse false;
    const tracy_no_crash_handler = b.option(bool, "tracy_no_crash_handler", "Disable crash handling") orelse false;
    const tracy_timer_fallback = b.option(bool, "tracy_timer_fallback", "Use lower resolution timers") orelse false;
    const tracy_rpmalloc_dynamic_tls = b.option(bool, "tracy_rpmalloc_dynamic_tls", "Avoid rpmalloc initial-exec TLS for dlopen-loaded Linux plugins") orelse false;
    const shared = b.option(bool, "shared", "Build the tracy client as a shared libary") orelse false;
    const tracy_config: TracyConfig = .{
        .enable = tracy_enable,
        .on_demand = tracy_on_demand,
        .callstack = tracy_callstack,
        .no_callstack = tracy_no_callstack,
        .no_callstack_inlines = tracy_no_callstack_inlines,
        .only_localhost = tracy_only_localhost,
        .no_broadcast = tracy_no_broadcast,
        .only_ipv4 = tracy_only_ipv4,
        .no_code_transfer = tracy_no_code_transfer,
        .no_context_switch = tracy_no_context_switch,
        .no_exit = tracy_no_exit,
        .no_sampling = tracy_no_sampling,
        .no_verify = tracy_no_verify,
        .no_vsync_capture = tracy_no_vsync_capture,
        .no_frame_image = tracy_no_frame_image,
        .no_system_tracing = tracy_no_system_tracing,
        .delayed_init = tracy_delayed_init,
        .manual_lifetime = tracy_manual_lifetime,
        .fibers = tracy_fibers,
        .no_crash_handler = tracy_no_crash_handler,
        .timer_fallback = tracy_timer_fallback,
        .rpmalloc_dynamic_tls = tracy_rpmalloc_dynamic_tls,
        .shared = shared,
    };

    const options = b.addOptions();
    options.addOption(bool, "tracy_enable", tracy_enable);
    options.addOption(bool, "tracy_on_demand", tracy_on_demand);
    options.addOption(?u8, "tracy_callstack", tracy_callstack);
    options.addOption(bool, "tracy_no_callstack", tracy_no_callstack);
    options.addOption(bool, "tracy_no_callstack_inlines", tracy_no_callstack_inlines);
    options.addOption(bool, "tracy_only_localhost", tracy_only_localhost);
    options.addOption(bool, "tracy_no_broadcast", tracy_no_broadcast);
    options.addOption(bool, "tracy_only_ipv4", tracy_only_ipv4);
    options.addOption(bool, "tracy_no_code_transfer", tracy_no_code_transfer);
    options.addOption(bool, "tracy_no_context_switch", tracy_no_context_switch);
    options.addOption(bool, "tracy_no_exit", tracy_no_exit);
    options.addOption(bool, "tracy_no_sampling", tracy_no_sampling);
    options.addOption(bool, "tracy_no_verify", tracy_no_verify);
    options.addOption(bool, "tracy_no_vsync_capture", tracy_no_vsync_capture);
    options.addOption(bool, "tracy_no_frame_image", tracy_no_frame_image);
    options.addOption(bool, "tracy_no_system_tracing", tracy_no_system_tracing);
    options.addOption(bool, "tracy_delayed_init", tracy_delayed_init);
    options.addOption(bool, "tracy_manual_lifetime", tracy_manual_lifetime);
    options.addOption(bool, "tracy_fibers", tracy_fibers);
    options.addOption(bool, "tracy_no_crash_handler", tracy_no_crash_handler);
    options.addOption(bool, "tracy_timer_fallback", tracy_timer_fallback);
    options.addOption(bool, "tracy_rpmalloc_dynamic_tls", tracy_rpmalloc_dynamic_tls);
    options.addOption(bool, "shared", shared);

    const tracy_src = b.dependency("tracy_src", .{});
    const tracy_c = b.addTranslateC(.{
        .root_source_file = b.path("src/tracy_c.h"),
        .target = target,
        .optimize = optimize,
    });
    tracy_c.addIncludePath(tracy_src.path("./public"));
    addTracyImportMacros(tracy_c, target, tracy_config);

    const tracy_module = b.addModule("tracy", .{
        .root_source_file = b.path("src/tracy.zig"),
        .target = target,
        .optimize = optimize,
    });

    tracy_module.addImport("tracy-options", options.createModule());
    tracy_module.addImport("tracy-c", tracy_c.createModule());

    const tracy_client = b.addLibrary(.{
        .linkage = if (shared) .dynamic else .static,
        .name = "tracy",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = target.result.abi == .msvc,
            .link_libcpp = target.result.abi != .msvc,
        }),
    });

    if (target.result.os.tag == .windows) {
        tracy_client.root_module.linkSystemLibrary("dbghelp", .{});
        tracy_client.root_module.linkSystemLibrary("ws2_32", .{});
    }
    tracy_client.root_module.addIncludePath(tracy_src.path("./public"));
    tracy_client.root_module.addCSourceFile(.{
        .file = tracy_src.path("./public/TracyClient.cpp"),
        .flags = if (target.result.os.tag == .windows) &.{"-fms-extensions"} else &.{},
    });
    inline for (tracy_header_files) |header| {
        tracy_client.installHeader(
            tracy_src.path("public/" ++ header),
            header,
        );
    }
    addTracyClientMacros(tracy_client.root_module, target, tracy_config);
    b.installArtifact(tracy_client);
}

fn addTracyClientMacros(module: *std.Build.Module, target: std.Build.ResolvedTarget, config: TracyConfig) void {
    if (config.enable)
        module.addCMacro("TRACY_ENABLE", "1");
    if (config.on_demand)
        module.addCMacro("TRACY_ON_DEMAND", "1");
    if (config.callstack) |depth| {
        module.addCMacro("TRACY_CALLSTACK", "\"" ++ digits2(depth) ++ "\"");
    }
    if (config.no_callstack)
        module.addCMacro("TRACY_NO_CALLSTACK", "1");
    if (config.no_callstack_inlines)
        module.addCMacro("TRACY_NO_CALLSTACK_INLINES", "1");
    if (config.only_localhost)
        module.addCMacro("TRACY_ONLY_LOCALHOST", "1");
    if (config.no_broadcast)
        module.addCMacro("TRACY_NO_BROADCAST", "1");
    if (config.only_ipv4)
        module.addCMacro("TRACY_ONLY_IPV4", "1");
    if (config.no_code_transfer)
        module.addCMacro("TRACY_NO_CODE_TRANSFER", "1");
    if (config.no_context_switch)
        module.addCMacro("TRACY_NO_CONTEXT_SWITCH", "1");
    if (config.no_exit)
        module.addCMacro("TRACY_NO_EXIT", "1");
    if (config.no_sampling)
        module.addCMacro("TRACY_NO_SAMPLING", "1");
    if (config.no_verify)
        module.addCMacro("TRACY_NO_VERIFY", "1");
    if (config.no_vsync_capture)
        module.addCMacro("TRACY_NO_VSYNC_CAPTURE", "1");
    if (config.no_frame_image)
        module.addCMacro("TRACY_NO_FRAME_IMAGE", "1");
    if (config.no_system_tracing)
        module.addCMacro("TRACY_NO_SYSTEM_TRACING", "1");
    if (config.delayed_init)
        module.addCMacro("TRACY_DELAYED_INIT", "1");
    if (config.manual_lifetime)
        module.addCMacro("TRACY_MANUAL_LIFETIME", "1");
    if (config.fibers)
        module.addCMacro("TRACY_FIBERS", "1");
    if (config.no_crash_handler)
        module.addCMacro("TRACY_NO_CRASH_HANDLER", "1");
    if (config.timer_fallback)
        module.addCMacro("TRACY_TIMER_FALLBACK", "1");
    if (config.rpmalloc_dynamic_tls and target.result.os.tag == .linux) {
        // Tracy's vendored rpmalloc requests initial-exec TLS on Linux. That
        // breaks late dlopen() of plugin binaries in hosts with limited static
        // TLS space, so use a Linux-compatible dynamic TLS branch instead.
        module.addCMacro("__HAIKU__", "1");
    }
    if (config.shared and target.result.os.tag == .windows)
        module.addCMacro("TRACY_EXPORTS", "1");
}

fn addTracyImportMacros(translate_c: *std.Build.Step.TranslateC, target: std.Build.ResolvedTarget, config: TracyConfig) void {
    if (config.enable)
        translate_c.defineCMacro("TRACY_ENABLE", null);
    if (config.on_demand)
        translate_c.defineCMacro("TRACY_ON_DEMAND", null);
    if (config.callstack) |depth| {
        translate_c.defineCMacro("TRACY_CALLSTACK", "\"" ++ digits2(depth) ++ "\"");
    }
    if (config.no_callstack)
        translate_c.defineCMacro("TRACY_NO_CALLSTACK", null);
    if (config.no_callstack_inlines)
        translate_c.defineCMacro("TRACY_NO_CALLSTACK_INLINES", null);
    if (config.only_localhost)
        translate_c.defineCMacro("TRACY_ONLY_LOCALHOST", null);
    if (config.no_broadcast)
        translate_c.defineCMacro("TRACY_NO_BROADCAST", null);
    if (config.only_ipv4)
        translate_c.defineCMacro("TRACY_ONLY_IPV4", null);
    if (config.no_code_transfer)
        translate_c.defineCMacro("TRACY_NO_CODE_TRANSFER", null);
    if (config.no_context_switch)
        translate_c.defineCMacro("TRACY_NO_CONTEXT_SWITCH", null);
    if (config.no_exit)
        translate_c.defineCMacro("TRACY_NO_EXIT", null);
    if (config.no_sampling)
        translate_c.defineCMacro("TRACY_NO_SAMPLING", null);
    if (config.no_verify)
        translate_c.defineCMacro("TRACY_NO_VERIFY", null);
    if (config.no_vsync_capture)
        translate_c.defineCMacro("TRACY_NO_VSYNC_CAPTURE", null);
    if (config.no_frame_image)
        translate_c.defineCMacro("TRACY_NO_FRAME_IMAGE", null);
    if (config.no_system_tracing)
        translate_c.defineCMacro("TRACY_NO_SYSTEM_TRACING", null);
    if (config.delayed_init)
        translate_c.defineCMacro("TRACY_DELAYED_INIT", null);
    if (config.manual_lifetime)
        translate_c.defineCMacro("TRACY_MANUAL_LIFETIME", null);
    if (config.fibers)
        translate_c.defineCMacro("TRACY_FIBERS", null);
    if (config.no_crash_handler)
        translate_c.defineCMacro("TRACY_NO_CRASH_HANDLER", null);
    if (config.timer_fallback)
        translate_c.defineCMacro("TRACY_TIMER_FALLBACK", null);
    if (config.shared and target.result.os.tag == .windows)
        translate_c.defineCMacro("TRACY_IMPORTS", null);
}

const tracy_header_files = [_][]const u8{
    "tracy/TracyC.h",
    "tracy/Tracy.hpp",
    "tracy/TracyCUDA.hpp",
    "tracy/TracyD3D11.hpp",
    "tracy/TracyD3D12.hpp",
    "tracy/TracyLua.hpp",
    "tracy/TracyOpenCL.hpp",
    "tracy/TracyOpenGL.hpp",
    "tracy/TracyVulkan.hpp",

    "client/TracyArmCpuTable.hpp",
    "client/TracyCallstack.h",
    "client/TracyCallstack.hpp",
    "client/tracy_concurrentqueue.h",
    "client/TracyCpuid.hpp",
    "client/TracyDebug.hpp",
    "client/TracyDxt1.hpp",
    "client/TracyFastVector.hpp",
    "client/TracyKCore.hpp",
    "client/TracyLock.hpp",
    "client/TracyProfiler.hpp",
    "client/TracyRingBuffer.hpp",
    "client/tracy_rpmalloc.hpp",
    "client/TracyScoped.hpp",
    "client/tracy_SPSCQueue.h",
    "client/TracyStringHelpers.hpp",
    "client/TracySysPower.hpp",
    "client/TracySysTime.hpp",
    "client/TracySysTrace.hpp",
    "client/TracyThread.hpp",

    "common/TracyAlign.hpp",
    "common/TracyAlloc.hpp",
    "common/TracyApi.h",
    "common/TracyColor.hpp",
    "common/TracyForceInline.hpp",
    "common/TracyMutex.hpp",
    "common/TracyProtocol.hpp",
    "common/TracyQueue.hpp",
    "common/TracySocket.hpp",
    "common/TracyStackFrames.hpp",
    "common/TracySystem.hpp",
    "common/TracyVersion.hpp",
    "common/TracyWinFamily.hpp",
    "common/TracyYield.hpp",
    "common/tracy_lz4.hpp",
    "common/tracy_lz4hc.hpp",
};
