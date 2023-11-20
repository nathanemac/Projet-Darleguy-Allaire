include("../Phase 1/node.jl")
include("../Phase 1/edge.jl")
include("../Phase 1/graph.jl")
include("../Phase 1/read_stsp.jl")
include("../Phase 1/main.jl")
include("../Phase 2/utils.jl")
include("../Phase 2/PriorityQueue.jl")

using LinearAlgebra
using Printf

##################################
##### Implémentation de HK : #####
##################################

#### Minimum 1-tree ####

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

function remove_node_and_edges(graph::ExtendedGraph, special_node::Node) :: ExtendedGraph
  # Copie le graphe
  new_graph = deepcopy(graph)

  # Supprime les arêtes incidentes au nœud spécial
  new_graph.edges = filter(e -> e.start_node != special_node && e.end_node != special_node, new_graph.edges)

  # Supprime également le nœud spécial
  new_graph.nodes = filter(n -> n != special_node, new_graph.nodes)

  return new_graph
end

"Trouve un 1-arbre de recouvrement minimal en partant de special_node"
function find_minimum_1tree(graph::ExtendedGraph; special_node::Node=graph.nodes[1], kruskal_or_prim = Kruskal)
  # Retire le nœud spécial et toutes ses arêtes incidentes du graphe
  subgraph = remove_node_and_edges(graph, special_node)

  # Trouve un mst pour subgraph
  if kruskal_or_prim == Prim
    mst = Prim(subgraph, st_node = subgraph.nodes[1])
  else
    mst = Kruskal(subgraph)
  end
  
  # Récupère les arêtes incidentes du nœud spécial dans le graphe d'origine
  special_node_edges = filter(e -> e.start_node == special_node || e.end_node == special_node, graph.edges)

  # Trie ces arêtes par poids
  sorted_edges = sort(special_node_edges, by = e -> e.weight)

  # Sélectionne les deux arêtes les moins chères
  cheapest_edges = sorted_edges[1:2]

  # Ajoute ces arêtes à l'arbre couvrant minimum pour former un 1-arbre
  for edge in cheapest_edges
      push!(mst.edges, edge)
  end

  # Ajoute special_node à subgraph
  push!(subgraph.nodes, special_node)
  sort!(mst.nodes, by = node -> node.name)
  mst
end


#### HK ####

"""Renvoie un vecteur contenant les arêtes reliant le noeud node à ses voisins"""
function neighbours(graph::ExtendedGraph, node::Node)
  arêtes_voisins = []
  for e in graph.edges
    noeud1 = e.start_node
    noeud2 = e.end_node 
    if (node == noeud1 || node == noeud2) 
      push!(arêtes_voisins, e)
    end
  end
  return arêtes_voisins
end

function HK(graph::ExtendedGraph; kruskal_or_prim = Kruskal,
                                  special_node::Node = graph.nodes[1], 
                                  maxIter::Int = 3000, 
                                  ϵ::Real = 1e-5, 
                                  verbose::Int=-1
                                  )

  graph_copy = deepcopy(graph)
  ### Initialisation ###
  n = length(graph_copy.nodes)
  k = 0
  πk = zeros(n)
  Tk = find_minimum_1tree(graph_copy, special_node = special_node, kruskal_or_prim = kruskal_or_prim)
  tk = 1

  # calcul de dk : 
  dk = []
  V = []
  for node in Tk.nodes
    voisins = neighbours(Tk, node)
    push!(V, voisins)
    push!(dk, length(voisins))
  end

  # calcul de vk :
  vk = dk .- 2
  nvk = norm(vk)

  if verbose > 0 && mod(k, verbose) == 0
    @info @sprintf "%5s  %9s  %7s " "iter" "tk" "‖vk‖"
    infoline = @sprintf "%5d  %9.2e  %7.1e" k tk nvk
  end

  while nvk > ϵ && k < maxIter # vk tend vers 0 composante par composante, donc sa norme tend vers 0
    # On met à jour πk avec vk
    πk .= πk .+ tk .* vk
    
    # On met à jour le poids des arêtes
    for i=1:n
      current_node = graph_copy.nodes[i]
      for e in graph_copy.edges
        if (e.start_node == current_node || e.end_node == current_node)
          e.weight += πk[i]
        end
      end
    end
    
    # On cherche le 1-arbre minimal correspondant au graphe mis à jour
    Tk = find_minimum_1tree(graph_copy)
    k += 1
    tk = 1/(k+1)

    dk = []
    V = []
    for node in Tk.nodes
      voisins = neighbours(Tk, node)
      push!(V, voisins)
      push!(dk, length(voisins))
    end
  
    # Calcul de vk pour le graphe mis à jour :
    vk = dk .- 2
    nvk = norm(vk)    

    if verbose > 0 && mod(k, verbose) == 0
      @info infoline
      infoline = @sprintf "%5d  %9.2e  %7.1e" k tk nvk
    end

    if k == maxIter
      println("maximum iteration criterion reached at k = $k")
    elseif nvk ≤ ϵ 
      println("algorithm converged to a optimal tour at k = $k")
    end
  end
  Tk.name = "Optimal tour"
  nvk_final = nvk
  @info infoline
  infoline = @sprintf "%5d  %9.2e  %7.1e" k tk nvk_final
  return Tk
end


r = HK(cours, maxIter = 100, verbose=2) # converge en 15 itérations pour le noeud 1

graph_tsp = build_graph("Phase 1/instances/stsp/bays29.tsp", "Graph_Test")
r2 = HK(graph_tsp, verbose=10000, maxIter=200_000) # ne converge pas

# Utilisation de la fonction
