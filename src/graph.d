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

// A tuple representing an edge of the graph. This enables us to store
// edges of the graph outside an adjacency list, e.g. in a prioriy
// queue.
import std.typecons;
alias Edge = Tuple!(vert, "a", vert, "b", int, "weight");

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

unittest {
	Graph g;

	// inserting vertices
	assert (insertVertex(g, 1));
	assert (!insertVertex(g, 1));
	assert (1 in g);
	insertVertex(g, 2);
	insertVertex(g, 3);

	// inserting edges, checking weights etc.
	assert (insertEdge(g, 1, 2, 5));
	assert (!insertEdge(g, 1, 2));
	assert (adjacent(g, 1, 2));
	assert (adjacent(g, 2, 1));
	assert (g[1][2] == 5);
	assert (g[2][1] == 5);
	insertEdge(g, 2, 3, 3);
	insertEdge(g, 3, 1, 6);

	// inserting and removing edges one-directional
	assert (removeEdge(g, 1, 2, true));
	assert (!adjacent(g, 1, 2));
	assert (adjacent(g, 2, 1));
	assert (insertEdge(g, 1, 2, 10, true));
	assert (g[1][2] == 10);
	assert (g[2][1] == 5);

	// reducing the graph
	g = reduce(g);
	assert (adjacent(g, 1, 2));
	assert (!adjacent(g, 2, 1));
}
