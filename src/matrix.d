module matrix;

import std.exception : enforce;
import std.string : format;

class Matrix(T) {
	public:
		// constrctors initializing an empty matrix of given dimensions
		this(size_t rows, size_t cols) { setElements(new T[][](rows, cols)); }
		this(size_t size) { this(size, size); }
		this() { this(1); }

		// constructor initializing a matrix with its elements
		this(T[][] elements) { setElements(elements); }

		// getter functions returning a matrix' dimensions
		inout(size_t) getRows() inout { return elements.length; }
		inout(size_t) getCols() inout { return elements[0].length; }

		// check whether a matrix is square
		bool isSquareMatrix() { return getCols() == getRows(); }

		// getter function returning a deep copy of the elements
		T[][] getElements() {
			auto ret = new T[][](elements.length);
			foreach(i, ref e; ret)
				e = elements[i].dup;
			return ret;
		}

		// getter function returning a shallow copy of the elements
		T[][] getElementsRef() { return elements.dup; }

		// clone function returning a deep copy of a matrix instance
		Matrix!T clone() {
			return new Matrix!T(getElements());
		}

		// Set and get elements at a given positions within the matrix.
		inout(T) getElementAt(size_t x, size_t y) inout { return elements[x][y]; }
		void setElementAt(size_t x, size_t y, T data) { elements[x][y] = data; }

		// operator simplifying access to the matrix elements
		inout(T) opIndex(size_t x, size_t y) inout { return getElementAt(x, y); }

		// Set elements of the matrix. The dimensions will be assumed to be
		// the length of the passed array and the length of its first member
		// implicitly. A check will be performed whether the given data
		// forms an actual matrix (i.e. all arrays are the same size).
		void setElements(T[][] data) {
			size_t cols = data[0].length;
			size_t rows = data.length;

			enforce((cols != 0) && (rows != 0), format(
				"Matrix dimensions cannot be zero. Size of passed elements was: %sx%s", rows, cols));

			foreach(i, e; data) {
				enforce(e.length == cols, format(
					"Index %s of passed data: Column size does not match. Expected: %s, actual: %s",
					i, cols, e.length));
			}
			elements = data;
		}

		// print the matrix
		void print() {
			import std.stdio;
			writeln(elements);
		}

		// fill the matrix with zeroes
		void fillWithZeroes() {
			foreach(ref e; elements)
				e[] = 0;
		}

		// transform the matrix into an identity matrix
		void identityMatrix() {
			enforce(isSquareMatrix(),
					"Cannot transform non-square matrix to identity matrix.");

			fillWithZeroes();
			foreach(i, ref e; elements)
				e[i] = 1;
		}

		// multiply with another matrix
		Matrix!T multiply(const Matrix!T other) {
			enforce(this.getCols() == other.getRows(), format(
				"Cannot multiply a %sx%s matrix with a %sx%s matrix (rows size must match column size)",
				this.getRows(), this,getCols(), other.getRows(), other.getCols()));

			auto result = new Matrix!T(this.getRows(), other.getCols());
				for (size_t i = 0; i < result.getRows(); i++) {
					for (size_t j = 0; j < result.getCols(); j++) {
						for (size_t k = 0; k < this.getCols(); k++) {
							result.setElementAt(i, j, (result[i, j] + this[i, k] * other[k, j]));
						}
					}
				}
			return result;
		}

		// multiply with another matrix using an array as argument
		Matrix!T multiply(T[][] other) { return multiply(new Matrix!T(other)); }

		// exponentiate by squaring
		void exponentiate(uint n) {
			enforce(isSquareMatrix(), format(
				"Matrix of size %sx%s cannote be exponentiated (must be square)",
				getCols(), getRows()));
			
			auto copy = this.clone();
			identityMatrix();

			while (n > 0) {
				if (n % 2 == 1)
					this.elements = this.multiply(copy).getElementsRef();
				n /= 2;
				copy = copy.multiply(copy);
			}
			assert(isSquareMatrix());
		}
		
	private:
		T[][] elements;
}

unittest {
	import std.exception : assertThrown;
	// basic operations: creating a matrix, setting its elements
	auto mat = new Matrix!int(4, 2);
	assert(mat.getRows() == 4);
	assert(mat.getCols() == 2);
	mat.setElementAt(0, 0, 1);
	assert(mat[0, 0] == 1);

	// attempting to create a deformed matrix throws an exception
	assertThrown(mat.setElements([[0, 1], [2]]));
	assertThrown(mat.setElements([[], []]));

	// multiplication
	mat.setElements([[1, 2, 3], [3, 4, 5]]);
	auto mult = mat.multiply([[1, 2], [2, 3], [3, 4]]);
	assert(mult.getRows() == 2);
	assert(mult.getCols() == 2);
	assert(mult[0, 0] == 14);
	assert(mult[0, 1] == 20);
	assert(mult[1, 0] == 26);
	assert(mult[1, 1] == 38);

	// filling with zeroes
	mat.fillWithZeroes();
	assert(mat[0, 0] == 0);
	assert(mat[1, 2] == 0);

	// transforming into the identity matrix
	assertThrown(mat.identityMatrix());
	mat.setElements([[1, 2, 3], [3, 4, 5], [5, 6, 7]]);
	mat.identityMatrix();
	assert(mat[0, 0] == 1);
	assert(mat[1, 1] == 1);
	assert(mat[2, 2] == 1);
	assert(mat[0, 1] == 0);
	assert(mat[1, 0] == 0);

	// exponentiation
	mat.setElements([[1], [2]]);
	assertThrown(mat.exponentiate(4));
	mat.setElements([[1, 2], [3, 4]]);
	mat.exponentiate(4);
	assert(mat[0, 0] == 199);
	assert(mat[0, 1] == 290);
	assert(mat[1, 0] == 435);
	assert(mat[1, 1] == 634);
}
