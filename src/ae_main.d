import std.stdio;
import fibonacci;
import meter;
import measurement;
import cache;

int getUserInput() {
	int option;
	writeln("***** MAIN *****");
	writeln("(1) Do a wall time measurement of the fibonacci algorithms");
	writeln("(2) Do a cycle count measurement of the fibonacci algorithms");
	writeln("(3) Do a wall time measurement of the sorting algorithms");
	writeln("(4) Do a cycle count measurement of the sorting algorithms");
	writeln("(5) Print information about this system's caches (Intel only)");
	writeln("(6) Output the memory mountain of this system");
	writeln("(7) Do a wall time measurement of the spanning tree algorithms");
	writeln("(8) Do a cycle count measurement of the spanning tree algorithms");
	writeln("(9) Quit and do nothing");
	write("Selection: ");
	readf("%s", &option);

	return option;
}

void main() {
	int option = getUserInput();

	switch (option) {
		case 1:
			auto measurement = new FibMeasurement(new WallMeter());
			measurement.doMeasurement();
			break;
		case 2:
			auto measurement = new FibMeasurement(new CycleMeter());
			measurement.doMeasurement();
			break;
		case 3:
			auto measurement = new SortMeasurement(new WallMeter());
			measurement.measureForAll();
			break;
		case 4:
			auto measurement = new SortMeasurement(new CycleMeter());
			measurement.measureForAll();
			break;
		case 5:
			printSystemCaches();
			break;
		case 6:
			memoryMountain();
			break;
		case 7:
			auto measurement = new MSTMeasurement(new WallMeter());
			measurement.measureAll();
			break;
		case 8:
			auto measurement = new MSTMeasurement(new CycleMeter());
			measurement.measureAll();
			break;
		case 9:
		default:
			{ }
	}
}
