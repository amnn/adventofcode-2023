const std = @import("std");
const lib = @import("lib");

const math = std.math;
const scan = lib.scan;
const sort = std.sort;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const File = std.fs.File;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const Reader = std.io.Reader;

const Almanac = struct {
    seed_to_soil: Map,
    soil_to_fertilizer: Map,
    fertilizer_to_water: Map,
    water_to_light: Map,
    light_to_temperature: Map,
    temperature_to_humidity: Map,
    humidity_to_location: Map,

    fn parse(r: *Reader, alloc: Allocator) !Almanac {
        var seed_to_soil = try Map.parse(r, alloc, "seed-to-soil");
        errdefer seed_to_soil.deinit(alloc);

        try scan.prefix(r, "\n");
        var soil_to_fertilizer = try Map.parse(r, alloc, "soil-to-fertilizer");
        errdefer soil_to_fertilizer.deinit(alloc);

        try scan.prefix(r, "\n");
        var fertilizer_to_water = try Map.parse(r, alloc, "fertilizer-to-water");
        errdefer fertilizer_to_water.deinit(alloc);

        try scan.prefix(r, "\n");
        var water_to_light = try Map.parse(r, alloc, "water-to-light");
        errdefer water_to_light.deinit(alloc);

        try scan.prefix(r, "\n");
        var light_to_temperature = try Map.parse(r, alloc, "light-to-temperature");
        errdefer light_to_temperature.deinit(alloc);

        try scan.prefix(r, "\n");
        var temperature_to_humidity = try Map.parse(r, alloc, "temperature-to-humidity");
        errdefer temperature_to_humidity.deinit(alloc);

        try scan.prefix(r, "\n");
        var humidity_to_location = try Map.parse(r, alloc, "humidity-to-location");
        errdefer humidity_to_location.deinit(alloc);

        return .{
            .seed_to_soil = seed_to_soil,
            .soil_to_fertilizer = soil_to_fertilizer,
            .fertilizer_to_water = fertilizer_to_water,
            .water_to_light = water_to_light,
            .light_to_temperature = light_to_temperature,
            .temperature_to_humidity = temperature_to_humidity,
            .humidity_to_location = humidity_to_location,
        };
    }

    fn seedToLocation(self: *Almanac, seed: u64) u64 {
        const soil = self.seed_to_soil.get(seed);
        const fertilizer = self.soil_to_fertilizer.get(soil);
        const water = self.fertilizer_to_water.get(fertilizer);
        const light = self.water_to_light.get(water);
        const temperature = self.light_to_temperature.get(light);
        const humidity = self.temperature_to_humidity.get(temperature);
        const location = self.humidity_to_location.get(humidity);
        return location;
    }

    fn deinit(self: *Almanac, alloc: Allocator) void {
        self.seed_to_soil.deinit(alloc);
        self.soil_to_fertilizer.deinit(alloc);
        self.fertilizer_to_water.deinit(alloc);
        self.water_to_light.deinit(alloc);
        self.light_to_temperature.deinit(alloc);
        self.temperature_to_humidity.deinit(alloc);
        self.humidity_to_location.deinit(alloc);
    }
};

const Map = struct {
    ranges: []const Range,

    fn parse(r: *Reader, alloc: Allocator, name: []const u8) !Map {
        try scan.prefix(r, name);
        try scan.prefix(r, " map:\n");

        var ranges: ArrayList(Range) = try .initCapacity(alloc, 0);
        defer ranges.deinit(alloc);

        while (true) {
            const range = Range.parse(r) catch break;
            try ranges.append(alloc, range);
            scan.prefix(r, "\n") catch break;
        }

        sort.pdq(Range, ranges.items, {}, Range.lessThan);

        return .{
            .ranges = try ranges.toOwnedSlice(alloc),
        };
    }

    fn get(self: Map, src: u64) u64 {
        const idx = sort.binarySearch(
            Range,
            self.ranges,
            src,
            Range.compare,
        ) orelse
            return src;

        const r = self.ranges[idx];
        return r.dst + (src - r.src);
    }

    fn deinit(self: *Map, alloc: Allocator) void {
        alloc.free(self.ranges);
    }
};

const Range = struct {
    dst: u64,
    src: u64,
    len: u64,

    fn parse(r: *Reader) !Range {
        var range: Range = undefined;

        range.dst = try scan.unsigned(u64, r);
        try scan.prefix(r, " ");
        range.src = try scan.unsigned(u64, r);
        try scan.prefix(r, " ");
        range.len = try scan.unsigned(u64, r);

        return range;
    }

    fn lessThan(ctx: void, a: Range, b: Range) bool {
        _ = ctx;
        return a.src < b.src;
    }

    fn compare(src: u64, r: Range) math.Order {
        if (src < r.src) {
            return .lt;
        } else if (src >= r.src + r.len) {
            return .gt;
        } else {
            return .eq;
        }
    }
};

pub fn main() !void {
    var input: [4096]u8 = undefined;
    var reader = File.stdin().reader(&input);
    const stdin = &reader.interface;

    var buf: [8192]u8 = undefined;
    var fba: FixedBufferAllocator = .init(&buf);
    const alloc = fba.allocator();

    const seeds = try parseSeeds(stdin, alloc);
    defer alloc.free(seeds);

    try scan.prefix(stdin, "\n\n");
    var almanac: Almanac = try .parse(stdin, alloc);
    defer almanac.deinit(alloc);

    var part1: u64 = math.maxInt(u64);
    for (seeds) |seed| {
        part1 = @min(part1, almanac.seedToLocation(seed));
    }

    std.debug.print("Part 1: {d}\n", .{part1});
}

fn parseSeeds(r: *Reader, alloc: Allocator) ![]u64 {
    var seeds: ArrayList(u64) = try .initCapacity(alloc, 1024);
    defer seeds.deinit(alloc);

    try scan.prefix(r, "seeds: ");
    while (true) {
        scan.spaces(r);
        const seed = scan.unsigned(u64, r) catch break;
        try seeds.append(alloc, seed);
    }

    return try seeds.toOwnedSlice(alloc);
}
