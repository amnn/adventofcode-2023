const std = @import("std");
const lib = @import("lib");

const ascii = std.ascii;
const heap = std.heap;
const grid = lib.grid;

const ArrayList = std.ArrayListUnmanaged;
const Dir = lib.grid.Dir;
const File = std.fs.File;
const Grid = lib.grid.Grid;
const Point = lib.grid.Point;
const Reader = std.io.Reader;

const Part = struct {
    pos: Point,
    val: u64,

    /// Find the part number at the given offset from the `base` point, if it
    /// exists.
    fn find(g: Grid(u8), base: Point, dx: isize, dy: isize) ?Part {
        const p = base.move(dx, dy) orelse return null;
        const c = g.get(p) orelse return null;
        if (!ascii.isDigit(c)) {
            return null;
        }

        // We know that there's at least one digit here, walk back to find
        // where the number starts.
        const row = g.row(p.y).?;
        var x = p.x;
        while (x > 0 and ascii.isDigit(row[x - 1])) : (x -= 1) {}

        // Then walk forward to parse the full number.
        const pos: Point = .pt(x, p.y);
        var val: u64 = 0;
        while (x < row.len and ascii.isDigit(row[x])) : (x += 1) {
            val *= 10;
            val += @intCast(row[x] - '0');
        }

        return .{ .pos = pos, .val = val };
    }
};

pub fn main() !void {
    var input: [4096]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&input);
    const stdin = &reader.interface;

    var buffer: [4 * 1024 * 1024]u8 = undefined;
    var fba = heap.FixedBufferAllocator.init(&buffer);
    const a = fba.allocator();

    const g = try grid.read(stdin, a);

    std.debug.print("Part 1: {d}\n", .{part1(g)});
    std.debug.print("Part 2: {d}\n", .{part2(g)});
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

                is_part_num |= isSymbol(g, here, -1, -1);
                is_part_num |= isSymbol(g, here, -1, 0);
                is_part_num |= isSymbol(g, here, -1, 1);
                is_part_num |= isSymbol(g, here, 0, 1);
                is_part_num |= isSymbol(g, here, 1, 1);
                is_part_num |= isSymbol(g, here, 1, 0);
                is_part_num |= isSymbol(g, here, 1, -1);
                is_part_num |= isSymbol(g, here, 0, -1);
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

fn part2(g: Grid(u8)) u64 {
    var gears = g.find('*');

    var ratios: u64 = 0;
    while (gears.next()) |pt| {
        var buf: [2]Part = undefined;
        var parts = ArrayList(Part).initBuffer(&buf);

        addCandidate(&parts, Part.find(g, pt, -1, -1)) catch continue;
        addCandidate(&parts, Part.find(g, pt, -1, 0)) catch continue;
        addCandidate(&parts, Part.find(g, pt, -1, 1)) catch continue;
        addCandidate(&parts, Part.find(g, pt, 0, 1)) catch continue;
        addCandidate(&parts, Part.find(g, pt, 1, 1)) catch continue;
        addCandidate(&parts, Part.find(g, pt, 1, 0)) catch continue;
        addCandidate(&parts, Part.find(g, pt, 1, -1)) catch continue;
        addCandidate(&parts, Part.find(g, pt, 0, -1)) catch continue;

        if (parts.items.len != 2) {
            continue;
        }

        ratios += parts.items[0].val * parts.items[1].val;
    }

    return ratios;
}

fn isSymbol(g: Grid(u8), base: Point, dx: isize, dy: isize) bool {
    const p = base.move(dx, dy) orelse return false;
    const c = g.get(p) orelse return false;
    return !ascii.isDigit(c) and c != '.';
}

fn addCandidate(parts: *ArrayList(Part), part: ?Part) !void {
    const p = part orelse return;
    for (parts.items) |existing| {
        if (std.meta.eql(existing.pos, p.pos)) {
            return;
        }
    } else if (parts.unusedCapacitySlice().len == 0) {
        return error.OutOfMemory;
    } else {
        parts.appendAssumeCapacity(p);
    }
}
