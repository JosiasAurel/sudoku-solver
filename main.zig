const std = @import("std");

// https://github.com/ziglang/zig/blob/d2014fe9713794f6cc0830301a1110d5e92d0ff0/lib/std/debug.zig#L84C1-L84C1
pub fn print(comptime fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    nosuspend stdout.print(fmt, args) catch return;
}

var sudokuGrid = [_][9]u32{
    [_]u32{ 0, 4, 0, 0, 0, 0, 6, 1, 2 },
    [_]u32{ 0, 8, 2, 9, 0, 0, 7, 0, 4 },
    [_]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [_]u32{ 0, 7, 0, 0, 0, 4, 0, 0, 0 },
    [_]u32{ 0, 0, 8, 5, 0, 0, 3, 7, 0 },
    [_]u32{ 0, 1, 3, 0, 0, 0, 0, 0, 0 },
    [_]u32{ 0, 0, 0, 8, 0, 0, 0, 0, 0 },
    [_]u32{ 0, 0, 5, 1, 0, 9, 0, 0, 0 },
    [_]u32{ 7, 0, 0, 0, 4, 0, 1, 0, 0 },
};

pub fn main() void {
    var i: usize = 0;
    var j: usize = 0;

    const solved = solve(&sudokuGrid, &i, &j);
    if (solved) {
        showGrid(sudokuGrid);
    } else print("You failed 😛\n", .{});
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
    var _i = i.*;
    var _j = j.*;
    while (grid[i.*][j.*] != 0) {
        step(i, j);
    }

    var array: [9]u32 = [9]u32{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    getRow_Col(&array, grid.*, i.*, j.*);
    getSubGrid(&array, grid.*, i.*, j.*);

    for (array, 0..array.len) |p, idx| {
        if (p == 0) {
            grid[i.*][j.*] = @intCast(idx + 1);
            if (i.* == 8 and j.* == 8) return true;
            const solved = solve(grid, i, j);
            if (solved) return true;
        }
    }

    // step behind
    grid[i.*][j.*] = 0;
    i.* = _i;
    j.* = _j;
    return false;
}

fn showGrid(grid: [9][9]u32) void {
    for (grid) |row| {
        for (row) |slot| {
            print("{} ", .{slot});
        }
        print("\n", .{});
    }
}

fn getSubGrid(array: *[9]u32, grid: [9][9]u32, i: usize, j: usize) void {
    const bi: usize = if (i < 3) 3 else if (i < 6 and i >= 3) 6 else 9;
    const bj: usize = if (j < 3) 3 else if (j < 6 and j >= 3) 6 else 9;

    for ((bi - 3)..bi) |idx| {
        for ((bj - 3)..bj) |jdx| {
            var num = grid[idx][jdx];
            if (num != 0) {
                array[num - 1] = num;
            }
        }
    }
}

fn getRow_Col(array: *[9]u32, grid: [9][9]u32, i: usize, j: usize) void {
    for (0..9, 0..9) |_i, _j| {
        var num1 = grid[i][_j];
        var num2 = grid[_i][j];

        if (num1 != 0) {
            array[num1 - 1] = num1;
        }
        if (num2 != 0) {
            array[num2 - 1] = num2;
        }
    }
}
