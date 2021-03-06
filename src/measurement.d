module measurement;

import meter;
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
			import std.math : sqrt;
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
				import file;
				auto outfile = openFile(getFilename(outputs[opIndex]), OUTPUT_FOLDER,
						FILE_OVERWRITE);
				writeFileHeader(outfile);

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

					writeResults(outfile, n);
				}
				outfile.close();
			}
		}

	protected:
		Meter meter;
		double[] data;
		char[][] outputs;

		// round the values
		double roundToPrecision(double value) {
			import std.math : round;
			int factor = 10 ^^ PRECISION;
			return (round(value * factor) / factor);
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
			import std.array : split;

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
			import std.conv : to;
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
				import std.algorithm : sort;
				meter.startMeasurement();
				sort(array);
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
			import std.algorithm : reverse;
			reverse(toSort);
			a = Arrangement.DESC;
			setNames();
		}

		import std.random : uniform;
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
		import std.conv : to;
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

class MSTMeasurement : Measurement {
	import graph;
	public:
		this(Meter m) {
			super(m);
			MEASURE_UPTO = 500;
			currentDegree = 1;
			outputs.length = baseNames.length;
			init();
		}
		// returns a single measurement where n equals the number of vertices.
		override double singleMeasurement(int n, size_t opIndex) {
			for (; vCount <= n; insertNew(currentDegree)) {}
			if (opIndex == 0) {
				meter.startMeasurement();
				genericMST!()(g);
				meter.stopMeasurement();
			}
			else return -1;
			return meter.getResult();
		}

		// a function used to measure for all degrees at once
		void measureAll() {
			for (uint i = 1; i <= MAX_DEGREE; i++) {
				currentDegree = i;
				init();
				doMeasurement();
			}
		}

	private:
		import std.conv : to;
		Graph!() g;
		char[][] baseNames = to!(char[][])([ "genericMST" ]);
		uint vCount;
		uint eCount;
		uint currentDegree;

		uint MAX_WEIGHT = 250;
		uint MAX_DEGREE = 6;

		uint maxEdges() {
			if (vCount == 0) return 0;
			return (vCount * (vCount - 1) / 2);
		}

		void init() {
			import std.string : format;
			g = g.init;
			vCount = 0;
			eCount = 0;
			outputs.length = 0;
			foreach (e; baseNames)
				outputs ~= e ~ format("_d%s", currentDegree).dup;
		}

		void insertNew(uint degree) {
			import std.random : uniform;
			vCount++;
			insertVertex!()(g, vCount);
			for (uint i = 1; i <= degree; i++) {
				if (eCount == maxEdges()) break;
				// try to insert a new edge to a randomly chosen vertex
				while (!insertEdge!()(g, vCount, uniform(1, vCount),
							uniform(1, MAX_WEIGHT))) {}
				eCount ++;
			}
		}
}
