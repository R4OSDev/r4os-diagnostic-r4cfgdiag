const r4os = @import("r4os");
const r4std = @import("r4std");

const missing_path = "C:\\R4OS\\CONFIG\\R4CFGM.R4S";
const broken_path = "C:\\R4OS\\CONFIG\\R4CFGB.R4S";
const central_path = "C:\\R4OS\\CONFIG\\R4CFG.R4S";
const document_path = "C:\\R4OS\\CONFIG\\R4CFGDOC.R4S";
const local_path = "C:\\DIAG\\R4CFGD.R4S";

pub fn r4_app_main(r4_app: *r4os.App) i32 {
    if (!r4std.init(r4_app.startContext())) return r4os.abi.err_no_group;
    var ctx = r4_app.system();
    var ok = true;

    ctx.println("R4CFGD");
    ok = checkMissing(&ctx) and ok;
    ok = checkBroken(&ctx) and ok;
    ok = checkWriteRead(&ctx, central_path, "central") and ok;
    ok = checkWriteRead(&ctx, local_path, "local") and ok;
    ok = checkDocumentSave(&ctx) and ok;

    ctx.print("R4CFGD result: ");
    ctx.println(if (ok) "OK" else "FAILED");
    return if (ok) 0 else 1;
}

fn checkMissing(ctx: *r4os.r4sys.Context) bool {
    _ = ctx.fileDelete(missing_path);
    var title: [32]u8 = undefined;
    const result = r4std.config.readString(ctx, missing_path, "TITLE", "Default", title[0..]);
    const ok = result == r4std.config.result_defaulted and equals(spanZ(title[0..]), "Default");
    ctx.print("missing/default: ");
    ctx.println(if (ok) "OK" else "FAILED");
    return ok;
}

fn checkBroken(ctx: *r4os.r4sys.Context) bool {
    _ = ctx.fileWrite(broken_path, "BROKEN\r\nCOUNT=NaN\r\nFLAG=maybe\r\nTITLE=Kept\r\n");

    var title: [32]u8 = undefined;
    var count: u32 = 0;
    var flag = false;
    const title_result = r4std.config.readString(ctx, broken_path, "TITLE", "Default", title[0..]);
    const count_result = r4std.config.readU32(ctx, broken_path, "COUNT", 9, &count);
    const flag_result = r4std.config.readBool(ctx, broken_path, "FLAG", true, &flag);

    const ok = title_result == r4std.config.result_ok and
        equals(spanZ(title[0..]), "Kept") and
        count_result == r4std.config.result_defaulted and
        count == 9 and
        flag_result == r4std.config.result_defaulted and
        flag;
    ctx.print("broken/default: ");
    ctx.println(if (ok) "OK" else "FAILED");
    return ok;
}

fn checkWriteRead(ctx: *r4os.r4sys.Context, path: [*:0]const u8, label: []const u8) bool {
    _ = ctx.fileDelete(path);

    const title_result = r4std.config.writeString(ctx, path, "TITLE", label);
    const bool_result = r4std.config.writeBool(ctx, path, "ENABLED", true);
    const u32_result = r4std.config.writeU32(ctx, path, "COUNT", 42);
    const i32_result = r4std.config.writeI32(ctx, path, "OFFSET", -4);
    const rgb_result = r4std.config.writeRgb24(ctx, path, "COLOR", 0x008080);

    var title: [32]u8 = undefined;
    var enabled = false;
    var count: u32 = 0;
    var offset: i32 = 0;
    var color: u32 = 0;
    const read_title = r4std.config.readString(ctx, path, "TITLE", "missing", title[0..]);
    const read_enabled = r4std.config.readBool(ctx, path, "ENABLED", false, &enabled);
    const read_count = r4std.config.readU32(ctx, path, "COUNT", 0, &count);
    const read_offset = r4std.config.readI32(ctx, path, "OFFSET", 0, &offset);
    const read_color = r4std.config.readRgb24(ctx, path, "COLOR", 0, &color);

    var file: [512]u8 = undefined;
    const file_len = ctx.fileRead(path, file[0..]);
    const canonical = file_len > 0 and startsWith(file[0..@intCast(file_len)], r4std.settings.utf8_bom);
    const ok = title_result >= 0 and
        bool_result == r4std.config.result_ok and
        u32_result == r4std.config.result_ok and
        i32_result == r4std.config.result_ok and
        rgb_result == r4std.config.result_ok and
        read_title == r4std.config.result_ok and
        read_enabled == r4std.config.result_ok and
        read_count == r4std.config.result_ok and
        read_offset == r4std.config.result_ok and
        read_color == r4std.config.result_ok and
        equals(spanZ(title[0..]), label) and
        enabled and
        count == 42 and
        offset == -4 and
        color == 0x008080 and
        canonical and
        !r4std.config.hasDocumentSaveLeftovers(ctx, path);

    ctx.print("write/read ");
    ctx.write(label);
    ctx.print(": ");
    ctx.println(if (ok) "OK" else "FAILED");
    return ok;
}

fn checkDocumentSave(ctx: *r4os.r4sys.Context) bool {
    _ = ctx.fileDelete(document_path);

    var first: [192]u8 = .{0} ** 192;
    var writer = r4std.settings.Writer.init(first[0..]);
    writer.writeHeader("R4CFGDOC");
    writer.writePair("MODE", "FIRST");
    const first_doc = writer.bytes();

    var second: [192]u8 = .{0} ** 192;
    var second_writer = r4std.settings.Writer.init(second[0..]);
    second_writer.writeHeader("R4CFGDOC");
    second_writer.writePair("MODE", "SECOND");
    const second_doc = second_writer.bytes();

    const created = r4std.config.saveDocument(ctx, document_path, first_doc);
    const updated = r4std.config.saveDocument(ctx, document_path, second_doc);
    const rejected = r4std.config.saveDocument(ctx, document_path, "BROKEN\r\nMODE=BAD\r\n");

    var file: [256]u8 = undefined;
    const file_len = ctx.fileRead(document_path, file[0..]);
    const bytes = if (file_len > 0) file[0..@intCast(file_len)] else file[0..0];
    const ok = created == r4std.config.result_created and
        updated == r4std.config.result_ok and
        rejected == r4std.config.error_invalid_value and
        startsWith(bytes, r4std.settings.utf8_bom) and
        contains(bytes, "SCHEMA=R4CFGDOC") and
        contains(bytes, "MODE=SECOND") and
        !contains(bytes, "MODE=BAD") and
        !r4std.config.hasDocumentSaveLeftovers(ctx, document_path);

    ctx.print("document/save: ");
    ctx.println(if (ok) "OK" else "FAILED");
    return ok;
}

fn spanZ(buf: []const u8) []const u8 {
    var end: usize = 0;
    while (end < buf.len and buf[end] != 0) : (end += 1) {}
    return buf[0..end];
}

fn equals(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (a[i] != b[i]) return false;
    }
    return true;
}

fn startsWith(value: []const u8, prefix: []const u8) bool {
    if (value.len < prefix.len) return false;
    return equals(value[0..prefix.len], prefix);
}

fn contains(value: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (value.len < needle.len) return false;
    var index: usize = 0;
    while (index + needle.len <= value.len) : (index += 1) {
        if (equals(value[index .. index + needle.len], needle)) return true;
    }
    return false;
}
