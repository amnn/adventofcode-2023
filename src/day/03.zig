const std = @import("std");
const lib = @import("lib");

const ascii = std.ascii;
const heap = std.heap;
const grid = lib.grid;

const File = std.fs.File;
const Grid = lib.grid.Grid;
const Point = lib.grid.Point;
const Reader = std.io.Reader;

pub fn main() !void {
    var input: [4096]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&input);
    const stdin = &reader.interface;

    var buffer: [4 * 1024 * 1024]u8 = undefined;
    var fba = heap.FixedBufferAllocator.init(&buffer);
    const a = fba.allocator();

    const g = try grid.read(stdin, a);

    std.debug.print("Part 1: {d}\n", .{part1(g)});
}

fn part1(g: Grid(u8)) u64 {
    var parts: u64 = 0;
    var y: usize = 0;
    var r = g.rows();
    while (r.next()) |row| {
        var num: u64 = 0;
        var is_part_num = false;
        for (row, 0..) |c, x| {
            if (ascii.isDigit(c)) {
                num *= 10;
                num += @intCast(c - '0');
                const here: Point = .pt(x, y);

                if (here.move(.u, 1)) |up| {
                    is_part_num |= isSymbol(g, up);
                    is_part_num |= isSymbol(g, up.move(.l, 1));
                    is_part_num |= isSymbol(g, up.move(.r, 1));
                }

                if (here.move(.d, 1)) |down| {
                    is_part_num |= isSymbol(g, down);
                    is_part_num |= isSymbol(g, down.move(.l, 1));
                    is_part_num |= isSymbol(g, down.move(.r, 1));
                }

                is_part_num |= isSymbol(g, here.move(.l, 1));
                is_part_num |= isSymbol(g, here.move(.r, 1));
            } else {
                if (is_part_num) {
                    parts += num;
                }

                num = 0;
                is_part_num = false;
            }
        } else if (is_part_num) {
            parts += num;
        }
        y += 1;
    }

    return parts;
}

fn isSymbol(g: Grid(u8), pt: ?Point) bool {
    const c = g.get(pt orelse return false) orelse return false;
    return !ascii.isDigit(c) and c != '.';
}
