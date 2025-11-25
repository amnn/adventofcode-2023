const std = @import("std");

const lib = @import("lib");

const mem = std.mem;

const File = std.fs.File;
const Limit = std.Io.Limit;
const Writer = std.Io.Writer;

const Error = error{
    BadInput,
};

const DIGITS = .{
    "zero",
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
};

pub fn main() !void {
    var line: [4096]u8 = undefined;
    var input: [4096]u8 = undefined;
    var reader = File.stdin().reader(&input);
    const stdin = &reader.interface;

    var part1: u64 = 0;
    var part2: u64 = 0;
    while (try lib.readLine(stdin, &line)) |l| {
        part1 += try calibrationPart1(l);
        part2 += try calibrationPart2(l);
    }

    std.debug.print("Part 1: {d}\n", .{part1});
    std.debug.print("Part 2: {d}\n", .{part2});
}

fn calibrationPart1(line: []const u8) !u8 {
    const fst = mem.indexOfAny(u8, line, "0123456789") orelse return error.BadInput;
    const lst = mem.lastIndexOfAny(u8, line, "0123456789") orelse return error.BadInput;
    return (line[fst] - '0') * 10 + (line[lst] - '0');
}

fn calibrationPart2(line: []const u8) !u8 {
    var lo = mem.indexOfAny(u8, line, "0123456789");
    var fst = if (lo) |i| line[i] - '0' else null;

    var hi = mem.lastIndexOfAny(u8, line, "0123456789");
    var lst = if (hi) |i| line[i] - '0' else null;

    inline for (DIGITS, 0..) |word, digit| {
        if (mem.indexOf(u8, line, word)) |next| {
            if (lo == null or lo.? > next) {
                lo = next;
                fst = digit;
            }
        }

        if (mem.lastIndexOf(u8, line, word)) |next| {
            if (hi == null or hi.? < next) {
                hi = next;
                lst = digit;
            }
        }
    }

    return (fst orelse return error.BadInput) * 10 + (lst orelse return error.BadInput);
}
