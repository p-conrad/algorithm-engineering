module fibonacci;

// The first implementation: simple, but inefficient as it runs in
// exponential time and uses exponential memory.
// This implementation follows the formal definition an can thus be seen
// as correct.
ulong fibExponential(uint n) {
	if (n <= 1) return n;
	else return fibExponential(n - 1) + fibExponential(n - 2);
}

unittest {
	assert(fibExponential(0) == 0);
	assert(fibExponential(1) == 1);
	assert(fibExponential(2) == 1);
	assert(fibExponential(3) == 2);
	assert(fibExponential(4) == 3);
	assert(fibExponential(5) == 5);
	assert(fibExponential(6) == 8);
	assert(fibExponential(7) == 13);
	assert(fibExponential(8) == 21);
	assert(fibExponential(25) == 75025);
	assert(fibExponential(30) == 832040);
	assert(fibExponential(35) == 9227465);
	assert(fibExponential(40) == 102334155);
	// not testing any higher values here as the computation would take
	// too much time
}

// A second implementation. This one runs in linear time and has linear
// memory usage.
ulong fibLinear(uint n) {
	if (n <= 1) return n;

	auto fib = new ulong[](n + 1);
	fib[0] = 0;
	fib[1] = 1;

	for (uint i = 2; i <= n; i++) {
		fib[i] = fib[i - 1] + fib[i - 2];
	}
	return fib[n];
}

unittest {
	assert(fibLinear(0) == 0);
	assert(fibLinear(1) == 1);
	assert(fibLinear(2) == 1);
	assert(fibLinear(3) == 2);
	assert(fibLinear(4) == 3);
	assert(fibLinear(5) == 5);
	assert(fibLinear(6) == 8);
	assert(fibLinear(7) == 13);
	assert(fibLinear(8) == 21);
	assert(fibLinear(25) == 75025);
	assert(fibLinear(30) == 832040);
	assert(fibLinear(35) == 9227465);
	assert(fibLinear(40) == 102334155);
	assert(fibLinear(50) == 12586269025);
	assert(fibLinear(54) == 86267571272);
	assert(fibLinear(58) == 591286729879);
	assert(fibLinear(65) == 17167680177565);
	assert(fibLinear(70) == 190392490709135);
}

// A third implementation. Since we only need the current number and its
// predecessor we can have the algorithm run in linear time and use
// constant memory.
ulong fibLinear2(uint n) {
	if (n <= 1) return n;

	ulong first = 0;
	ulong second = 1;
	ulong res;
	
	for (uint i = 2; i <= n; i++) {
		res = first + second;
		first = second;
		second = res;
	}
	return res;
}

unittest {
	assert(fibLinear2(0) == 0);
	assert(fibLinear2(1) == 1);
	assert(fibLinear2(2) == 1);
	assert(fibLinear2(3) == 2);
	assert(fibLinear2(4) == 3);
	assert(fibLinear2(5) == 5);
	assert(fibLinear2(6) == 8);
	assert(fibLinear2(7) == 13);
	assert(fibLinear2(8) == 21);
	assert(fibLinear2(25) == 75025);
	assert(fibLinear2(30) == 832040);
	assert(fibLinear2(35) == 9227465);
	assert(fibLinear2(40) == 102334155);
	assert(fibLinear2(50) == 12586269025);
	assert(fibLinear2(54) == 86267571272);
	assert(fibLinear2(58) == 591286729879);
	assert(fibLinear2(65) == 17167680177565);
	assert(fibLinear2(70) == 190392490709135);
}

// A fourth implementation. This one runs in logarithmic time and
// exponentiates a matrix to calculate the result
ulong fibLogarithmic(uint n) {
	import matrix;

	if (n <= 1) return n;
	
	auto mat = new Matrix!ulong([[0, 1], [1, 1]]);
	mat.exponentiate(n);
	mat = mat.multiply([[0], [1]]);

	return mat[0, 0];
}

unittest {
	assert(fibLogarithmic(0) == 0);
	assert(fibLogarithmic(1) == 1);
	assert(fibLogarithmic(2) == 1);
	assert(fibLogarithmic(3) == 2);
	assert(fibLogarithmic(4) == 3);
	assert(fibLogarithmic(5) == 5);
	assert(fibLogarithmic(6) == 8);
	assert(fibLogarithmic(7) == 13);
	assert(fibLogarithmic(8) == 21);
	assert(fibLogarithmic(25) == 75025);
	assert(fibLogarithmic(30) == 832040);
	assert(fibLogarithmic(35) == 9227465);
	assert(fibLogarithmic(40) == 102334155);
	assert(fibLogarithmic(50) == 12586269025);
	assert(fibLogarithmic(54) == 86267571272);
	assert(fibLogarithmic(58) == 591286729879);
	assert(fibLogarithmic(65) == 17167680177565);
	assert(fibLogarithmic(70) == 190392490709135);
}
