const std = @import("std");
const lib = @import("lib");

const heap = std.heap;
const scan = lib.scan;
const sort = std.sort;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Reader = std.io.Reader;

const Card = struct {
    num: u64,
    winning: []u64,
    on_card: []u64,

    fn parse(r: *Reader, alloc: Allocator) !Card {
        try scan.prefix(r, "Card");
        scan.spaces(r);

        const num = try scan.unsigned(u64, r);
        try scan.prefix(r, ":");

        var winning: ArrayList(u64) = try .initCapacity(alloc, 0);
        defer winning.deinit(alloc);

        var on_card: ArrayList(u64) = try .initCapacity(alloc, 0);
        defer on_card.deinit(alloc);

        while (true) {
            scan.spaces(r);
            try winning.append(alloc, scan.unsigned(u64, r) catch |e| {
                if (e == error.NoMatch) {
                    try scan.prefix(r, "|");
                    break;
                } else {
                    return e;
                }
            });
        }

        while (true) {
            scan.spaces(r);
            try on_card.append(alloc, scan.unsigned(u64, r) catch |e| {
                if (e == error.NoMatch) {
                    break;
                } else {
                    return e;
                }
            });
        }

        const S = struct {
            fn lessThan(ctx: void, a: u64, b: u64) bool {
                _ = ctx;
                return a < b;
            }
        };

        sort.pdq(u64, winning.items, {}, S.lessThan);
        sort.pdq(u64, on_card.items, {}, S.lessThan);

        return .{
            .num = num,
            .winning = try winning.toOwnedSlice(alloc),
            .on_card = try on_card.toOwnedSlice(alloc),
        };
    }

    fn matches(self: Card) u64 {
        var count: u64 = 0;
        var i: usize = 0;
        var j: usize = 0;

        while (i < self.winning.len and j < self.on_card.len) {
            if (self.winning[i] == self.on_card[j]) {
                count += 1;
                j += 1;
            } else if (self.winning[i] < self.on_card[j]) {
                i += 1;
            } else {
                j += 1;
            }
        }

        return count;
    }

    fn value(self: Card) u64 {
        const count = self.matches();
        if (count == 0) {
            return 0;
        } else {
            return @as(u64, 1) << @intCast(count - 1);
        }
    }

    fn deinit(self: *Card, alloc: Allocator) void {
        alloc.free(self.winning);
        alloc.free(self.on_card);
    }
};

pub fn main() !void {
    var input: [4096]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&input);
    const stdin = &reader.interface;

    var buf: [4 * 1024 * 1024]u8 = undefined;
    var fba = heap.FixedBufferAllocator.init(&buf);
    const alloc = fba.allocator();

    var counts: ArrayList(u64) = try .initCapacity(alloc, 0);
    defer counts.deinit(alloc);

    var i: u64 = 0;
    var part1: u64 = 0;
    var part2: u64 = 0;
    while (true) : (i += 1) {
        var card = Card.parse(stdin, fba.allocator()) catch |e|
            if (e == error.NoMatch) break else return e;
        defer card.deinit(fba.allocator());

        const hi = i + card.matches();
        while (counts.items.len <= hi) {
            try counts.append(alloc, 1);
        }

        var j = i + 1;
        const extra = counts.items[i];
        while (j <= hi) : (j += 1) {
            counts.items[j] += extra;
        }

        part1 += card.value();
        part2 += extra;

        scan.prefix(stdin, "\n") catch break;
    }

    std.debug.print("Part 1: {d}\n", .{part1});
    std.debug.print("Part 2: {d}\n", .{part2});
}
