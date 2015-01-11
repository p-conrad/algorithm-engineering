module measurement;

import meter;
import std.math;
import std.stdio;

class Measurement {
	public:
		this (Meter m) { meter = m; }
		
		// statistical functions
		double min() {
			auto min = data[0];
			foreach (e; data) {
				if (e < min)
					min = e;
			}
			return min;
		}

		double max() {
			auto max = data[0];
			foreach (e; data) {
				if (e > max)
					max = e;
			}
			return max;
		}

		double sd() {
			double squaredDiffSum = 0;

			foreach (e; data)
				squaredDiffSum += (mean() - e) ^^ 2;

			return roundToPrecision(sqrt(squaredDiffSum / mean()));
		}
		double mean() {
			double sum = 0;

			foreach (e; data)
				sum += e;
			
			return roundToPrecision(sum / MEASURE_COUNT);
		}

		// take a single measurement for a given n and return its result
		// This needs to be implemented by its subclasses.
		abstract double singleMeasurement(int n, size_t opIndex);

		// do a complete measurement using the given meter
		void doMeasurement() {
			assert (outputs.length != 0);

			int iterations;

			for (size_t opIndex = 0; opIndex < outputs.length; opIndex++) {
				File file;
				openFile(file, getFilename(outputs[opIndex]));

				for (int n = 0; n <= MEASURE_UPTO; n += (n / 10 + 1)) {
					if (ITERATE && meter.isWall() && n <= ITERATE_UPTO)
						iterations = ITERATION_COUNT;
					else
						iterations = 1;

					data.length = 0;

					for (int count = 1; count <= MEASURE_COUNT; count++) {
						double result = 0;

						// iterate over a number of iterations and accumulate the
						// measurements
						for (int i = 1; i <= iterations; i++)
							result += singleMeasurement(n, opIndex);
						
						// get the average result
						result = result / iterations;

						// convert to microseconds and round if meter measures wall time
						if (meter.isWall()) {
							result = result / 1000;
							result = roundToPrecision(result);
						}

						// write data into the vector
						data ~= result;
					}

					writeResults(file, n);
				}
				file.close();
			}
		}

	protected:
		Meter meter;
		double[] data;
		char[][] outputs;

		// round the values
		double roundToPrecision(double value) {
			int factor = 10 ^^ PRECISION;
			return (round(value * factor) / factor);
		}

		// Prepare the output file. This will also implicitly write the
		// header into it.
		void openFile(ref File file, in char[] filename) {
			import std.file;
			import std.conv;
			import std.string;

			if (exists(OUTPUT_FOLDER) && !isDir(OUTPUT_FOLDER))
				remove(OUTPUT_FOLDER);
			if (!exists(OUTPUT_FOLDER))
				mkdir(OUTPUT_FOLDER);

			char[] filePath = format("%s/%s", OUTPUT_FOLDER, filename).dup;

			if (exists(filePath) && !FILE_OVERWRITE) {
				int count = 1;
				char[][] existingFiles;

				char[] fileToRename = filePath.dup;
				char[] nextFile;
				existingFiles ~= fileToRename;

				// put all existing file paths into the array
				// The last inserted element will be a non-existing file which will
				// be used as the first 'target' below.
				do {
					nextFile = format("%s/%s_%s", OUTPUT_FOLDER, to!(char[])(count), filename).dup;
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

			file.open(filePath.idup, "w");
			writeFileHeader(file);		
		}

		// get a filename consistent with the type of meter used, having an
		// extension if the output is set to CSV
		char[] getFilename(char[] basename) {
			if (meter.getType() == MeterType.WALL)
				basename ~= "_wall".dup;
			else if (meter.getType() == MeterType.CYCLES)
				basename ~= "_cycles".dup;
			else
				basename ~= "_undef".dup;

			if (OUTPUT_TO_CSV)
				basename ~= ".csv".dup;

			return basename;
		}

		// write the header into the measurements file
		void writeFileHeader(ref File file) {
			import std.array;

			if (OUTPUT_TO_CSV) {
				if (meter.isWall())
					file.writeln(HEADER_WALL);
				else
					file.writeln(HEADER_CYCLES);
			}
			else {
				string[] header;
				if (meter.isWall())
					header = split(HEADER_WALL, ',');
				else
					header = split(HEADER_CYCLES, ',');

				foreach (e; header)
					file.writef("%-10s", e);
				file.writeln();
			}
		}

		// write the current measurement results to a file
		void writeResults(File file, int n) {
			if (OUTPUT_TO_CSV) {
				file.writef("%d,%.2f,%.2f,%.2f,%.2f,", n, min(), max(), mean(), sd());
			}
			else {
				file.writef("%-10d%-10.2f%-10.2f%-10.2f%-10.2f", n, min(), max(), mean(), sd());
			}

			foreach (i, e; data)
				file.writef("%.2f%s", e, (i == data.length - 1) ? "\n" : " ");
		}

		/* Default Configuration
		 * Any of the settings below may be overridden in the
		 * derived classes constructor.
		 */

		// results will be rounded. Set the desired precision here.
		int PRECISION = 2;

		// headers to write to the file
		string HEADER_WALL = "n,min [us],max [us],mean [us],sd [us],measurements [us]";
		string HEADER_CYCLES = "n,min,max,mean,sd,measurements";

		// how much measurements to take for a single row
		int MEASURE_COUNT = 6;

		// the value up to which to take the measurements
		int MEASURE_UPTO = 50;

		// iterate function calls and return the average of all
		// measurements. This may be useful in cases where the values
		// returned by the clock turn out to be too imprecise.
		bool ITERATE = true;
		int ITERATE_UPTO = 15;
		int ITERATION_COUNT = 1500;

		// the folder used for writing the results
		char[] OUTPUT_FOLDER = "measurements".dup;

		// whether to overwrite existing output files or not
		bool FILE_OVERWRITE = false;

		// output the results in CSV format
		bool OUTPUT_TO_CSV = true;
}

class FibMeasurement : Measurement {
	import fibonacci;

	public:
		this(Meter m) {
			import std.conv;
			super(m);
			super.outputs = to!(char[][])(["fibExponential", "fibLinear",
				"fibLinear2", "fibLogarithmic", "fibClosed", "fibTable"]);
		}

		override double singleMeasurement(int n, size_t opIndex) {
			// measure the fibonacci function corresponding to the
			// given index
			if (opIndex == 0) {
				if (n >= 44) return double.nan;
				meter.startMeasurement();
				fibExponential(n);
				meter.stopMeasurement();
			}
			else if (opIndex == 1) {
				meter.startMeasurement();
				fibLinear(n);
				meter.stopMeasurement();
			}
			else if (opIndex == 2) {
				meter.startMeasurement();
				fibLinear2(n);
				meter.stopMeasurement();
			}
			else if (opIndex == 3) {
				meter.startMeasurement();
				fibLogarithmic(n);
				meter.stopMeasurement();
			}
			else if (opIndex == 4) {
				meter.startMeasurement();
				fibClosed(n);
				meter.stopMeasurement();
			}
			else if (opIndex == 5) {
				meter.startMeasurement();
				fibTable(n);
				meter.stopMeasurement();
			}
			else return -1;
			return meter.getResult();
		}
}

class SortMeasurement : Measurement {
	import sort;
	import std.conv;
	import std.algorithm;
	import std.random;

	public:
		enum Arrangement { ASC, DESC, RAND, REP }
		this (Meter m) { 
			super(m);
			toSort = new int[](VECTOR_SIZE);
			setAscending();

			// some custom configuration
			super.MEASURE_UPTO = VECTOR_SIZE;
			super.ITERATE_UPTO = 5;
		}

		override double singleMeasurement(int n, size_t opIndex) {
			// generate a subset of toSort holding n elements
			auto array = toSort[0 .. n].dup;

			if (opIndex == 0) {
				meter.startMeasurement();
				insertionSort(array);
				meter.stopMeasurement();
			}
			else if (opIndex == 1) {
				meter.startMeasurement();
				quickSort(array);
				meter.stopMeasurement();
			}
			else if (opIndex == 2) {
				meter.startMeasurement();
				mergeSort(array);
				meter.stopMeasurement();
			}
			else if (opIndex == 3) {
				meter.startMeasurement();
				heapSort(array);
				meter.stopMeasurement();
			}
			else if (opIndex == 4) {
				meter.startMeasurement();
				array.sort;
				meter.stopMeasurement();
			}
			else return -1;
			return meter.getResult();
		}

		// cycle through all arrangement types and take measurements
		void measureForAll() {
			setAscending();
			doMeasurement();
			setDescending();
			doMeasurement();
			setRandom();
			doMeasurement();
			setRepeated();
			doMeasurement();
		}

		// functions for changing the arrangement of the input vector
		void setAscending() {
			foreach (i, ref e; toSort)
				e = cast(int) i;
			a = Arrangement.ASC;
			setNames();
		}

		void setDescending() {
			foreach (i, ref e; toSort)
				e = cast(int) i;
			toSort.reverse;
			a = Arrangement.DESC;
			setNames();
		}

		void setRandom() {
			foreach (ref e; toSort)
				e = uniform(0, MAX_RAND);
			a = Arrangement.RAND;
			setNames();
		}

		void setRepeated() {
			foreach (i, ref e; toSort) {
				int random;
				if (i % REP_COUNT == 0)
					random = uniform(0, MAX_RAND);
				e = random;
			}
			a = Arrangement.REP;
			setNames();
		}

	private:
		Arrangement a;
		int[] toSort;
		char[][] baseNames = to!(char[][])(["insertionSort", "quickSort",
				"mergeSort", "heapSort", "phobosSort"]);
		
		void setNames() {
			outputs.length = 0;
			foreach (e; baseNames) {
				if (a == Arrangement.ASC)
					outputs ~= (e ~ "_asc");
				else if (a == Arrangement.DESC) 
					outputs ~= (e ~ "_desc");
				else if (a == Arrangement.RAND)
					outputs ~= (e ~ "_rand");
				else if (a == Arrangement.REP)
					outputs ~= (e ~ "_rep");
				else
					outputs ~= (e ~ "_undef");
			}
		}

		// some configuration
		int VECTOR_SIZE = 1000;
		int REP_COUNT = 20;
		int MAX_RAND = 30000;
}
