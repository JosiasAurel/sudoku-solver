const std = @import("std");
const print = std.debug.print;
const BoundedArray = std.BoundedArray(u32, 100);
const HistoryMap = std.StringHashMap(HistoryObj);
const History = std.BoundedArray(Pair, 100);

var sudokuGrid = [_][9]u32{
    [_]u32{ 5, 7, 3, 0, 0, 1, 0, 6, 0 },
    [_]u32{ 0, 0, 0, 0, 6, 3, 1, 4, 0 },
    [_]u32{ 0, 0, 6, 9, 0, 0, 3, 2, 0 },
    [_]u32{ 0, 6, 0, 5, 0, 0, 2, 0, 8 },
    [_]u32{ 2, 8, 5, 0, 0, 7, 0, 0, 1 },
    [_]u32{ 0, 0, 1, 0, 2, 9, 0, 0, 6 },
    [_]u32{ 1, 2, 0, 4, 5, 0, 0, 7, 0 },
    [_]u32{ 6, 0, 9, 1, 0, 0, 5, 0, 0 },
    [_]u32{ 7, 0, 0, 0, 0, 0, 6, 1, 0 },
};

const HistoryObj = struct {
    const Self = @This();
    count: u32 = 0,
    i: usize = 0,
    j: usize = 0,
    values: BoundedArray,
};

const Pair = struct { i: usize, j: usize };

pub fn main() !void {
    var HeapAllocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = HeapAllocator.allocator();

    var historyMap = HistoryMap.init(allocator);
    try historyMap.ensureTotalCapacity(100);
    var list = std.ArrayList(Pair).init(allocator);

    defer {
        historyMap.deinit();
        list.deinit();
        const status = HeapAllocator.deinit();
        switch (status) {
            .leak => @panic("failed to deinit allocator"),
            else => {},
        }
    }

    var i: usize = 0;
    var j: usize = 0;
    var mset: bool = false;
    while (i < sudokuGrid.len) : (i += 1) {
        if (!mset) j = 0;
        while (j < sudokuGrid[0].len) {
            var slot = sudokuGrid[i][j];
            var usedNums = try BoundedArray.init(10);
            for (0..10) |u| {
                usedNums.set(u, 0);
            }
            var backtrack: bool = true;

            if (slot == 0 or mset) {
                mset = false;
                var key = try indexToString(i, j);

                getCol(&usedNums, sudokuGrid, j);
                getRow(&usedNums, sudokuGrid, i);
                getSubGrid(&usedNums, sudokuGrid, i, j);
                // print("{any} \n", .{usedNums.constSlice()});
                for (usedNums.constSlice(), 0..10) |item, n| {
                    const num: u32 = @intCast(n + 1);
                    if (item == 0 and isValidEntry(&usedNums, num) and num != 10) {
                        var historyObj = HistoryObj{ .i = i, .j = j, .values = try BoundedArray.init(10) };
                        var existingObj = historyMap.get(key);
                        backtrack = false;

                        if (existingObj) |xobj| {
                            for (xobj.values.constSlice()) |v| {
                                if (num != v) {
                                    sudokuGrid[i][j] = num;

                                    for (xobj.values.constSlice()) |co| {
                                        historyObj.values.set(historyObj.count, co);
                                        historyObj.count += 1;
                                    }

                                    historyObj.values.set(historyObj.count, num);
                                    historyObj.count += 1;

                                    try historyMap.put(key, historyObj);
                                }
                            }
                        } else {
                            sudokuGrid[i][j] = num;

                            historyObj.values.set(historyObj.count, num);
                            historyObj.count += 1;

                            try historyObj.values.resize(historyObj.count);

                            // insert the pair into the map
                            const newKey = try indexToString(i, j);
                            try historyMap.putNoClobber(newKey, historyObj);

                            // insert the pair in hisory
                            try list.append(.{ .i = i, .j = j });

                            break;
                        }
                    }
                }
                if (backtrack) {
                    // pop the last item from history
                    // remove entry from hashmap
                    // change the value of i & j
                    sudokuGrid[i][j] = 0;
                    const last = list.pop();
                    _ = historyMap.remove(key);
                    // historyCount -= 1;
                    i = last.i;
                    j = last.j;
                    mset = true;
                }
            }
            if (!mset) j += 1;
        }
    }

    showGrid(sudokuGrid);
}

fn indexToString(i: usize, j: usize) ![]u8 {
    const state = struct {
        var buffer: [50]u8 = undefined;
    };
    var result = try std.fmt.bufPrint(&state.buffer, "{},{}", .{ i, j });
    return result;
}
fn showGrid(grid: [9][9]u32) void {
    for (grid) |row| {
        for (row) |slot| {
            print("{} ", .{slot});
        }
        print("\n", .{});
    }
}

fn isValidEntry(array: *BoundedArray, input: u32) bool {
    for (array.constSlice()) |v| {
        if (v == 0) continue;
        if (v == input) return false;
    }
    return true;
}

fn getSubGrid(array: *BoundedArray, grid: [9][9]u32, i: usize, j: usize) void {
    const bi: usize = if (i < 3) 3 else if (i < 6 and i >= 3) 6 else 9;
    const bj: usize = if (j < 3) 3 else if (j < 6 and j >= 3) 6 else 9;

    for ((bi - 3)..bi) |idx| {
        for ((bj - 3)..bj) |jdx| {
            var num = grid[idx][jdx];
            if (num != 0) {
                array.set(num - 1, num);
            }
        }
    }
}

fn getCol(array: *BoundedArray, grid: [9][9]u32, j: usize) void {
    for (0..9) |i| {
        var num = grid[i][j];
        if (num != 0) {
            array.set(num - 1, num);
        }
    }
}

fn getRow(array: *BoundedArray, grid: [9][9]u32, i: usize) void {
    for (0..9) |j| {
        var num = grid[i][j];
        if (num != 0) {
            array.set(num - 1, num);
        }
    }
}
