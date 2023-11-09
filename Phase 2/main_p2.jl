include("../Phase 1/node.jl")
include("../Phase 1/edge.jl")
include("../Phase 1/graph.jl")
include("../Phase 1/read_stsp.jl")
include("../Phase 1/main.jl")
include("utils.jl")
include("PriorityQueue.jl")

n1 = Node("1", [1.0, 3.0], nothing)
n2 = Node("2", [2.0, 1.0])
n3 = Node("3", [1.0, 2.0], nothing)
n4 = Node("4", [1.0, 2.0])
n5 = Node("5", [2.0, 3.9])

e1 = Edge(n1, n2, 5.6)
e2 = Edge(n2, n3, 1.0)
e3 = Edge(n1, n3, 2.0)
e4 = Edge(n2, n4, 2.0)
e5 = Edge(n1, n4, 0.5)
e6 = Edge(n4, n5, 3.0)

connexcomp1 = ConnexComponent("connex component 1", [n1, n2])
connexcomp2 = ConnexComponent("connex component 2", [n3, n4])
connexcomp3 = ConnexComponent("connex component 3", [n5])

graph_test = ConnexGraph("graph test", [connexcomp1, connexcomp2])

##############################

# Questions 1, 2
graph = build_graph("Phase 1/instances/stsp/bays29.tsp", "Graph_Test")


# Question 3

# Exemple sur deux composantes connexes de même rang maximal : 
CC1 = ConnexComponent("cc1", [Node("1", 0.5)])
for i = 2:10
  push!(CC1.nodes, Node("n$i", rand(1)[1]))
end
CC2 = ConnexComponent("cc2", [Node("11", 0.8)])
for i = 2:10
  push!(CC2.nodes, Node("n$(i+10)", rand(1)[1]))
end

union_all!(CC1, CC2)

CC3 = ConnexComponent("cc3", [Node("21", 1.5)])
for i = 2:5
  push!(CC3.nodes, Node("n$(i+20)", rand(1)[1]))
end

union_all!(CC1, CC3)
# TODO : répondre question sur le rang
# sinon ça m'a l'air ok, à tester. 



##########
# Question 4

  # 1 : exemple simple
G = ExtendedGraph("test", [n1, n2, n3, n4, n5], [e1, e2, e3, e4, e5, e6])

test_graph_kruskal = Kruskal(G)
test_graph_prim = Prim(G)
# Youpi ça renvoie la bonne chose, le graphe est optimal

  # 2 : exemple sur un TSP symétrique
graph = build_graph("Phase 1/instances/stsp/bays29.tsp", "Graph_Test")
graph_kruskal = Kruskal(graph)
graph_prim = Prim(graph, graph.nodes[1])

# le graphe est gros donc difficile de savoir si c'est optimal ou pas. 


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

# Youpi, les deux graphes optimisés sont identiques aux graphes du cours. 

# Reste une chose à traiter : vérifier si la gestion des parents est correcte vis à vis des heuristiques. 


