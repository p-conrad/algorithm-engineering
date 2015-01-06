module meter;

enum MeterType {WALL, CYCLES, UNDEFINED}
class Meter {
	public:
		this(MeterType t) { type = t; }
		abstract void startMeasurement();
		abstract void stopMeasurement();
		abstract long getResult();
		MeterType getType() { return type; }
		// determine whether a given meter is a wall time meter in a
		// more convenient way. This comes in useful since we need to
		// check this very often.
		bool isWall() { return (type == MeterType.WALL); }
	protected:
		MeterType type = MeterType.UNDEFINED;
}

class WallMeter : Meter {
	import std.datetime;

	public:
		this() { super(MeterType.WALL); }

		override void startMeasurement() {
			timer.reset();
			timer.start();
		}
		
		override void stopMeasurement() {
			timer.stop();
		}

		override long getResult() {
			return timer.peek().nsecs();
		}
	private:
		StopWatch timer;
}

class CycleMeter : Meter {
	public:
		this() { super(MeterType.CYCLES); }

		override void startMeasurement() {
			uint hi, lo;
			asm {
				cpuid		;
				rdtsc		;
				mov hi,EDX	;
				mov lo,EAX	;
			}
			start = ((cast(ulong) hi << 32) | lo);
		}

		override void stopMeasurement() {
			uint hi, lo;
			asm {
				rdtsc		;
				mov hi,EDX	;
				mov lo,EAX	;
				cpuid		;
			}
			stop = ((cast(ulong) hi << 32) | lo);
		}

		override long getResult() {
			return (stop - start);
		}

	private:
		ulong start, stop;
}
