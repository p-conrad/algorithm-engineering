module graph;

// default data types for vertices and edges
alias vType = int;
alias eType = int;

// A graph will be represented by an adjacency list.
// An adjacency list is stored as an associative array, where the key
// equals the identifier of a vertex in a graph, containing another
// associatve array of adjacent nodes. The value then equals the weight
// of the edge.
// A simple array would not be sufficient here, because it would, for
// instance, not allow us to generate subsets of a given graph.
alias Graph(V = vType, E = eType) = E[V][V];

// A tuple representing an edge of the graph. This enables us to store
// edges of the graph outside an adjacency list, e.g. in a prioriy
// queue. The tuple is defined in a way that allows us to expand it into
// other functions, e.g. insertEdge()
import std.typecons;
alias Edge(V = vType, E = eType) = Tuple!(V, "a", V, "b", E, "weight");

// check whether two given vertices are connected
bool adjacent(V = vType, E = eType)(in Graph!(V, E) g, in V a, in V b) {
	if (!((a in g) && (b in g))) return false;

	return cast(bool)(b in g[a]);
}

// insert a single vertex into a graph, not having any adjacent edges
bool insertVertex(V = vType, E = eType)(ref Graph!(V, E) g, V n) {
	if (n in g) return false;
	else {
		g[n] = g[n].init;
		return true;
	}
}

// insert a new edge into a graph. Existing edges will be overridden.
bool insertEdge(V = vType, E = eType)(ref Graph!(V, E) g, V a, V b,
		E weight = E.init, bool oneWay = false, bool insertNew = true) {
	if ((!(a in g) || !(b in g)) && !insertNew)
		return false;
	if (adjacent!(V, E)(g, a, b)) return false;
	
	// Just insert the vertices. Nothing will happen here if they
	// already exist
	insertVertex!(V, E)(g, a);
	insertVertex!(V, E)(g, b);

	g[a][b] = weight;
	if (!oneWay)
		g[b][a] = weight;

	return true;
}

// remove an edge from the graph
bool removeEdge(V = vType, E = eType)(ref Graph!(V, E) g, V a, V b,
		bool oneWay = false) {
	if ((a in g) && (b in g)) {
		g[a].remove(b);
		if (!oneWay)
			g[b].remove(a);
		return true;
	}
	return false;
}

// deep-copy a graph and all of its elements
Graph!(V, E) clone(V = vType, E = eType)(Graph!(V, E) g) {
	Graph!(V, E) clone;
	foreach (e; g.byKey())
		clone[e] = g[e].dup;
	return clone;
}

// generate an array of the edges from a given graph, ignoring
// any duplicates
Edge!(V, E)[] toArray(V = vType, E = eType)(in Graph!(V, E) g) {
	Graph!(V, E) finished;
	Edge!(V, E)[] result;

	foreach (a; g.byKey()) {
		foreach (b; g[a].byKey()) {
			if (!adjacent!(V, E)(finished, a, b)) {
				result ~= Edge!(V, E)(a, b, g[a][b]);
				insertEdge!(V, E)(finished, a, b);
			}
		}
	}
	return result;
}

// construct a graph from a given set of vertices and edges
Graph!(V, E) construct(V = vType, E = eType)(V[] v, Edge!(V, E)[] e = []) {
	Graph!(V, E) result;
	
	foreach (a; v)
		insertVertex!(V, E)(result, a);
	foreach (a; e)
		insertEdge!(V, E)(result, a.expand);

	return result;
}

// Since we are working with undirected graphs, an edge (a, b) is stored
// in its adjacency list if and only if (b, a) is also contained.
// Although correct, this information is redundant, so generate a graph
// where each edge is only represented once.
Graph!(V, E) reduce(V = vType, E = eType)(in Graph!(V, E) g) {
	Graph!(V, E) result;

	auto array = toArray!(V, E)(g);
	foreach(a; array)
		insertEdge!(V, E)(result, a.expand, true);

	return result;
}

// restore a previously reduced graph to its normal representation
Graph!(V, E) restore(V = vType, E = eType)(in Graph!(V, E) g) {
	Graph!(V, E) result;

	foreach (a; g.byKey()) {
		foreach (b; g[a].byKey())
			insertEdge!(V, E)(result, a, b, g[a][b]);
	}

	return result;
}

// Find a 'safe' edge for a given subset of the graph. A safe edge is an
// edge whose insertion will not cause any cycles, and can be used for
// determining spanning trees. Safe edges are any edges of which one
// adjacent node is part of the existing subset, and the other one
// is not.
Edge!(V, E) safeEdge(V = vType, E = eType)(in Graph!(V, E) g,
		in Graph!(V, E) sub) {
	// sub must be an actual subset of g
	foreach (v; sub.byKey())
		assert (v in g);

	Edge!(V, E)[] edges;

	foreach (a; sub.byKey()) {
		foreach (b; g[a].byKey()) {
			if (!(b in sub))
				edges ~= Edge!(V, E)(a, b, g[a][b]);
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
	else return Edge!(V, E).init;
}

// a simple algorithm used to generate a minimum spanning tree by
// repeatedly inserting safe edges.
Graph!(V, E) genericMST(V = vType, E = eType)(Graph!(V, E) g) {
	if (g.length == 0) return g;

	Graph!(V, E) tree;
	foreach (e; g.byKey()) {
		insertVertex!(V, E)(tree, e);

		for (auto edge = safeEdge!(V, E)(g, tree); edge != Edge!(V, E).init;
				edge = safeEdge!(V, E)(g, tree)) {
			insertEdge!(V, E)(tree, edge.expand);
		}
	}

	return tree;
}

/**********************************************************************
* DEPTH-FIRST SEARCH
**********************************************************************/
// Color of Nodes found while searching the graph
// WHITE: undiscovered, GREY: discovered, but not finished,
// BLACK: discovered and finished
enum Color { WHITE, GREY, BLACK }
// Types of edges found. In an undirected graph, only tree and backward
// edges can occur.
enum EdgeType { TREE, FORWARD, BACKWARD, CROSS }
// A tuple holding all information on discovered vertices: its
// predecessor, the time discovered, the time finished, and its color
alias vData(V = vType) = Tuple!(V, "parent", int, "d", int, "f",
		Color, "color");
// The result returned by the algorithm: A hash containing all
// information on discovered vertices, and a graph holding information
// about the type of discovered edges.
alias DFSResult(V = vType) = Tuple!(vData!V[V], "vertices",
		Graph!(V, EdgeType), "graph");

// The depth-first search algorithm
DFSResult!V depthFirstSearch(V = vType, E = vType)(in Graph!(V, E) g) {
	// initialization - all nodes are undiscovered first, time runs from
	// zero, every node is its own parent
	int time = 0;
	DFSResult!V result;
	foreach (u; g.byKey()) {
		result.vertices[u] = vData!V(u, 0, 0, Color.WHITE);
	}

	// Search all vertices in the graph and visit them if they have not
	// yet been discovered
	foreach (u; g.byKey()) {
		if (result.vertices[u].color == Color.WHITE)
			dfsVisit!(V, E)(g, result, u, time);
	}

	return result;
}

void dfsVisit(V = vType, E = eType)(in Graph!(V, E) g,
		ref DFSResult!V result, V u, ref int time) {
	time += 1;
	result.vertices[u].d = time;
	result.vertices[u].color = Color.GREY;

	// Explore all edges to nodes (v) adjacent with u, classifying them
	// accordingly. If v has not yet been discovered, the explored edge
	// is a tree edge. If v has already been discovered, the explored
	// edge is a back edge. Currently, only the edges of undirected
	// graphs are being classified correctly.
	foreach (v; g[u].byKey()) {
		if (result.vertices[v].color == Color.WHITE) {
			insertEdge!(V, EdgeType)(result.graph, u, v,
					EdgeType.TREE);
			result.vertices[v].parent = u;
			dfsVisit!(V, E)(g, result, v, time);
		}
		else if (result.vertices[v].color == Color.GREY) {
			if (!adjacent!(V, EdgeType)(result.graph, u, v))
				insertEdge!(V, EdgeType)(result.graph, u, v,
						EdgeType.BACKWARD);
		}
	}
	result.vertices[u].color = Color.BLACK;
	time += 1;
	result.vertices[u].f = time;
}

unittest {
	Graph!() g;

	// inserting vertices
	assert(insertVertex!()(g, 1));
	assert(!insertVertex!()(g, 1));
	assert(1 in g);
	insertVertex!()(g, 2);
	insertVertex!()(g, 3);

	// inserting edges, checking weights etc.
	assert(insertEdge!()(g, 1, 2, 5));
	assert(!insertEdge!()(g, 1, 2));
	assert(adjacent!()(g, 1, 2));
	assert(adjacent!()(g, 2, 1));
	assert(g[1][2] == 5);
	assert(g[2][1] == 5);
	insertEdge!()(g, 2, 3, 3);
	insertEdge!()(g, 3, 1, 6);

	// inserting and removing edges one-directional
	assert(removeEdge!()(g, 1, 2, true));
	assert(!adjacent!()(g, 1, 2));
	assert(adjacent!()(g, 2, 1));
	assert(insertEdge!()(g, 1, 2, 10, true));
	assert(g[1][2] == 10);
	assert(g[2][1] == 5);

	// reducing the graph
	g = reduce!()(g);
	assert(adjacent!()(g, 1, 2));
	assert(!adjacent!()(g, 2, 1));

	// restoring the reduced graph
	g = restore!()(g);
	assert(adjacent!()(g, 1, 2));
	assert(adjacent!()(g, 2, 1));

	// construct a graph using the given function
	g = construct!()([1, 2, 3], [Edge!()(1, 2, 3), Edge!()(2, 3, 6), Edge!()(3, 1, 9)]);
	assert(1 in g);
	assert(adjacent!()(g, 1, 2));
	assert(adjacent!()(g, 2, 1));
	
	// finding safe edges for g, starting from 1
	auto tree = construct!()([1]);
	assert(safeEdge!()(g, tree) == Edge!()(1, 2, 3));
	insertEdge!()(tree, safeEdge!()(g, tree).expand);
	assert(safeEdge!()(g, tree) == Edge!()(2, 3, 6));
	insertEdge!()(tree, safeEdge!()(g, tree).expand);
	assert(safeEdge!()(g, tree) == Edge!().init);

	// performing a depth-first search
	auto res = depthFirstSearch!()(g);
	foreach (v; res.vertices.byValue())
		assert (v.color == Color.BLACK);
	assert(adjacent!(vType, EdgeType)(res.graph, 1, 2));
	assert(adjacent!(vType, EdgeType)(res.graph, 2, 3));
	assert(adjacent!(vType, EdgeType)(res.graph, 3, 1));
	assert(res.graph[1][2] == EdgeType.TREE);
	assert(res.graph[2][3] == EdgeType.TREE);
	assert(res.graph[3][1] == EdgeType.BACKWARD);
}
