const std = @import("std");
const lib = @import("lib");

const scan = lib.scan;

const ArrayList = std.ArrayList;
const File = std.fs.File;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const Reader = std.io.Reader;

pub fn main() !void {
    var input: [4096]u8 = undefined;
    var reader = File.stdin().reader(&input);
    const stdin = &reader.interface;

    var buf: [8192]u8 = undefined;
    var fba: FixedBufferAllocator = .init(&buf);
    const alloc = fba.allocator();

    const times = try parseNumbers(stdin, "Time", alloc);
    defer alloc.free(times);

    try scan.prefix(stdin, "\n");
    const dists = try parseNumbers(stdin, "Distance", alloc);
    defer alloc.free(dists);

    var part1: u64 = 1;
    for (times, dists) |T, D| {
        part1 *= ways(T, D);
    }

    std.debug.print("Part 1: {d}\n", .{part1});
}

fn parseNumbers(r: *Reader, label: []const u8, alloc: std.mem.Allocator) ![]u64 {
    try scan.prefix(r, label);
    try scan.prefix(r, ":");

    var nums: ArrayList(u64) = try .initCapacity(alloc, 0);
    defer nums.deinit(alloc);

    while (true) {
        scan.spaces(r);
        const n = scan.unsigned(u64, r) catch break;
        try nums.append(alloc, n);
    }

    return nums.toOwnedSlice(alloc);
}

/// Let T = the total time for the race
///     D = the current distance record
///
/// Define `d(c)` as the distance covered in time T when the boat is charged
/// for time c:
///
///     d(c) = (T - c) * c
///          = cT - c²
///
/// This function is maximized when its derivative is zero:
///
///     d'(c) = T - 2c = 0 => c = T/2
///
/// So the number of settings where the current record is beaten can be found
/// by binary searching between 0 and floor(T/2) to find the smallest `c` that
/// yields a `d(c) > D`, and between ceil(T/2) and T to find the smallest `c`
/// that yields a `d(c) <= D`.
fn ways(T: u64, D: u64) u64 {
    var lo: u64 = 0;
    var hi: u64 = T / 2;

    while (lo < hi) {
        const c = lo + (hi - lo) / 2;
        const d = (T - c) * c;
        if (d > D) {
            hi = c;
        } else {
            lo = c + 1;
        }
    }

    // At the end of the loop, lo == hi, and they both point at the first `c`
    // where d(c) > D.
    const fst = lo;

    lo = (T - 1) / 2 + 1;
    hi = T;

    while (lo < hi) {
        const c = lo + (hi - lo) / 2;
        const d = (T - c) * c;
        if (d <= D) {
            hi = c;
        } else {
            lo = c + 1;
        }
    }

    // At the end of the loop, lo == hi, and they both point at the first `c`
    // where `d(c) <= D`.
    const lst = lo;
    return lst - fst;
}
