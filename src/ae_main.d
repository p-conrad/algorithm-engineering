import std.stdio;
import fibonacci;
import meter;
import measurement;

void timeMeasurements(int option) {
	if (option == 0) {
		auto measurement = new FibMeasurement(new WallMeter());
		measurement.doMeasurement();
	}
	else if (option == 1) {
		auto measurement = new SortMeasurement(new WallMeter());
		measurement.measureForAll();
	}
}

void countCycles(int option) {
	if (option == 0) {
		auto measurement = new FibMeasurement(new CycleMeter());
		measurement.doMeasurement();
	}
	else if (option == 1) {
		auto measurement = new SortMeasurement(new CycleMeter());
		measurement.measureForAll();
	}
}

int getUserInput() {
	int option;
	writeln("***** MAIN *****");
	writeln("(1) Do a wall time measurement of the fibonacci algorithms");
	writeln("(2) Do a cycle count measurement of the fibonacci algorithms");
	writeln("(3) Do a wall time measurement of the sorting algorithms");
	writeln("(4) Do a cycle count measurement of the sorting algorithms");
	writeln("(5) Quit and do nothing");
	write("Selection: ");
	readf("%s", &option);

	return option;
}

void main() {
	int option = getUserInput();

	switch (option) {
		case 1:
			timeMeasurements(0);
			break;
		case 2:
			countCycles(0);
			break;
		case 3:
			timeMeasurements(1);
			break;
		case 4:
			countCycles(1);
			break;
		case 5:
		default:
			{ }
	}
}
