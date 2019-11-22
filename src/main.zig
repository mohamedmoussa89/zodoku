const std = @import("std");
const fs = std.fs;
const debug = std.debug;
const mem = std.mem;
const heap = std.heap;
const fmt = std.fmt;

const Puzzle = struct {
    const ALL_VALUES: u16 = (1 << 9) - 1;

    values: [9][9]u16,

    pub fn newFromFile(alloc: *mem.Allocator, path: []const u8) !Puzzle {
        
        var p = Puzzle{
            .values = [_][9]u16{[_]u16{ALL_VALUES} ** 9} ** 9
        };

        const fh = try fs.File.openRead(path);
        defer fh.close();
    
        var chunk = std.ArrayList(u8).init(alloc);
        defer chunk.deinit();     

        const fstream = &fh.inStream().stream;

        var row: u8 = 0;               
        var col: u8 = 0;

        while (true){
          const byte = fstream.readByte() catch |err| switch (err) {
            error.EndOfStream => {
              break;
            },
            else => return err,
          };          
          switch (byte) {
            '1' ... '9' => {
              p.values[row][col] = byte - '0';
              col += 1;
            },      
            '-' => col += 1,
            '\n' => {
              row += 1;
              col = 0;
            },
            else => continue
          }
          if (row == 9 or col == 0){
            break;
          }
        }        
        return p;
    }

};

pub fn main() !void {
    var alloc = debug.global_allocator;
    const p = try Puzzle.newFromFile(alloc, ".\\puzzles\\easy_puzzle1.txt");
}
