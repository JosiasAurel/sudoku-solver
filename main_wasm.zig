const std = @import("std");
pub const alloc = std.heap.wasm_allocator;

//var sudokuGrid = [_][9]u32{
//[_]u32{ 0, 4, 0, 0, 0, 0, 6, 1, 2 },
//[_]u32{ 0, 8, 2, 9, 0, 0, 7, 0, 4 },
//[_]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
//[_]u32{ 0, 7, 0, 0, 0, 4, 0, 0, 0 },
//[_]u32{ 0, 0, 8, 5, 0, 0, 3, 7, 0 },
//[_]u32{ 0, 1, 3, 0, 0, 0, 0, 0, 0 },
//[_]u32{ 0, 0, 0, 8, 0, 0, 0, 0, 0 },
//[_]u32{ 0, 0, 5, 1, 0, 9, 0, 0, 0 },
//[_]u32{ 7, 0, 0, 0, 4, 0, 1, 0, 0 },
//};

// 040000612082900704000000000070004000008500370013000000000800000005109000700040100

extern fn print(d: i32) void;

var sudokuGrid = [_][9]u32{
    [_]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [_]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [_]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [_]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [_]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [_]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [_]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [_]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [_]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
};

export fn allocMem() *[]u8 {
    const str_mem = alloc.alloc(u8, 81) catch unreachable;
    return @constCast(&str_mem);
}

export fn freeMem(ptr: [*]u8) void {
    alloc.free(ptr[0..81]);
}

// fills the sudoki grid with the string
// expects each character to fall within [48, 57]
pub fn buildGridFromStr(str: [81]u8) void {
    var row: usize = 0;
    var column: usize = 0;
    for (str, 0..str.len) |c, i| {
        if ((i + 1) % 9 == 0) {
            row += 1;
            column = 0;
            continue;
        }
        sudokuGrid[row][column] = c - 48;
        column += 1;
    }
}

pub fn buildStrFromGrid() []u8 {
    var gridStr: [81]u8 = undefined;
    var index: usize = 0;
    for (sudokuGrid) |row| {
        for (row) |entry| {
            gridStr[index] = @intCast(entry + 48);
            index += 1;
        }
    }
    return &gridStr;
    // std.mem.copyBackwards(u8, str_ptr, gridStr);
}

fn out(str: []u8, str_ptr: [*]const u8) void {
    std.mem.copyBackwards(u8, &@constCast(str_ptr[0..81]).*, str);
}

export fn main(str_ptr: [*]const u8) u32 {
    var i: usize = 0;
    var j: usize = 0;
    // var result: []u8 = undefined;

    const str = str_ptr[0..81];
    // const sampleStr = "040000612082900704000000000070004000008500370013000000000800000005109000700040100";
    // buildGridFromStr(@constCast(sampleStr).*);
    buildGridFromStr(@constCast(str).*);

    // print(@intCast(sudokuGrid[0][1]));
    // print(@intCast(sudokuGrid[0][6]));
    // print(@intCast(sudokuGrid[0][7]));
    // print(@intCast(sudokuGrid[8][6]));
    // print(@intCast(sudokuGrid[8][4]));

    const solved = solve(&sudokuGrid, &i, &j);
    // print(@intCast(@intFromBool(solved)));
    if (solved) {
        const out_str = buildStrFromGrid();
        out(@constCast(&out_str).*, str_ptr);
    } else out(@constCast("Failed!"), str_ptr);

    return @intCast(@intFromBool(solved));
}

fn step(i: *usize, j: *usize) void {
    if (j.* == 8) {
        j.* = 0;
        i.* += 1;
        return;
    }
    j.* += 1;
}

fn solve(grid: *[9][9]u32, i: *usize, j: *usize) bool {
    // freeze the i,j of the parent function
    const _i = i.*;
    const _j = j.*;
    // look for values that are 0 (representing empty values that need to be filled!)
    while (grid[i.*][j.*] != 0) {
        step(i, j);
    }

    // to be filled with non-zero values in the current
    // 1. row/column
    // 2. sudoku sub-grid
    var array: [9]u32 = [9]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    getRow_Col(&array, grid.*, i.*, j.*);
    getSubGrid(&array, grid.*, i.*, j.*);

    for (array, 0..array.len) |p, idx| {
        if (p == 0) {
            // fill the item at 0 with it's numeric value
            grid[i.*][j.*] = @intCast(idx + 1);
            // if we just filled the last value, then we solved the sudoku
            if (i.* == 8 and j.* == 8) return true;
            // try to recursively solve the sudoku
            const solved = solve(grid, i, j); // forward and try solving the next entry
            if (solved) return true; // return if we solved it (will propagate back to the original caller)
            // will continue here and try a different value if the last forward failed
        }
    }

    // step behind
    grid[i.*][j.*] = 0; // set the entry to zero so the caller can try a different value
    i.* = _i;
    j.* = _j;
    return false; // didn't solve :(
}

fn getSubGrid(array: *[9]u32, grid: [9][9]u32, i: usize, j: usize) void {
    const bi: usize = if (i < 3) 3 else if (i < 6 and i >= 3) 6 else 9;
    const bj: usize = if (j < 3) 3 else if (j < 6 and j >= 3) 6 else 9;

    for ((bi - 3)..bi) |idx| {
        for ((bj - 3)..bj) |jdx| {
            const num = grid[idx][jdx];
            if (num != 0) {
                array[num - 1] = num;
            }
        }
    }
}

fn getRow_Col(array: *[9]u32, grid: [9][9]u32, i: usize, j: usize) void {
    for (0..9, 0..9) |_i, _j| {
        const num1 = grid[i][_j];
        const num2 = grid[_i][j];

        if (num1 != 0) {
            array[num1 - 1] = num1;
        }
        if (num2 != 0) {
            array[num2 - 1] = num2;
        }
    }
}
