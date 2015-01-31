// Vertices are identified given an int value. Define symbolic alias
// for them to gain some readability. This will also enable us to easily
// switch to another identifier.
alias vert = int;

// A graph will be represented by an adjacency list.
// An adjacency list is stored as an associative array, where the key
// equals the identifier of a vertex in a graph, containing another
// associatve array of adjacent nodes. The value then equals the weight
// of the edge.
// A simple array would not be sufficient, because it would, for instance,
// not allow us to generate subsets of a given graph.
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

// insert a new edge into a graph
bool insertEdge(ref Graph g, vert a, vert b, int weight = 1,
		bool insertNew = false) {
	if ((!(a in g) || !(b in g)) && !insertNew)
		return false;
	if (adjacent(g, a, b)) return false;
	
	// Just insert the vertices. Nothing will happen here if they
	// already exist
	insertVertex(g, a);
	insertVertex(g, b);

	g[a][b] = weight;
	g[b][a] = weight;

	return true;
}

unittest {
	Graph g;
	assert (insertVertex(g, 1));
	assert (!insertVertex(g, 1));
	
	insertVertex(g, 5);
	assert (insertEdge(g, 1, 5, 3));
	assert (adjacent(g, 1, 5));
	assert (adjacent(g, 5, 1));
	assert (!insertEdge(g, 1, 5));
}
