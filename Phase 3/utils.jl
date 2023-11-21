using LinearAlgebra
using Printf

"""Prend un graphe et un noeud en entrée et renvoie un graphe sans ce noeud et sans les arêtes incidentes à ce noeud"""
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

"""fonction par défaut de calcul de tk pour l'algorithme de HK."""
function compute_tk(k::Int; div::Int=100)
  K = [i for i = 1:div]
  return 1/K[k%div + 1]
end

""" 
        `HK(graph; kwargs...)`

    Implémente une partie de l'algorithme de HK renvoyant une tournée optimale d'un graphe connexe non-orienté.
    
    # Argument : 
    - `graph::ExtendedGraph` est le graphe dont on doit trouver une tournée

    # Arguments optionnels 
    - `kruskal_or_prim` = Kruskal : fonction au choix (Prim ou Kruskal) pour déterminer un arbre de recouvrement minimal
    - `special_node::Node` = graph.nodes[1] : noeud spécial pour déterminer un 1-tree minimal 
    - `maxIter::Int = 1000` : nombre maximal d'itérations 
    - `ϵ::Real = 1e-3` : lorsque chaque noeud a exactement deux voisins, vk = zeros(length(graph.nodes)) donc sa norme est proche de 0
    - `verbose::Int=-1` : si > 0, affiche des détails de l'itération courante toutes les `verbose`` itérations
    - `compute_tk::Function = compute_tk` : fonction de calcul par défaut de tk, voir `compute_tk` pour davantage d'informations. Cet argument peut être modifié afin d'implémenter une méthode de calcul de tk propre à l'utilisateur.  

    # Sortie : 
    `Tk::ExtendedGraph` : graphe dont les arêtes forment une tournée optimale si le critère sur ϵ a été atteint. 

"""
function HK(graph::ExtendedGraph; kruskal_or_prim = Kruskal,
                                  special_node::Node = graph.nodes[1], 
                                  maxIter::Int = 1000, 
                                  ϵ::Real = 1e-3, 
                                  verbose::Int=-1,
                                  compute_tk::Function = compute_tk,
                                  )

  graph_copy = deepcopy(graph)
  ### Initialisation ###
  n = length(graph_copy.nodes)
  k = 0
  πk = zeros(n)
  Tk = find_minimum_1tree(graph_copy, special_node = special_node, kruskal_or_prim = kruskal_or_prim)  
  weights = map(edge -> edge.weight, Tk.edges)
  total_weight = sum(weights)
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
    @info @sprintf "%5s  %9s  %7s  %7s " "iter" "tk" "‖vk‖" "weight_graph"
    infoline = @sprintf "%5d  %9.2e  %7.1e  %7.1e" k tk nvk total_weight
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
    weights = map(edge -> edge.weight, Tk.edges)
    total_weight = sum(weights)
    total_weight
    k += 1
    tk = compute_tk(k)

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
      infoline = @sprintf "%5d  %9.2e  %7.1e  %7.1e" k tk nvk total_weight
    end

    if k == maxIter
      println("maximum iteration criterion reached at k = $k")
    elseif nvk ≤ ϵ 
      println("algorithm converged to a optimal tour at k = $k")
    end
  end
  Tk.name = "Optimal tour"

  # Enfin, on stocke les arêtes formant la tournée (optimale ou non) dans le graphe. 
  final_edges = []
  for e_tk in Tk.edges
    for e in graph.edges
      if e_tk.start_node == e.start_node && e_tk.end_node == e.end_node
        push!(final_edges, e)
      end
    end
  end
  Tk.edges = final_edges

  weights = map(edge -> edge.weight, Tk.edges)
  total_weight = sum(weights)

  if verbose > 0
    @info infoline
    infoline = @sprintf "%5d  %9.2e  %7.1e  %7.1e" k tk nvk total_weight 
  end 
  return Tk
end

function RSL!(graph::ExtendedGraph, racine::Node, root_node::Node, visited=Set{Node}(), path=Vector{String}())
  push!(visited, racine)
  push!(path, racine.name)  
  edges = neighbours(graph, racine)
  for e in edges
      next_node = e.start_node == racine ? e.end_node : e.start_node
      if !(next_node in visited)
          next_node.parent = racine
          RSL!(graph, next_node, root_node, visited, path)  
      end
  end

  all_visited = all(node -> node in visited, nodes(graph))
  if all_visited && path[end] != root_node.name
    return path
  end
end