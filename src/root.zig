const std = @import("std");

const Limit = std.Io.Limit;
const Reader = std.Io.Reader;
const Writer = std.Io.Writer;

/// Read a line from `Reader` `r` into fixed-size `buffer`, returning `null`
/// after reading the first empty line, and an error if the read fails.
pub fn readLine(r: *Reader, buffer: []u8) !?[]u8 {
    var w = Writer.fixed(buffer);
    if (0 == try r.streamDelimiterEnding(&w, '\n')) return null;
    _ = try r.discard(Limit.limited(1));

    return w.buffered();
}
