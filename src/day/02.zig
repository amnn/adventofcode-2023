const std = @import("std");
const lib = @import("lib");

const heap = std.heap;
const scan = lib.scan;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const File = std.fs.File;
const Reader = std.io.Reader;

const Game = struct {
    id: u64,
    rounds: []const Round,

    fn parse(r: *Reader, a: Allocator) !Game {
        var game: Game = undefined;

        try scan.prefix(r, "Game ");
        game.id = try scan.unsigned(u64, r);

        var rounds = try ArrayList(Round).initCapacity(a, 0);
        defer rounds.deinit(a);

        try scan.prefix(r, ": ");
        while (true) {
            try rounds.append(a, try Round.parse(r));
            scan.prefix(r, "; ") catch break;
        }

        game.rounds = try rounds.toOwnedSlice(a);
        return game;
    }

    fn isPossible(self: *const Game) bool {
        return for (self.rounds) |r| {
            if (r.r > 12 or r.g > 13 or r.b > 14) break false;
        } else true;
    }

    fn deinit(self: *Game, a: Allocator) void {
        a.free(self.rounds);
    }
};

const Round = struct {
    r: u64 = 0,
    g: u64 = 0,
    b: u64 = 0,

    fn parse(r: *Reader) !Round {
        var round = Round{};

        while (true) {
            const count = try scan.unsigned(u64, r);
            try scan.prefix(r, " ");

            switch (try scan.@"enum"(Color, r)) {
                .red => round.r = count,
                .green => round.g = count,
                .blue => round.b = count,
            }

            scan.prefix(r, ", ") catch break;
        }

        return round;
    }
};

const Color = enum {
    red,
    green,
    blue,
};

pub fn main() !void {
    var input: [4096]u8 = undefined;
    var reader = File.stdin().reader(&input);
    const stdin = &reader.interface;

    var buffer: [8192]u8 = undefined;
    var fba = heap.FixedBufferAllocator.init(&buffer);
    const a = fba.allocator();

    var part1: u64 = 0;
    while (true) {
        var game = Game.parse(stdin, a) catch break;
        defer game.deinit(a);

        if (game.isPossible()) {
            part1 += game.id;
        }

        scan.prefix(stdin, "\n") catch break;
    }

    std.debug.print("Part 1: {d}\n", .{part1});
}
