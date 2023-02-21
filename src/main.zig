const std = @import("std");

const Op = enum {
    add,
    sub,
    mul,
    div,
    mod,
    band,
    bor,
    bxor,
    shl,
    shr,
    lt,
    gt,
    eq,
};

const Node = union(enum) {
    t,
    num: u32,
    bin: struct { op: Op, l: *Node, r: *Node },
};

const Parser = struct {
    src: []const u8,
    pos: usize = 0,
    alloc: std.mem.Allocator,

    fn peek(self: *Parser) ?u8 {
        while (self.pos < self.src.len and self.src[self.pos] == ' ') self.pos += 1;
        return if (self.pos < self.src.len) self.src[self.pos] else null;
    }

    fn node(self: *Parser, n: Node) !*Node {
        const p = try self.alloc.create(Node);
        p.* = n;
        return p;
    }

    fn primary(self: *Parser) anyerror!*Node {
        const c = self.peek() orelse return error.UnexpectedEnd;
        if (c == '(') {
            self.pos += 1;
            const e = try self.expr(0);
            if (self.peek() != ')') return error.ExpectedParen;
            self.pos += 1;
            return e;
        }
        if (c == 't') {
            self.pos += 1;
            return self.node(.t);
        }
        var n: u32 = 0;
        const start = self.pos;
        while (self.pos < self.src.len and std.ascii.isDigit(self.src[self.pos])) : (self.pos += 1) {
            n = n * 10 + (self.src[self.pos] - '0');
        }
        if (self.pos == start) return error.BadToken;
        return self.node(.{ .num = n });
    }

    // precedence climbing; higher binds tighter
    fn prec(op: Op) u8 {
        return switch (op) {
            .bor => 1,
            .bxor => 2,
            .band => 3,
            .eq => 4,
            .lt, .gt => 5,
            .shl, .shr => 6,
            .add, .sub => 7,
            .mul, .div, .mod => 8,
        };
    }

    fn binop(self: *Parser) ?Op {
        const c = self.peek() orelse return null;
        const d: u8 = if (self.pos + 1 < self.src.len) self.src[self.pos + 1] else 0;
        const op: Op = switch (c) {
            '+' => .add,
            '-' => .sub,
            '*' => .mul,
            '/' => .div,
            '%' => .mod,
            '=' => if (d == '=') .eq else return null,
            '<' => if (d == '<') .shl else .lt,
            '>' => if (d == '>') .shr else .gt,
            '&' => .band,
            '|' => .bor,
            '^' => .bxor,
            else => return null,
        };
        self.pos += switch (op) {
            .shl, .shr => @as(usize, 2),
            .eq => @as(usize, 2),
            else => 1,
        };
        return op;
    }

    fn expr(self: *Parser, min: u8) anyerror!*Node {
        var l = try self.primary();
        while (true) {
            const save = self.pos;
            const op = self.binop() orelse break;
            if (prec(op) < min) {
                self.pos = save;
                break;
            }
            const r = try self.expr(prec(op) + 1);
            l = try self.node(.{ .bin = .{ .op = op, .l = l, .r = r } });
        }
        return l;
    }
};

fn eval(n: *const Node, t: u32) u32 {
    return switch (n.*) {
        .t => t,
        .num => |v| v,
        .bin => |b| blk: {
            const l = eval(b.l, t);
            const r = eval(b.r, t);
            break :blk switch (b.op) {
                .add => l +% r,
                .sub => l -% r,
                .mul => l *% r,
                .div => if (r == 0) 0 else l / r,
                .mod => if (r == 0) 0 else l % r,
                .band => l & r,
                .bor => l | r,
                .bxor => l ^ r,
                .shl => l << @truncate(u5, r),
                .shr => l >> @truncate(u5, r),
                .lt => @boolToInt(l < r),
                .gt => @boolToInt(l > r),
                .eq => @boolToInt(l == r),
            };
        },
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    if (args.len < 4) {
        std.debug.print("usage: bytebeat FORMULA RATE SECONDS\n", .{});
        std.process.exit(2);
    }
    const formula = args[1];
    const rate = try std.fmt.parseInt(u32, args[2], 10);
    const seconds = try std.fmt.parseInt(u32, args[3], 10);
    var p = Parser{ .src = formula, .alloc = alloc };
    const root = try p.expr(0);
    const out = std.io.getStdOut().writer();
    var t: u32 = 0;
    while (t < rate * seconds) : (t += 1) {
        const s: u8 = @truncate(u8, eval(root, t));
        try out.writeByte(s);
    }
}
