include("../Phase 1/node.jl")
include("../Phase 1/edge.jl")
include("../Phase 1/graph.jl")
include("../Phase 1/read_stsp.jl")
include("../Phase 1/main.jl")
include("../Phase 2/utils.jl")
include("../Phase 2/PriorityQueue.jl")

##################################
##### Implémentation de HK : #####
##################################

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
  # Copiez le graphe
  new_graph = deepcopy(graph)

  # Supprimez les arêtes incidentes au nœud spécial
  new_graph.edges = filter(e -> e.start_node != special_node && e.end_node != special_node, new_graph.edges)

  # Supprimez également le nœud spécial
  new_graph.nodes = filter(n -> n != special_node, new_graph.nodes)

  return new_graph
end

"Trouve un 1-arbre de recouvrement minimal en partant de special_node"
function find_minimum_1tree(graph::ExtendedGraph, special_node::Node; kruskal_or_prim = Kruskal)
  # Retire le nœud spécial et toutes ses arêtes incidentes du graphe
  subgraph = remove_node_and_edges(graph, special_node)

  # Trouve un mst pour subgraph
  if kruskal_or_prim == Prim
    mst = Prim(subgraph, st_node = subgraph.nodes[1])
  else
    mst = Kruskal(subgraph)
  end
  

  # Récupérez les arêtes incidentes du nœud spécial dans le graphe d'origine
  special_node_edges = filter(e -> e.start_node == special_node || e.end_node == special_node, graph.edges)

  # Triez ces arêtes par poids
  sorted_edges = sort(special_node_edges, by = e -> e.weight)

  # Sélectionnez les deux arêtes les moins chères
  cheapest_edges = sorted_edges[1:2]

  # Ajoutez ces arêtes à l'arbre couvrant minimum pour former un 1-arbre
  for edge in cheapest_edges
      push!(mst.edges, edge)
  end

  # Ajoute special_node à subgraph
  push!(subgraph.nodes, special_node)
  mst
end

m1st = find_minimum_1tree(cours, cours.nodes[3])
# Semble fonctionner. 

"""Renvoie le coût d'une liste d'arêtes"""
function length_path(E)
  cost = 0
  for e in E
    cost += e.weight
  end
  cost
end

"Renvoie l'arête la plus lourde d'une liste d'arêtes"
function find_longest_edge(edges)
  longest_edge = nothing
  max_weight = -Inf
  for edge in edges
      if edge.weight > max_weight
          max_weight = edge.weight
          longest_edge = edge
      end
  end
  return longest_edge
end

function incident_edges_not_including(edge_to_exclude::Edge, min_1_tree::ExtendedGraph, special_node::Node)
  edges = []
  for edge in min_1_tree.edges
      if edge != edge_to_exclude && (edge.start_node == special_node || edge.end_node == special_node)
          push!(edges, edge)
      end
  end
  return edges
end

function calculate_alpha_values(graph::ExtendedGraph, min_1_tree::ExtendedGraph, special_node::Node)
  alpha_values = Dict{Tuple{Node,Node}, Float64}()

  # Calcul de la longueur totale du 1-arbre minimum
  length_min_1_tree = sum(edge.weight for edge in min_1_tree.edges)

  for edge in graph.edges
      if edge.start_node in min_1_tree.edges
          # Cas (a) : Si l'arête (i,j) appartient à T, alors α(i,j) est égal à 0.
          alpha_values[(edge.start_node, edge.end_node)] = 0.0
      else
          # Cas (b) et (c) : Si l'arête (i,j) n'appartient pas à T.
          # Pour le nœud spécial, nous remplaçons l'arête la plus longue incidente par (i,j).
          # Sinon, nous insérons (i,j) et retirons l'arête la plus longue pour former T^(i,j).
          new_1_tree = insert_edge_in_1_tree(min_1_tree, edge, special_node)
          length_new_1_tree = sum(e.weight for e in new_1_tree.edges)
          # α(i,j) est la différence de longueur entre le nouveau 1-arbre et le 1-arbre minimum original.
          alpha_values[(edge.start_node, edge.end_node)] = length_new_1_tree - length_min_1_tree
      end
  end
  return alpha_values
end

function insert_edge_in_1_tree(min_1_tree::ExtendedGraph, edge::Edge, special_node::Node)
  # Copie du 1-arbre minimum pour ne pas modifier l'original
  new_1_tree = deepcopy(min_1_tree)
  
  # Ajoutez l'arête nouvellement insérée
  push!(new_1_tree.edges, edge)

  # Trouver le cycle qui inclut l'arête nouvellement insérée
  cycle_edges = find_cycle(new_1_tree, edge, special_node)

  # Identifier et supprimer l'arête la plus longue dans le cycle pour maintenir la structure du 1-arbre
  longest_edge = find_longest_edge(cycle_edges)
  new_1_tree.edges = setdiff(new_1_tree.edges, [longest_edge])

  return new_1_tree
end

function find_cycle(graph::ExtendedGraph, inserted_edge::Edge, special_node::Node)
  visited = Set{Node}()
  parent = Dict{Node, Union{Node, Nothing}}()

  function dfs(current_node::Node, prev_node::Union{Node, Nothing})
      if current_node in visited
          return true, current_node
      end

      push!(visited, current_node)
      parent[current_node] = prev_node

      for edge in graph.edges
          if edge.start_node == current_node || edge.end_node == current_node
              neighbor = edge.start_node == current_node ? edge.end_node : edge.start_node
              if neighbor !== prev_node  # Use `!==` to include comparison with `Nothing`
                  found_cycle, cycle_end = dfs(neighbor, current_node)
                  if found_cycle
                      return true, cycle_end
                  end
              end
          end
      end

      return false, nothing
  end

  # Initial call to `dfs` with `prev_node` as `Nothing`
  found_cycle, cycle_end = dfs(special_node, nothing)

  # Reconstruct the cycle if found
  cycle_edges = []
  if found_cycle
      current_node = cycle_end
      while current_node !== nothing && current_node != special_node
          prev_node = parent[current_node]
          edge = find_edge(graph, current_node, prev_node)
          push!(cycle_edges, edge)
          current_node = prev_node
      end
      # Add the inserted edge to complete the cycle
      push!(cycle_edges, inserted_edge)
  end

  return cycle_edges
end

function find_edge(graph::ExtendedGraph, node1::Node, node2::Node)
  for edge in graph.edges
      if (edge.start_node == node1 && edge.end_node == node2) || (edge.start_node == node2 && edge.end_node == node1)
          return edge
      end
  end
  return nothing  # Renvoie rien si aucune arête n'est trouvée (ce qui ne devrait pas arriver dans un graphe complet).
end


m1st = find_minimum_1tree(graph_sym, graph_sym.nodes[1])
alpha = calculate_alpha_values(graph_sym, m1st, graph_sym.nodes[1])


n = [Node("$i", 1.0) for i =1:5]
e1 = Edge(n[1], n[2], 1.0)
e2 = Edge(n[1], n[3], 2.0)
e3 = Edge(n[1], n[4], 0.6)
e4 = Edge(n[1], n[5], 0.6)
e5 = Edge(n[2], n[3], 3.0)
e6 = Edge(n[2], n[4], 2.0)
e7 = Edge(n[2], n[5], 1.5)
e8 = Edge(n[3], n[4], 2.0)
e9 = Edge(n[3], n[5], 3.5)
e10 = Edge(n[4], n[5], 0.7)

E = [e1, e2, e3, e4, e5, e6, e7, e8, e9, e10]
mini_graph = ExtendedGraph("mini", N, E)



alpha = calculate_alpha_values(mini_graph, m1st, mini_graph.nodes[1])

## Test sur petit graphe
alpha_values = Dict{Tuple{Node,Node}, Float64}()
graph = mini_graph
min_1_tree = find_minimum_1tree(graph, graph.nodes[1])



function insert_edge_in_1_tree(min_1_tree::ExtendedGraph, edge::Edge, special_node::Node)
  # Créer une copie du 1-arbre pour ne pas modifier l'original
  new_1_tree = deepcopy(min_1_tree)

  # Ajouter la nouvelle arête au 1-arbre
  push!(new_1_tree.edges, edge)

  # Trouver le cycle incluant la nouvelle arête
  cycle_edges = find_cycle(new_1_tree, edge, special_node)

  # Si aucun cycle n'est trouvé, cela signifie que l'arête peut être ajoutée sans problème
  if isempty(cycle_edges)
      return new_1_tree
  end

  # Trouver l'arête la plus longue dans le cycle
  longest_edge = find_longest_edge(cycle_edges)

  # Retirer l'arête la plus longue pour briser le cycle et conserver la structure du 1-arbre
  new_1_tree.edges = filter(e -> e != longest_edge, new_1_tree.edges)

  return new_1_tree
end

function calculate_alpha_values(graph::ExtendedGraph, min_1_tree::ExtendedGraph, special_node::Node)
  alpha_values = Dict{Tuple{Node,Node}, Float64}()

  length_min_1_tree = sum(edge.weight for edge in min_1_tree.edges)

  for edge in graph.edges
      if edge in min_1_tree.edges
          alpha_values[(edge.start_node, edge.end_node)] = 0.0
      elseif edge.start_node == special_node || edge.end_node == special_node
          incident_edges = filter(e -> e.start_node == special_node || e.end_node == special_node, min_1_tree.edges)
          longest_edge = find_longest_edge(incident_edges)
          alpha_value = edge.weight - longest_edge.weight
          alpha_values[(edge.start_node, edge.end_node)] = alpha_value
      # else
      #     new_1_tree = insert_edge_in_1_tree(min_1_tree, edge, special_node)
      #     length_new_1_tree = sum(e.weight for e in new_1_tree.edges)
      #     alpha_values[(edge.start_node, edge.end_node)] = length_new_1_tree - length_min_1_tree
      end
  end
  return alpha_values
end


function find_cycle(graph::ExtendedGraph, inserted_edge::Edge, special_node::Node)
  # On utilise un dictionnaire pour garder la trace des prédécesseurs des nœuds lors de la DFS.
  parent_map = Dict{Node, Node}()
  
  # Ensemble pour suivre les nœuds visités.
  visited = Set{Node}()

  # Fonction interne DFS pour visiter les nœuds.
  function dfs(node::Node, parent::Union{Node, Nothing})
      push!(visited, node)
      parent_map[node] = parent

      for edge in graph.edges
          # Vérifier si l'arête courante est connectée au nœud en cours de visite.
          if edge.start_node == node || edge.end_node == node
              next_node = edge.start_node == node ? edge.end_node : edge.start_node
              if next_node != parent
                  # Si nous rencontrons un nœud déjà visité, nous avons trouvé un cycle.
                  if next_node in visited
                      return next_node, true
                  end
                  cycle_end, found_cycle = dfs(next_node, node)
                  if found_cycle
                      return cycle_end, true
                  end
              end
          end
      end

      return node, false
  end

  # Commencer la recherche DFS à partir du nœud spécial.
  cycle_end, found_cycle = dfs(special_node, nothing)
  
  # Si un cycle est trouvé, reconstruisez-le en remontant le chemin à partir de cycle_end.
  cycle_edges = []
  if found_cycle
      current_node = cycle_end
      while current_node != special_node
          parent_node = parent_map[current_node]
          # Utilisez la fonction find_edge pour récupérer l'arête entre current_node et parent_node.
          edge = find_edge(graph, current_node, parent_node)
          push!(cycle_edges, edge)
          current_node = parent_node
      end
      # Ajoutez l'arête insérée pour fermer le cycle.
      push!(cycle_edges, inserted_edge)
  end
        
  return cycle_edges
end
        
function find_edge(graph::ExtendedGraph, node1::Node, node2::Node)
  # Cette fonction doit trouver et renvoyer l'arête qui connecte node1 et node2.
  for edge in graph.edges
    if (edge.start_node == node1 && edge.end_node == node2) || (edge.start_node == node2 && edge.end_node == node1)
      return edge
    end
  end
  println("arête non trouvée") # Si l'arête n'est pas trouvée, ce qui ne devrait pas arriver.
end

