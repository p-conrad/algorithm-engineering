module sort;

import std.algorithm : swap, isSorted;

// The Insertion Sort algorithm
void insertionSort(T)(T[] array) {
	for (size_t i = 1; i < array.length; i++) {
		auto j = i;
		while ((j > 0) && array[j - 1] > array[j]) {
			swap(array[j], array[j - 1]);
			j--;
		}
	}
}

unittest {
	int[] array;
	for (int i = 1; i <= 10; i++) {
		array = randomArray!int(2, 300);
		insertionSort(array);
		assert (isSorted(array));
	}
	for (int i = 1; i <= 10; i++) {
		array = randomArray!int();
		insertionSort(array);
		assert (isSorted(array));
	}
}

// The quicksort algorithm, including some modifications like picking
// a random pivot, using Insertion Sort for smaller arrays, and creating
// a 'fat partition' containing multiple pivot elements.
void quickSort(T)(T[] array) {
	import std.random : uniform;

	if (array.length <= 1) return;
	if (array.length <= 15) {
		insertionSort(array);
		return;
	}

	// pick a random pivot element and put it at the end of the array
	swap(array[uniform(0, array.length)], array[$ - 1]);
	
	// create a fat partition
	// The algorithm used is an adaptation of the algorithm taken from:
	// http://www.sorting-algorithms.com/quick-sort-3-way
	//
	// indices on the array after completing the first loop:
	// 0 .. firstLarger: elements smaller than the pivot
	// firstLarger .. firstPivot: elements larger than the pivot
	// firstPivot .. $: pivot elements
	T pivot = array[$ - 1];
	size_t i = 0;
	size_t firstLarger = 0;
	size_t firstPivot = array.length - 1;

	while (i < firstPivot) {
		if (array[i] < pivot) {
			swap(array[i], array[firstLarger]);
			i++;
			firstLarger++;
		}
		else if (array[i] == pivot) {
			firstPivot--;
			swap(array[i], array[firstPivot]);
		}
		else
			i++;
	}

	// shift the pivot elements to the center
	// first determine the length of the pivot elements
	auto lengthOfPivots = array.length - firstPivot;

	// the first pivot element will be at the index of the first larger
	// element
	firstPivot = firstLarger;
	i = firstLarger;
	size_t j = array.length - 1;
	while ((array[j] == pivot) && (array[i] != pivot) && (i <= j)) {
		swap(array[j], array[i]);
		i++;
		j--;
	}

	firstLarger += lengthOfPivots;

	quickSort(array[0 .. firstPivot]);
	quickSort(array[firstLarger .. $]);
}

unittest {
	int[] array;
	for (int i = 1; i <= 10; i++) {
		array = randomArray!int(2, 300);
		quickSort(array);
		assert (isSorted(array));
	}
	for (int i = 1; i <= 10; i++) {
		array = randomArray!int();
		quickSort(array);
		assert (isSorted(array));
	}
}

// Merge algorithm used in Mergesort
void merge(T)(T[] left, T[] right, T[] target) {
	assert (left.length + right.length == target.length);

	size_t index = 0;
	while ((left.length > 0) && (right.length > 0)) {
		if (left[0] <= right[0]) {
			target[index] = left[0];
			left = left[1 .. $];
		}
		else {
			target[index] = right[0];
			right = right[1 .. $];
		}
		index++;
	}
	while (left.length > 0) {
		target[index] = left[0];
		left = left[1 .. $];
		index++;
	}
	while (right.length > 0) {
		target[index] = right[0];
		right = right[1 .. $];
		index++;
	}
}

// The Mergesort algorithm, modified to allocate memory only once
void mergeSort(T)(T[] array, T[] target) {
	assert (array.length == target.length);

	if (array.length <= 1) return;

	target[] = array[];
	mergeSort(target[0 .. $ / 2], array[0 .. $ / 2]);
	mergeSort(target[$ / 2 .. $], array[$ / 2 .. $]);
	merge(target[0 .. $ / 2], target[$ / 2 .. $], array);
}

// helper function initializing the Mergesort algorithm
void mergeSort(T)(T[] array) {
	T[] tmp = new T[](array.length);
	mergeSort(array, tmp);
}

unittest {
	int[] array;
	for (int i = 1; i <= 10; i++) {
		array = randomArray!int(2, 300);
		mergeSort(array);
		assert (isSorted(array));
	}
	for (int i = 1; i <= 10; i++) {
		array = randomArray!int();
		mergeSort(array);
		assert (isSorted(array));
	}
}

// The Heapsort algorithm
void heapSort(T)(T[] array) {
	import heap;

	if (array.length <= 1) return;

	buildMaxHeap(array);
	assert(isHeap(array));

	for (auto i = array.length - 1; i >= 1; i--) {
		swap(array[i], array[0]);
		maxHeapify(array[0 .. i], 0);
	}
	assert(isSorted(array));
}

unittest {
	int[] array;
	for (int i = 1; i <= 10; i++) {
		array = randomArray!int(2, 300);
		heapSort(array);
		assert (isSorted(array));
	}
	for (int i = 1; i <= 10; i++) {
		array = randomArray!int();
		heapSort(array);
		assert (isSorted(array));
	}
}

version(unittest)
T[] randomArray(T)(size_t size = 1000, T maxNumber = 30000) {
	import std.random : uniform;

	auto array = new T[](size);
	foreach(ref e; array)
		e = uniform(0, maxNumber);
	return array;
}
