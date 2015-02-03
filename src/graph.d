module graph;

// Vertices are identified given an int value. Define symbolic alias
// for them to gain some readability. This will also enable us to easily
// switch to another identifier.
alias vert = int;

// A graph will be represented by an adjacency list.
// An adjacency list is stored as an associative array, where the key
// equals the identifier of a vertex in a graph, containing another
// associatve array of adjacent nodes. The value then equals the weight
// of the edge.
// A simple array would not be sufficient here, because it would, for
// instance, not allow us to generate subsets of a given graph.
alias Graph = int[vert][vert];

// A tuple representing an edge of the graph. This enables us to store
// edges of the graph outside an adjacency list, e.g. in a prioriy
// queue.
import std.typecons;
alias Edge = Tuple!(vert, "a", vert, "b", int, "weight");

// check whether two given vertices are connected
bool adjacent(in Graph g, in vert a, in vert b) {
	if (!((a in g) && (b in g))) return false;

	return cast(bool)(b in g[a]);
}

// insert a single vertex into a graph, not having any adjacent edges
bool insertVertex(ref Graph g, vert n) {
	if (n in g) return false;
	else {
		g[n] = g[n].init;
		return true;
	}
}

// insert a new edge into a graph. Existing edges will be overridden.
bool insertEdge(ref Graph g, vert a, vert b, int weight = 1,
		bool oneWay = false, bool insertNew = true) {
	if ((!(a in g) || !(b in g)) && !insertNew)
		return false;
	if (adjacent(g, a, b)) return false;
	
	// Just insert the vertices. Nothing will happen here if they
	// already exist
	insertVertex(g, a);
	insertVertex(g, b);

	g[a][b] = weight;
	if (!oneWay)
		g[b][a] = weight;

	return true;
}

// remove an edge from the graph
bool removeEdge(ref Graph g, vert a, vert b, bool oneWay = false) {
	if ((a in g) && (b in g)) {
		g[a].remove(b);
		if (!oneWay)
			g[b].remove(a);
		return true;
	}
	return false;
}

// deep-copy a graph and all of its elements
Graph clone(Graph g) {
	Graph clone;
	foreach (e; g.byKey())
		clone[e] = g[e].dup;
	return clone;
}

// generate an array of the edges from a given graph, ignoring
// any duplicates
Edge[] toArray(in Graph g) {
	Graph finished;
	Edge[] result;

	foreach (a; g.byKey()) {
		foreach (b; g[a].byKey()) {
			if (!adjacent(finished, a, b)) {
				result ~= Edge(a, b, g[a][b]);
				insertEdge(finished, a, b);
			}
		}
	}
	return result;
}

// construct a graph from a given set of vertices and edges
Graph construct(vert[] v, Edge[] e = []) {
	Graph result;
	
	foreach (a; v)
		insertVertex(result, a);
	foreach (a; e)
		insertEdge(result, a.expand);

	return result;
}

// Since we are working with undirected graphs, an edge (a, b) is stored
// in its adjacency list if and only if (b, a) is also contained.
// Although correct, this information is redundant, so generate a graph
// where each edge is only represented once.
Graph reduce(in Graph g) {
	Graph result;

	auto array = toArray(g);
	foreach(a; array)
		insertEdge(result, a.expand, true);

	return result;
}

// restore a previously reduced graph to its normal representation
Graph restore(in Graph g) {
	Graph result;

	foreach (a; g.byKey()) {
		foreach (b; g[a].byKey())
			insertEdge(result, a, b, g[a][b]);
	}

	return result;
}

// Find a 'safe' edge for a given subset of the graph. A safe edge is an
// edge whose insertion will not cause any cycles, and can be used for
// determining spanning trees. Safe edges are any edges of which one
// adjacent node is part of the existing subset, and the other one
// is not.
Edge safeEdge(in Graph g, in Graph sub) {
	// sub must be an actual subset of g
	foreach (v; sub.byKey())
		assert (v in g);

	Edge[] edges;

	foreach (a; sub.byKey()) {
		foreach (b; g[a].byKey()) {
			if (!(b in sub))
				edges ~= Edge(a, b, g[a][b]);
		}
	}
	
	if (edges.length > 0) {
		// there appears to be no function for just finding and returning
		// the minimum in Ranges having a search predicate, so we are using
		// minPos instead.
		import std.algorithm;
		auto min = minPos!("a.weight < b.weight")(edges)[0];
		return min;
	}
	else return Edge.init;
}

unittest {
	Graph g;

	// inserting vertices
	assert(insertVertex(g, 1));
	assert(!insertVertex(g, 1));
	assert(1 in g);
	insertVertex(g, 2);
	insertVertex(g, 3);

	// inserting edges, checking weights etc.
	assert(insertEdge(g, 1, 2, 5));
	assert(!insertEdge(g, 1, 2));
	assert(adjacent(g, 1, 2));
	assert(adjacent(g, 2, 1));
	assert(g[1][2] == 5);
	assert(g[2][1] == 5);
	insertEdge(g, 2, 3, 3);
	insertEdge(g, 3, 1, 6);

	// inserting and removing edges one-directional
	assert(removeEdge(g, 1, 2, true));
	assert(!adjacent(g, 1, 2));
	assert(adjacent(g, 2, 1));
	assert(insertEdge(g, 1, 2, 10, true));
	assert(g[1][2] == 10);
	assert(g[2][1] == 5);

	// reducing the graph
	g = reduce(g);
	assert(adjacent(g, 1, 2));
	assert(!adjacent(g, 2, 1));

	// restoring the reduced graph
	g = restore(g);
	assert(adjacent(g, 1, 2));
	assert(adjacent(g, 2, 1));

	// construct a graph using the given function
	g = construct([1, 2, 3], [Edge(1, 2, 3), Edge(2, 3, 6), Edge(3, 1, 9)]);
	assert(1 in g);
	assert(adjacent(g, 1, 2));
	assert(adjacent(g, 2, 1));
	
	// finding safe edges for g, starting from 1
	auto tree = construct([1]);
	assert(safeEdge(g, tree) == Edge(1, 2, 3));
	insertEdge(tree, safeEdge(g, tree).expand);
	assert(safeEdge(g, tree) == Edge(2, 3, 6));
	insertEdge(tree, safeEdge(g, tree).expand);
	assert(safeEdge(g, tree) == Edge.init);
}
