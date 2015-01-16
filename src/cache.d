module cache;

/* This module is used to print information about the system's caches
 * and their properties. Currently only Intel CPUs are supported.
 */

struct CacheProperties {
	string typeString() const @property {
		return [ "null", "data", "instruction", "unified" ][type];
	}
	uint type;
	uint level;
	uint self_init;
	uint full_assoc;
	uint associativity;
	uint line_part;
	uint line_size;
	uint sets;
	uint size() const @property {
		return associativity * line_part * line_size * sets;
	}
}

CacheProperties extractCacheProperties(uint n) {
	CacheProperties cp;
	uint eax, ebx, ecx;
	asm {
		mov EAX, 0x4	;
		mov ECX, n		;
		cpuid			;
		mov eax, EAX	;
		mov ebx, EBX	;
		mov ecx, ECX	;
	}
	/*
	 * EAX[5:0]: cache type as in cacheTypes
	 * EAX[7:5]: cache level
	 * EAX[8]: self initializing
	 * EAX[9]: fully associative
	 * EBX[31:22]: associativity
	 * EBX[21:12]: physical line partitions
	 * EBX[11:0]: line size
	 * ECX[31:0] number of sets
	 */
	cp.type = eax & 0b11111;
	cp.level = (eax & 0b111 << 5) >> 5;
	cp.self_init = (eax & 0b1 << 8) >> 8;
	cp.full_assoc = (eax & 0b1 << 9) >> 9;
	cp.associativity = ((ebx & 0b111111111111 << 22) >> 22) + 1;
	cp.line_part = ((ebx & 0b111111111111 << 12) >> 12) + 1;
	cp.line_size = (ebx & 0b111111111111) + 1;
	cp.sets = ecx + 1;

	return cp;
}

void printSystemCaches() {
	import std.stdio;

	uint count = 0;
	CacheProperties cp;

	do {
		cp = extractCacheProperties(count);
		if (cp.type != 0)
			writefln("Level %s %s cache, %s-way associative, %s line partitions, "
					~ "line size: %sB, number of sets: %s, total size: %sB",
				cp.level, cp.typeString, cp.associativity,
				cp.line_part, cp.line_size, cp.sets, cp.size);
		count++;
	} while (cp.type != 0);
}
