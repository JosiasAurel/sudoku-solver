const std = @import("std");
const BoundedArray = std.BoundedArray(u32, 10);
const HistoryMap = std.StringHashMap([]HistoryObj);
const History = std.BoundedArray(Pair, 100);

// cheated from
// https://github.com/ziglang/zig/blob/d2014fe9713794f6cc0830301a1110d5e92d0ff0/lib/std/debug.zig#L84C1-L84C1
pub fn print(comptime fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    nosuspend stdout.print(fmt, args) catch return;
}
// var sudokuGrid = [_][9]u32{
//     [_]u32{ 5, 7, 3, 0, 0, 1, 0, 6, 0 },
//     [_]u32{ 0, 0, 0, 0, 6, 3, 1, 4, 0 },
//     [_]u32{ 0, 0, 6, 9, 0, 0, 3, 2, 0 },
//     [_]u32{ 0, 6, 0, 5, 0, 0, 2, 0, 8 },
//     [_]u32{ 2, 8, 5, 0, 0, 7, 0, 0, 1 },
//     [_]u32{ 0, 0, 1, 0, 2, 9, 0, 0, 6 },
//     [_]u32{ 1, 2, 0, 4, 5, 0, 0, 7, 0 },
//     [_]u32{ 6, 0, 9, 1, 0, 0, 5, 0, 0 },
//     [_]u32{ 7, 0, 0, 0, 0, 0, 6, 1, 0 },
// };

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

const HistoryObj = struct {
    const Self = @This();
    count: u32 = 0,
    i: usize = 0,
    j: usize = 0,
    values: BoundedArray,

    pub fn init(allocator: std.mem.Allocator, i: usize, j: usize) ![]HistoryObj {
        var item = HistoryObj{ .i = i, .j = j, .values = try BoundedArray.init(10) };
        // make all the values in the bounded array 0
        item.values.set(0, 0);
        item.values.set(1, 0);
        item.values.set(2, 0);
        item.values.set(3, 0);
        item.values.set(4, 0);
        item.values.set(5, 0);
        item.values.set(6, 0);
        item.values.set(7, 0);
        item.values.set(8, 0);
        item.values.set(9, 0);

        var itemArr = [_]HistoryObj{item};
        const memAddr = try allocator.alloc(HistoryObj, 1);
        std.mem.copy(HistoryObj, memAddr, &itemArr);
        return memAddr;
    }
};

const Pair = struct { i: usize, j: usize };

pub fn main() !void {
    var HeapAllocator = std.heap.GeneralPurposeAllocator(.{}){};
    var gpa = HeapAllocator.allocator();
    var ArenaAllocator = std.heap.ArenaAllocator.init(gpa);
    var allocator = ArenaAllocator.allocator();

    var historyMap = HistoryMap.init(allocator);
    try historyMap.ensureTotalCapacity(1000); // total capacity ensured is not on the basis of anything
    var list = std.ArrayList(Pair).init(allocator);

    defer {
        historyMap.deinit();
        list.deinit();
        ArenaAllocator.deinit();
    }

    var i: usize = 0;
    var j: usize = 0;

    // will be true if we don't want to modify
    // the values of i & j while backtracking
    var mset: bool = false;
    while (i < sudokuGrid.len) : (i += 1) {
        if (!mset) j = 0;
        while (j < sudokuGrid[0].len) {
            var slot = sudokuGrid[i][j];
            var usedNums = try BoundedArray.init(9);
            for (0..9) |u| {
                usedNums.set(u, 0);
            }
            var backtrack: bool = true;

            // if slot == 0
            // or this is a backtrack
            if (slot == 0 or mset) {
                mset = false;
                var key = try indexToString(i, j);

                getCol(&usedNums, sudokuGrid, j);
                getRow(&usedNums, sudokuGrid, i);
                getSubGrid(&usedNums, sudokuGrid, i, j);

                for (usedNums.constSlice(), 0..9) |item, n| {
                    if (item != 0) continue;
                    const num: u32 = @intCast(n + 1);

                    var existingObj = historyMap.get(key);

                    // does an object with this key exist already?
                    if (existingObj) |prevObj| {
                        var historyObj = &prevObj.ptr[0];
                        if (isValidEntry(&historyObj.values, num)) {
                            // if we found a valid entry, don't backtrack
                            backtrack = false;

                            sudokuGrid[i][j] = num;

                            // resize to make sure there's enough space to insert
                            // the new item
                            try historyObj.values.resize(historyObj.count + 1);

                            historyObj.values.set(historyObj.count, num);
                            historyObj.count += 1;
                            try historyObj.values.resize(historyObj.count);

                            try list.append(.{ .i = i, .j = j });

                            break;
                        }
                    } else {
                        // also don't backtrack if we are inserting a non-existent item
                        // or an item that previously existed but we removed while backtracking
                        backtrack = false;
                        sudokuGrid[i][j] = num;

                        var historyObjAddr = try HistoryObj.init(allocator, i, j);
                        var historyObj: *HistoryObj = &historyObjAddr.ptr[0];

                        historyObj.values.set(historyObj.count, num);
                        historyObj.count += 1;

                        historyObj.values.resize(historyObjAddr.ptr[0].count) catch print("failed to resize \n", .{});

                        // insert the pair into the map
                        const newKey = try indexToString(i, j);
                        try historyMap.put(newKey, historyObjAddr);

                        // insert the pair in hisory
                        try list.append(.{ .i = i, .j = j });

                        break;
                    }
                }
                if (backtrack) {

                    // pop the last item from history
                    // remove entry from hashmap
                    // change the value of i & j
                    sudokuGrid[i][j] = 0;
                    const last = list.pop();

                    var eItem = historyMap.get(key);
                    if (eItem) |eitem| {
                        allocator.free(eitem);
                    }
                    _ = historyMap.remove(key);
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

// checks if num
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
