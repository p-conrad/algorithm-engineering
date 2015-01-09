import std.stdio;
import fibonacci;
import meter;
import measurement;

void timeMeasurements() {
		auto measurement = new FibMeasurement(new WallMeter());
		measurement.doMeasurement();
}

void countCycles() {
		auto measurement = new FibMeasurement(new CycleMeter());
		measurement.doMeasurement();
}

int getUserInput() {
	int option;
	writeln("***** MAIN *****");
	writeln("(1) Do a wall time measurement of the fibonacci algorithms");
	writeln("(2) Do a cycle count measurement of the fibonacci algorithms");
	writeln("(3) Quit and do nothing");
	write("Selection: ");
	readf("%s", &option);

	return option;
}

void main() {
	int option = getUserInput();

	switch (option) {
		case 1:
			timeMeasurements();
			break;
		case 2:
			countCycles();
			break;
		case 3:
		default:
			{ }
	}
}
