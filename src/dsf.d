module dsf;

// a disjoint set forest, including union by rank and path compression
// heuristicts to optimize time consumption
class DisjointSetForest(T) {
	public:
		// constructor, initializing the forest out of a given set of
		// elements, where each element belongs to its own set.
		this(T[] elements) {
			foreach (e; elements) {
				parentOf[e] = e;
				rankOf[e] = 0;
			}
		}
	
		// link the representative of one set to the representative of
		// another, i.e. make them the same set
		void link(T x, T y) {
			assert (parentOf[x] == x);
			assert (parentOf[y] == y);

			if (x == y) return;

			if (rankOf[x] > rankOf[y])
				parentOf[y] = x;
			else 
				parentOf[x] = y;
			if (rankOf[x] == rankOf[y])
				rankOf[y] += 1;
		}

		// unite the sets belonging to two given elements
		void unite(T x, T y) {
			link(findSet(x), findSet(y));
		}

		// find the representative of a given element, compressing the
		// paths along all the parents
		T findSet(T x) {
			if (x != parentOf[x])
				parentOf[x] = findSet(parentOf[x]);
			return parentOf[x];
		}

	private:
		// a set holding the parents of each node
		T[T] parentOf;
		// the rank of each node, i.e. an upper bound for its height
		// within the tree
		int[T] rankOf;
}

unittest {
	auto forest = new DisjointSetForest!int([1, 2, 3, 4, 5, 6]);
	assert (forest.findSet(1) == 1);
	forest.unite(1, 2);
	forest.unite(3, 4);
	forest.unite(5, 6);
	assert (forest.findSet(2) == forest.findSet(1));
	forest.unite(1, 3);
	assert (forest.findSet(3) == forest.findSet(1));
}
