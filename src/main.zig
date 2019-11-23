const std = @import("std");
const fs = std.fs;
const io = std.io;
const os = std.os;
const debug = std.debug;
const mem = std.mem;
const heap = std.heap;
const fmt = std.fmt;

const Log2Int = std.math.Log2Int;

pub fn lowestBitIndex(comptime T: type, x: T) T {
  const lsb: T = x & (~x+1);
  const bit_width: T = 8*@sizeOf(T);
  return bit_width - @clz(T, x);
}

pub fn shiftedBit(comptime T: type, x: T) T {
  return @as(T,1) << @truncate(Log2Int(T), x);
}

pub fn countBits(comptime T: type, x: T) T {
  return @popCount(T, x);
}

const Puzzle = struct {
    const ALL_VALUES: u16 = (1 << 9) - 1;
    values: [9][9]u16,

    fn assertValueRange(x: u16) void {
      debug.assert(x >= 1);
      debug.assert(x <= 9);
    }

    pub fn setValue(self: *Puzzle, row: usize, col: usize, val: u16) void {
      assertValueRange(val);
      const bit = shiftedBit(u16, val-1);
      self.values[row][col] = bit;
    }

    pub fn addValue(self: *Puzzle, row: usize, col: usize, val: u16) void {
      assertValueRange(val);
      const bit = shiftedBit(u16, val-1);
      self.values[row][col] |= bit;
    }

    pub fn containsValue(self: *Puzzle, row: usize, col: usize, val: u8) bool {
      assertValueRange(val);
      const bit = shiftedBit(u16, val-1);
      return (self.values[row][col] & bit) > 0;
    }

    pub fn countValues(self: *Puzzle, row: usize, col: usize) u16 {
      return countBits(u16, self.values[row][col]);
    }

    pub fn getFirstValue(self: *Puzzle, row: usize, col: usize) u16 {
      return lowestBitIndex(u16, self.values[row][col]);
    }

    pub fn newFromFile(path: []const u8) !Puzzle {
        
        var p = Puzzle{
            .values = [_][9]u16{[_]u16{ALL_VALUES} ** 9} ** 9
        };

        const fh = try fs.File.openRead(path);
        defer fh.close();  

        const fstream = &fh.inStream().stream;

        var row: usize = 0;               
        var col: usize = 0;

        while (true){
          const byte = fstream.readByte() catch |err| switch (err) {
            error.EndOfStream => {
              break;
            },
            else => return err,
          };          
          switch (byte) {
            '1' ... '9' => {
              p.setValue(row, col, byte-'0');
              col += 1;
            },      
            '-' => col += 1,
            '\n' => {
              row += 1;
              col = 0;
            },
            else => continue
          }
          if (row == 9){
            break;
          }
        }        
        return p;
    }

    pub fn print(self: *Puzzle, stream: *io.OutStream(os.WriteError)) !void {
      for (self.values) |row_data, row| {
        for (row_data) |cell, col| {
          if (self.countValues(row, col) == 1){
           const val = self.getFirstValue(row, col);
           try stream.print("{} ", val);
          }else{
           try stream.print("- ");
          }
        }
        try stream.print("\n");
      }
    }

};

pub fn main() !void {
    var alloc = debug.global_allocator;
    const stdout = &std.io.getStdOut().outStream().stream;
    var p = try Puzzle.newFromFile(".\\puzzles\\easy_puzzle1.txt");    
    try p.print(stdout);
}
