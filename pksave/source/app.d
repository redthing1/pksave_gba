import std.stdio;
import libspec;
import std.file;
import std.utf;

void main(string[] args) {
	writeln("PKSAVE");

	auto sav_path = args[1];
	writefln("save path: %s", sav_path);
	auto savfile_data = cast(ubyte[]) std.file.read(sav_path);

	// try loading the save
	auto loaded_save = gba_read_main_save(cast(const(ubyte)*) savfile_data);

	auto trainer = gba_get_trainer(loaded_save);
	ushort[16] trainer_name_buf;
	gba_text_to_ucs2(cast(ushort*) trainer_name_buf, cast(ubyte*) trainer.name, 7);
	writefln("trainer name: %s", cast(wchar[16]) trainer_name_buf);
}
