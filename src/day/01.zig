const std = @import("std");

const lib = @import("lib");

const mem = std.mem;

const File = std.fs.File;
const Limit = std.Io.Limit;
const Writer = std.Io.Writer;

const Error = error{
    BadInput,
};

pub fn main() !void {
    var line: [4096]u8 = undefined;
    var input: [4096]u8 = undefined;
    var reader = File.stdin().reader(&input);
    const stdin = &reader.interface;

    var part1: u64 = 0;
    while (try lib.readLine(stdin, &line)) |l| {
        part1 += try calibrationPart1(l);
    }

    std.debug.print("Part 1: {d}\n", .{part1});
}

fn calibrationPart1(line: []const u8) !u8 {
    const fst = mem.indexOfAny(u8, line, "0123456789") orelse return error.BadInput;
    const lst = mem.lastIndexOfAny(u8, line, "0123456789") orelse return error.BadInput;
    return (line[fst] - '0') * 10 + (line[lst] - '0');
}
