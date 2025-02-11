const std = @import("std");

pub fn main() !void {
    // std in
    const stdin_file = std.io.getStdIn();
    defer stdin_file.close();
    var stdin_reader = std.io.bufferedReader(stdin_file.reader());
    var stdin = stdin_reader.reader();

    // std out
    const stdout_file = std.io.getStdOut();
    defer stdout_file.close();
    var stdout_buffer = std.io.bufferedWriter(stdout_file.writer());
    var stdout = stdout_buffer.writer();

    // Input buffer.
    const max_input = 1024;
    const max_args = 10;
    var input_buffer: [max_input]u8 = undefined;

    while (true) {
        try stdout.print("$> ", .{});
        try stdout_buffer.flush();
        const input_str = try stdin.readUntilDelimiterOrEof(&input_buffer, '\n') orelse {
            try stdout.print("\n", .{});
            continue;
        };
        if (input_str.len == 0) continue;

        var args_ptrs: [max_args:null]?[*:0]u8 = undefined;
        var i: usize = 0;
        var n: usize = 0;
        var ofs: usize = 0;
        while (i <= input_str.len) : (i += 1) {
            if (input_buffer[i] == 0x29 or input_buffer[i] == 0xa) {
                if (n >= max_args) continue; // TODO: Handle variable number of arguments.
                args_ptrs[n] = @constCast(@ptrCast(&input_buffer[ofs..i :0]));
                n += 1;
                ofs = i + 1;
            }
        }
        args_ptrs[n] = null;

        const fork_pid = try std.posix.fork();

        if (fork_pid == 0) {
            // Child
            const env = [_:null]?[*:0]u8{null};
            const result = std.posix.execvpeZ(args_ptrs[0].?, &args_ptrs, &env);
            try stdout.print("ERROR: {}\n", .{result});
            return;
        } else {
            // Parent
            const wait_result = std.posix.waitpid(fork_pid, 0);
            if (wait_result.status != 0) {
                try stdout.print("Command retuned {}.\n", .{wait_result.status});
            }
        }
    }
}
