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

    pub fn removeValueSet(self: *Puzzle, row: usize, col: usize, val_set: u16) void{
      self.values[row][col] &= ~val_set;
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
      // Determine max width based on largest value set
      var max_count: usize = 0;
      for (self.values) |row_data, row| {
        for (row_data) |cell, col| {
          max_count = std.math.max(max_count, self.countValues(row, col));
        }
      }

      const max_width = max_count+2;
      for (self.values) |row_data, row| {
        for (row_data) |cell, col| {          
          // Compute left and right offsets
          const value_count = self.countValues(row, col);
          var left_offset = (max_width-value_count)/2;
          var right_offset = (max_width-value_count-left_offset);
          // Print left offset
          while (left_offset > 0) : (left_offset -= 1){
            try stream.print(" ");
          }
          // Print value set
          var val: u8 = 1;
          while (val <= 9) : (val += 1){
            if (self.containsValue(row, col, val)){
              try stream.print("{}", val);
            }
          }
          // Print right offset
          while (right_offset > 0) : (right_offset -= 1){
            try stream.print(" ");
          }
          // Print column lines
          if (col == 2 or col == 5){
            try stream.print("|");
          }
        }
        try stream.print("\n");
        // Print row lines
        if (row == 2 or row == 5){
          var counter = 3*(max_width*3) + 2;
          while (counter > 0) : (counter -= 1){
            try stream.print("-");
          }
          try stream.print("\n");
        }
      }
    }
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
