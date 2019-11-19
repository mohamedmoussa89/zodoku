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
    
        var contents = std.ArrayList(u8).init(alloc);
        defer contents.deinit();

        const fstream = &fh.inStream().stream;
        while (true){
          const byte = fstream.readByte() catch |err| switch (err) {
            error.EndOfStream => {
              break;
            },
            else => return err,
          };
          debug.warn("{c}", @bitCast(u8,byte));
        }
        debug.warn("\n");
        return p;
    }

};

pub fn main() !void {
    var alloc = debug.global_allocator;
    const p = try Puzzle.newFromFile(alloc, ".\\puzzles\\easy_puzzle1.txt");
}
