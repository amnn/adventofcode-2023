const std = @import("std");

const Limit = std.Io.Limit;
const Reader = std.Io.Reader;
const Writer = std.Io.Writer;

/// Read a line from `Reader` `r`, as long as it fits into the reader's
/// internal buffer.
///
/// Returns `null` if there are no more lines.
pub fn readLine(r: *Reader) !?[]u8 {
    return r.takeDelimiterInclusive('\n') catch |e| switch (e) {
        error.EndOfStream => return null,
        else => return e,
    };
}

test "readLine simple" {
    var r = Reader.fixed("hello\nworld\n");
    try std.testing.expectEqualStrings("hello\n", (try readLine(&r)).?);
    try std.testing.expectEqualStrings("world\n", (try readLine(&r)).?);
    try std.testing.expectEqual(null, try readLine(&r));
}

test "readLine no delimiter" {
    var r = Reader.fixed("hello");
    try std.testing.expectEqual(null, try readLine(&r));
}
