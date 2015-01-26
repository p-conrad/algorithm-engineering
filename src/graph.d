// Vertices are identified given an int value. Define symbolic alias
// for them to gain some readability. This will also enable us to easily
// switch to another identifier.
alias vert = int;

// List element of an adjacency list containing the connecting node
// and the weight of the connecting edge. 
import std.typecons;
alias AdjElement = Tuple!(vert, "vertex", int, "weight");

// A graph will be represented by an adjacency list.
// An adjacency list is stored as an associative array, where the key
// equals the identifier of a vertex in a graph.
// A simple array would not be sufficient, because it would, for instance,
// not allow us to generate subsets of a given graph.
alias Graph = AdjElement[][vert];

// check whether two given vertices are connected
bool adjacent(in Graph g, in vert a, in vert b) {
	if (!((a in g) && (b in g))) return false;

	import std.algorithm : find;
	return find!("a.vertex == b")(g[a], b).length > 0;
}

// insert a single vertex into a graph, not having any adjacent edges
bool insertVertex(ref Graph g, vert n) {
	if (n in g) return false;
	else {
		g[n] = [];
		return true;
	}
}

// insert a new edge into a graph
bool insertEdge(ref Graph g, vert source, vert target, int weight = 1,
		bool insertNew = false) {
	if ((!(source in g) || !(target in g)) && !insertNew)
		return false;
	if (adjacent(g, source, target)) return false;
	
	// Just insert the vertices. Nothing will happen here if they
	// already exist
	insertVertex(g, source);
	insertVertex(g, target);

	g[source] ~= AdjElement(target, weight);
	g[target] ~= AdjElement(source, weight);
	return true;
}

unittest {
	Graph g;
	assert (insertVertex(g, 1));
	assert (!insertVertex(g, 1));
	
	insertVertex(g, 5);
	assert (insertEdge(g, 1, 5, 3));
	assert (adjacent(g, 1, 5));
	assert (!insertEdge(g, 1, 5));
}
