include("../Phase 1/node.jl")
include("../Phase 1/edge.jl")
include("../Phase 1/graph.jl")
include("../Phase 1/read_stsp.jl")
include("../Phase 1/main.jl")
include("../Phase 2/utils.jl")
include("../Phase 2/PriorityQueue.jl")
include("../Phase 3/utils.jl")
include("shredder-julia/bin/tools.jl")

using ImageMagick, FileIO, Images, ImageView

photo = build_graph("Phase 4/shredder-julia/tsp/instances/alaska-railroad.tsp", "Graph_Test")
tour = HK(photo, maxIter=10, verbose=1) # pas optimal car peu d'itérations, HK a pas convergé

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
i = 1
# pour que ça marche avec write_tour
for node in cours.nodes
  node.name = "$i"
  i+=1
end

r = HK(cours) # converge en 15 itérations pour le noeud 1


"""Suppose que les arêtes forment bien un tour"""
function create_tour(graph::ExtendedGraph)
  E = copy(graph.edges)
  tour_names = [E[1].start_node.name, E[1].end_node.name]
  tour = [E[1].start_node, E[1].end_node]
  dict_visited = Dict(edge => false for edge in E)
  dict_visited[E[1]] = true

  current_end_node = tour[end]

  while true
    for e in E
      if (e.start_node == current_end_node) && (dict_visited[e] == false)
        push!(tour_names, e.end_node.name)
        push!(tour, e.end_node)
        current_end_node = tour[end]
        dict_visited[e] = true
        break
      elseif (e.end_node == current_end_node) && (dict_visited[e] == false)
        push!(tour_names, e.start_node.name)
        push!(tour, e.start_node)
        current_end_node = tour[end]
        dict_visited[e] = true
        break
      end
    end

    if current_end_node == tour[1]
      break
    end
  end
  deleteat!(tour_names, length(tour_names))
  tour_int = [parse(Int, str) for str in tour_names]

  return tour_int
end

function cost_tour(tour::ExtendedGraph)
  sum(map(edge -> edge.weight, tour.edges))
end

write_tour("tour cours", create_tour(r), Float32(cost_tour(r)))
# Ok fonctionne. A faire ensuite avec une tournée de RSL (vu que HL converge pas)

# Test avec un tour donné
tour_test = "Phase 4/shredder-julia/tsp/tours/alaska-railroad.tour"
reconstruct_picture(tour_test, "Phase 4/shredder-julia/images/shuffled/alaska-railroad.png", "photo_train.png")
# Ok fonctionne pour un fichier tour donné. 


