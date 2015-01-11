/* Functions used for operating on heaps.
 * Implementational details are primarily taken from Cormen's
 * "Introduction to Algorithms"
 */

module heap;

size_t parent(size_t i) {
	if (i == 0) return 0;
	return ((i - 1) / 2);
}

size_t left(size_t i) {
	return (2 * i) + 1;
}

size_t right(size_t i) {
	return (2 * i) + 2;
}

bool isHeap(T)(T[] array) {
	if (array.length <= 1) return true;

	for (size_t i = array.length - 1; i < array.length; i--) {
		if (array[parent(i)] < array[i])
			return false;
	}
	return true;
}

void maxHeapify(T)(T[] array, size_t i) {
	import std.algorithm;

	auto l = left(i);
	auto r = right(i);
	auto max = i;

	if ((l < array.length) && (array[l] > array[i]))
		max = l;

	if ((r < array.length) && (array[r] > array[max]))
		max = r;

	if (max != i) {
		swap(array[i], array[max]);
		maxHeapify(array, max);
	}
}

void buildMaxHeap(T)(T[] array) {
	if (array.length <= 1) return;

	for (auto i = parent(array.length - 1); i < array.length; i--)
		maxHeapify(array, i);
}
