function move_to_json(src, dst) {
	if (!fs.stat(src))
		return 0;
	let fd = fs.open(src, "r");
	let line, lines = [];
	while (line = fd.read("line")) {
		line = trim(line);
		try { 
			line = json(line);
		} catch(c) {};
		push(lines, j ? j : line);
	}
	fd.close();
	fs.unlink(src);
	let fd = fs.open(dst, "w");
	let msg = {};
	msg[fs.basename(dst)] = lines;
	fd.write(msg);
	fd.close();
	print(lines);
}

move_to_json('/sys/fs/pstore/dmesg-ramoops-0', '/tmp/crashlog');
move_to_json('/sys/fs/pstore/console-ramoops-0', '/tmp/consolelog');
move_to_json('/sys/fs/pstore/pmsg-ramoops-0', '/tmp/pstore');
