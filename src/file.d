module file;

import std.stdio;

// open a file given its name, the name of the folder, and whether to
// override it. If set to false, any existing files will be renamed
// in ascending order. Either way, a file with the given name will be
// opened.
File openFile(in char[] fileName, in char[] folderName, bool overwrite) {
	import std.file;
	import std.string : format;

	if (exists(folderName) && !isDir(folderName))
		remove(folderName);
	if (!exists(folderName))
		mkdir(folderName);

	char[] filePath = format("%s/%s", folderName, fileName).dup;

	if (exists(filePath) && !overwrite) {
		int count = 1;
		char[][] existingFiles;

		char[] fileToRename = filePath.dup;
		char[] nextFile;
		existingFiles ~= fileToRename;

		// put all existing file paths into the array
		// The last inserted element will be a non-existing file which will
		// be used as the first 'target' below.
		do {
			import std.conv : to;
			nextFile = format("%s/%s_%s", folderName, to!(char[])(count), fileName).dup;
			existingFiles ~= nextFile;
			count++;
		} while (exists(nextFile));

		char[] target = existingFiles[$ - 1];
		existingFiles.length -= 1;
		do {
			char[] source = existingFiles[$ - 1];
			existingFiles.length -= 1;
			rename(source, target);
			target = source;
		} while (existingFiles.length > 0);
	}

	return File(filePath.idup, "w");
}
