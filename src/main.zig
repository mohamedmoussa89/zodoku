const std = @import("std");
const fs = std.fs;
const debug = std.debug;
const mem = std.mem;
const heap = std.heap;

const Puzzle = struct {
    const ALL_VALUES: u16 = (1 << 9) - 1;

    values: [9][9]u16,

    pub fn newFromFile(alloc: *mem.Allocator, path: []const u8) !Puzzle {
        
        var p = Puzzle{
            .values = [_][9]u16{[_]u16{ALL_VALUES} ** 9} ** 9
        };

        const fh = try fs.File.openRead(path);
        defer fh.close();

        return p;
    }

};

pub fn main() !void {
    var alloc = debug.global_allocator;
    const p = try Puzzle.newFromFile(alloc, "easy_puzzle1");
}
