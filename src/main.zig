const std = @import("std");
const fs = std.fs;
const io = std.io;
const os = std.os;
const debug = std.debug;
const mem = std.mem;
const heap = std.heap;
const fmt = std.fmt;

const Log2Int = std.math.Log2Int;

pub fn shiftedBit(comptime T: type, x: T) T {
  return @as(T,1) << @truncate(Log2Int(T), x);
}

pub fn countBits(comptime T: type, x: T) T {
  return @popCount(T, x);
}

const Puzzle = struct {
    const ALL_VALUES: u16 = (1 << 9) - 1;

    const RowCol = struct {
      row: usize,
      col: usize,
    };

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

    pub fn boxIndex(row: usize, col: usize) usize {
      return 3*(row/3) + (col/3);
    }

    pub fn constrainInner(self: *Puzzle) bool {
      var row_value_sets: [9]u16 = [_]u16{0} ** 9;
      var col_value_sets: [9]u16 = [_]u16{0} ** 9;
      var box_value_sets: [9]u16 = [_]u16{0} ** 9;
          
      var row: usize = 0;        
      while (row < 9) : (row += 1){
        var col: usize = 0;
        while (col < 9) : (col += 1){
          if (self.countValues(row, col) == 1){
            const box = Puzzle.boxIndex(row, col);
            const cell = self.values[row][col];          
            row_value_sets[row] |= cell;
            col_value_sets[col] |= cell;
            box_value_sets[box] |= cell;
          }          
        }
      }

      var change_made = false;    
      row = 0;
      while (row < 9) : (row += 1){
        var col: usize = 0;
        while (col < 9) : (col += 1){
          if (self.countValues(row, col) > 1){
            const box = Puzzle.boxIndex(row, col);
            const prior = self.values[row][col];    
            const combined_value_set = (row_value_sets[row] | col_value_sets[col] | box_value_sets[box]);
            self.removeValueSet(row, col, combined_value_set);
            const cell_changed = (prior ^ self.values[row][col]) > 0;
            change_made = change_made or cell_changed;
            if (cell_changed and self.countValues(row, col) == 1){
              const cell = self.values[row][col]; 
              row_value_sets[row] |= cell;
              col_value_sets[col] |= cell;
              box_value_sets[box] |= cell;
            }
          }
        }
      }
      return change_made;
    }

    pub fn constrain(self: *Puzzle) void {
      while (self.constrainInner()){
      }      
    }

    const SolveErrors = error {
      AllCellsFilled,
      NoOptionsLeft,
    };

    pub fn cellWithSmallestValueSet(self: *Puzzle) !RowCol {
      var ret_val: RowCol = RowCol{.row = 0, .col = 0};
      var smallest_count: u16 = 10;
      for (self.values) |row_data, row| {
        for (row_data) |cell, col| {
          const count = self.countValues(row, col);
          if (count != 1 and count < smallest_count){
            ret_val.row = row;
            ret_val.col = col;
            smallest_count = count;
          }
          if (smallest_count == 2){
            break;
          }
        }
      }
      if (smallest_count == 10){
        return error.AllCellsFilled;
      } else if (smallest_count == 0){
        return error.NoOptionsLeft;
      } else{
        return ret_val;
      }
    }

    pub fn solve(allocator: *mem.Allocator, initial_puzzle: Puzzle) !Puzzle {
      const stdout = &std.io.getStdOut().outStream().stream;

      var stack = std.ArrayList(Puzzle).init(allocator);  
      defer stack.deinit();

      try stack.append(initial_puzzle);
      while (stack.count() > 0){
        var puzzle = stack.pop();
        puzzle.constrain();        
        const cell = puzzle.cellWithSmallestValueSet() catch |err| switch (err){
          error.AllCellsFilled => return puzzle,
          error.NoOptionsLeft => continue,
        };
        var val: u8 = 1;
        while (val <= 9) : (val += 1){
          if (puzzle.containsValue(cell.row, cell.col, val)){
            var child_puzzle = Puzzle{.values = puzzle.values};
            child_puzzle.setValue(cell.row, cell.col, val);
            child_puzzle.constrain();
            try stack.append(child_puzzle);            
          }
        }
      }
      return initial_puzzle;
    }    
};

pub fn main() !void {
    var alloc = debug.global_allocator;
    const stdout = &std.io.getStdOut().outStream().stream;    
    var p = try Puzzle.newFromFile(".\\puzzles\\17.txt"); 
    try p.print(stdout);
    try stdout.print("\n");
    p = try Puzzle.solve(alloc, p);    
    try p.print(stdout);
}
