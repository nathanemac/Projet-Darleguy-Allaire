include("../Phase 1/node.jl")
include("../Phase 1/edge.jl")
include("../Phase 1/graph.jl")
include("../Phase 1/read_stsp.jl")
include("../Phase 1/main.jl")
include("../Phase 2/utils.jl")
include("../Phase 2/PriorityQueue.jl")
include("utils.jl")

function create_graph()
  # 3 : exemple du cours
  a, b, c, d, e, f, g, h, i = Node("a", 1.0), Node("b", 1.0), Node("c", 1.0), Node("d", 1.0), Node("e", 1.0), Node("f", 1.0), Node("g", 1.0), Node("h", 1.0), Node("i", 1.0)
  e1 = Edge(a, b, 4.)
  e2 = Edge(b, c, 8.)
  e3 = Edge(c, d, 7.)
  e4 = Edge(d, e, 9.)
  e5 = Edge(e, f, 10.)
  e6 = Edge(d, f, 14.)
  e7 = Edge(f, c, 4.)
  e8 = Edge(f, g, 2.)
  e9 = Edge(g, i, 6.)
  e10 = Edge(g, h, 1.)
  e11 = Edge(a, h, 8.)
  e12 = Edge(h, i, 7.)
  e13 = Edge(i, c, 2.)
  e14 = Edge(b, h, 11.)
  G_cours = ExtendedGraph("graphe du cours", [a, b, c, d, e, f, g, h, i], [e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14])
  
  
  graph_cours_kruskal = Kruskal(G_cours)
  graph_cours_prim = Prim(G_cours, st_node = a)

  return graph_cours_kruskal, graph_cours_prim, G_cours
end
kruskal, prim, cours = create_graph()


# HK
r = HK(cours) # converge en 15 itérations pour le noeud 1
poids_tour_cours = sum(map(edge -> edge.weight, r.edges))


graph_bays29 = build_graph("Phase 1/instances/stsp/bays29.tsp", "Graph_Test")
r2 = HK(graph_bays29, verbose=1000, maxIter=20000) # ne converge pas
poids_tour_bays29 = sum(map(edge -> edge.weight, r2.edges))

graph_swiss42 = build_graph("Phase 1/instances/stsp/swiss42.tsp", "Graph_Test")
r3 = HK(graph_swiss42, verbose=1000, maxIter=20000) # ne converge pas
poids_tour_swiss42 = sum(map(edge -> edge.weight, r3.edges))

graph_gr17 = build_graph("Phase 1/instances/stsp/gr17.tsp", "Graph_Test")
r4 = HK(graph_gr17, verbose=1000, maxIter=20000) # ne converge pas
poids_tour_gr17 = sum(map(edge -> edge.weight, r4.edges))



### RSL 

# sur exemple du cours
tour = RSL(cours)

# sur un tsp
graph_bays29 = build_graph("Phase 1/instances/stsp/bays29.tsp", "Graph_Test")
r5 = RSL(graph_bays29) 
cost1 = cost_tour(graph_bays29, r5)


# sur un autre tsp
graph_gr17 = build_graph("Phase 1/instances/stsp/gr17.tsp", "Graph_Test")
r6 = RSL(graph_gr17) 
cost2 = cost_tour(graph_gr17, r6)

# Pour Victor: tu verras dans les paramètres de HK (tape ? puis HK dans le terminal), il y a pas mal de paramètres que l'utilisateur peut choisir. 
# Ce serait bien de montrer comment ça marche, je peux te montrer si tu galères. 