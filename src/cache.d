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

// output the memory mountain by accessing an array of
// various sizes with varying strides
void memoryMountain() {
	import meter;
	import file;

	const uint size_max = 1 << 26;	// 64 MB
	const uint size_min = 1 << 6;	// 64 B
	const uint stride_max = 32;

	auto data = new uint[](size_max / uint.sizeof);

	// To prevent the compiler from possibly optimizing the loop in arrSum
	// away, we initialize the array with 1 and obtain the calculated
	// result from the function. This result equals the access count to
	// the array, and will later be used to determine the number of bytes
	// read
	data[] = 1;
	uint accessCount;

	auto cm = new CycleMeter();
	auto outfile = openFile("memoryMountain.csv", "measurements", true);
	outfile.writeln("size [B],stride,throughput [MB/s]");
	ulong freq = cpufreq();

	for (uint size = size_max; size >= size_min; size -= (size / 10)) {
		for (uint stride = 1; stride <= stride_max; stride++) {
			auto array = data[0 .. (size / uint.sizeof)];
			// warm-up
			arrSum(array, stride, accessCount);

			cm.startMeasurement();
			arrSum(array, stride, accessCount);
			cm.stopMeasurement();

			// memory throughput in B/s
			double throughput = ((array.length * uint.sizeof) / accessCount)
				* (freq / cm.getResult());
			// convert to MB/s and write
			throughput /= (1024 * 1024);
			outfile.writefln("%s,%s,%.2f", array.length * uint.sizeof, stride, throughput);
		}
	}
	outfile.close();
}

void arrSum(in uint[] data, in uint stride, out uint count) {
	uint result;
	for (uint i = 0; i < data.length; i += stride)
		result += data[i];
	count = result;
}

// determine the CPU frequency by measuring cycles over a set
// amount of time
ulong cpufreq() {
	import meter;
	import core.thread;

	auto cm = new CycleMeter();
	cm.startMeasurement();
	Thread.sleep(dur!("msecs")(500));
	cm.stopMeasurement();
	return 2 * cm.getResult();
}
