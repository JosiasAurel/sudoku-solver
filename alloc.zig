const std = @import("std");
const BoundedArray = std.BoundedArray(u32, 10);
const print = std.debug.print;

const Obj = struct { name: []const u8, values: BoundedArray };

pub fn main() !void {
    var GenerapPurposeAllocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = GenerapPurposeAllocator.allocator();

    var addr = try gimme_address(allocator);
    print("Obj size = {}\n", .{@sizeOf(Obj)});
    print("BoundedArray size = {}\n", .{@sizeOf(BoundedArray)});
    print("{s}\n", .{addr.ptr[0].name});
}

pub fn gimme_address(allocator: std.mem.Allocator) ![]Obj {
    var obj = Obj{ .name = "Sample", .values = try BoundedArray.init(10) };
    obj.values.set(0, 0);
    obj.values.set(1, 1);
    obj.values.set(2, 2);
    obj.values.set(3, 3);
    obj.values.set(4, 4);
    obj.values.set(5, 5);
    obj.values.set(6, 6);
    obj.values.set(7, 7);
    obj.values.set(8, 8);
    obj.values.set(9, 9);

    var mem = try allocator.alloc(Obj, 1);
    var data = [_]Obj{obj};
    std.mem.copy(Obj, mem, &data);
    return mem;
}
