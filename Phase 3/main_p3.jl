include("../Phase 1/node.jl")
include("../Phase 1/edge.jl")
include("../Phase 1/graph.jl")
include("../Phase 1/read_stsp.jl")
include("../Phase 1/main.jl")
include("../Phase 2/utils.jl")
include("../Phase 2/PriorityQueue.jl")

using LinearAlgebra

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
  mst
end

m1st = find_minimum_1tree(cours)
# Semble fonctionner. 



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

function HK(graph::ExtendedGraph; special_node::Node = graph.nodes[1], maxIter = 3000, ϵ = 1e-5, verbose::Int=-1)

  graph_copy = deepcopy(graph)

  ### Initialisation ###
  n = length(graph_copy.nodes)
  k = 0
  println("itération $k")
  πk = zeros(n)
  Tk = find_minimum_1tree(graph_copy, special_node = special_node)
  T0 = deepcopy(Tk)
  tk = 1

  # calcul de dk : 
  dk = []
  V = []
  for node in Tk.nodes
    voisins = neighbours(Tk, node)
    push!(V, voisins)
    push!(dk, length(voisins))
  end

  # Ensuite, on retire les arêtes en double : V contient 2 fois trop d'arêtes car (a voisin de b) <=> (b voisin de a)
  
  VV = []
  for e in vcat(V...)
    if e ∉ VV
      push!(VV, e)
    end
  end

  # calcul de vk :
  vk = dk .- 2
  v0 = vk
  nvk = norm(vk)

  while nvk > ϵ && k < maxIter # vk tend vers 0 composante par composante, donc sa norme tend vers 0
    # On met à jour πk avec vk
    πk = πk + tk * vk
    
    # On met à jour le poids des arêtes
    for i=1:n
      VV[i].weight += πk[i]
    end

    # On crée le nouveau graphe avec les arêtes mises à jour
    for e_VV in VV
      for e in graph_copy.edges
        if e_VV.start_node == e.start_node && e_VV.end_node == e.end_node
          w = e.weight
          e.weight = e_VV.weight
          # println("poids : ", w," -> ", e.weight)
        end
      end
    end
                
    new_graph = ExtendedGraph("graphe $k", graph_copy.nodes, graph_copy.edges)
    Tk = find_minimum_1tree(new_graph)
    k += 1
    (k % verbose == 0) && println("itération ", k)
    tk = 1/(k+1)

    dk = []
    V = []
    for node in Tk.nodes
      voisins = neighbours(Tk, node)
      push!(V, voisins)
      push!(dk, length(voisins))
    end
  
    # Et on réitère les manipulations de l'Initialisation    
    VV = []
    for e in vcat(V...)
      if e ∉ VV
        push!(VV, e)
      end
    end
  
    # calcul de vk :
    vk = dk .- 2
    nvk = norm(vk)    
    if k == maxIter
      println("maximum iteration criterion reached at k = $k")
    elseif nvk ≤ ϵ 
      println("algorithm converged to a optimal tour at k = $k")
    end
  end
  return T0, Tk, v0, vk
end

r = HK(cours, special_node=cours.nodes[2])
# Semble ne pas fonctionner : le poids des arêtes sont mis à jour, mais les arêtes restent les mêmes quoi qu'il advienne


m1st_1 = find_minimum_1tree(cours, special_node = cours.nodes[1])
M1ST = [find_minimum_1tree(cours, special_node = cours.nodes[i]) for i=1:9]

r1 = HK(cours, special_node=cours.nodes[1])
r2 = HK(cours, special_node=cours.nodes[2])
r3 = HK(cours, special_node=cours.nodes[3], maxIter = 10_000)



graph_tsp = build_graph("Phase 1/instances/stsp/bays29.tsp", "Graph_Test")

r = HK(graph_tsp, verbose=10)