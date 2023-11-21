###############################
#### Algorithme de Kruskal ####
###############################

# find_component recherche la composante connexe d'un noeud donné.
"""
    find_component(components, node)

Recherche et renvoie la composante connexe à laquelle appartient le noeud `node`.
- `components` est un tableau de composantes connexes.
- `node` est le noeud dont la composante connexe est recherchée.

Renvoie la composante connexe trouvée ou `nothing` si le noeud n'est pas trouvé.
"""
function find_component(components, node)
    for component in components
        if node in component.nodes
            return component
        end
    end
    return nothing
end

# merge_components! fusionne deux composantes connexes en une seule.
"""
    merge_components!(components, component1, component2)

Fusionne deux composantes connexes `component1` et `component2` en une seule.
- `components` est le tableau contenant toutes les composantes.
- `component1` et `component2` sont les composantes à fusionner.

Supprime `component2` du tableau `components` après fusion.
"""
function merge_components!(components, component1, component2)
    for node in component2.nodes
        push!(component1.nodes, node)
    end
    deleteat!(components, findfirst(x -> x == component2, components))
end

# Kruskal implémente l'algorithme de Kruskal pour trouver l'arbre couvrant minimal d'un graphe.
"""
    Kruskal(graph::ExtendedGraph)

Implémente l'algorithme de Kruskal pour trouver l'arbre couvrant minimal d'un graphe.
- `graph` est un graphe étendu avec des sommets et des arêtes.

Crée un `ExtendedGraph` représentant l'arbre couvrant minimal trouvé.
"""
function Kruskal(graph::ExtendedGraph)
    A0 = typeof(graph.edges[1])[]
    A = graph.edges
    S_connex = ConnexGraph("Graphe connexe", graph)
    S = graph.nodes

    res = ExtendedGraph("res Kruskal", S, A0)

    for n in S
        add_connex_component!(S_connex, ConnexComponent("", [n]))
    end

    A_sorted = sort(A, by = e -> e.weight)
    Components = S_connex.components

    for a in A_sorted
        start_component = find_component(Components, a.start_node)
        end_component = find_component(Components, a.end_node)

        if start_component !== end_component
            push!(A0, a)
            merge_components!(Components, start_component, end_component)
        end
    end
    return res
end

#################################
#### Pour les 2 heuristiques ####
#################################

"""
    find_root!(CC::ConnexComponent)

Trouve la racine de la composante connexe `CC`. Si la racine est déjà déterminée,
la fonction la retourne simplement. Sinon, elle la détermine en cherchant le premier
nœud sans parent et en le définissant comme racine. Ensuite, elle fait pointer tous
les nœuds de la composante directement vers la racine.

### Arguments
- `CC` : une composante connexe de type `ConnexComponent`.

### Retourne
La racine de la composante connexe.

### Modification en place
Les nœuds de la composante connexe sont modifiés pour pointer vers la racine trouvée.
"""
function find_root!(CC::ConnexComponent)

  # Renvoie la racine de la composante si elle n'est pas déjà déterminée
  if CC.root !== nothing
    return CC.root
  end

  root = CC.nodes[1]
  for node in CC.nodes
    # On s'arrête dès que l'on trouve un noeud sans parent
    if node.parent === nothing
      root = node
      root.rank += 1
      CC.root = root
      break
    end
  end
  
  # On fait pointer les nœuds directement vers la racine.
  for node in CC.nodes
    if node === root
      continue
    else
      node.parent = root
    end
  end
  root
end


"""
    union_roots!(root1::AbstractNode, root2::AbstractNode)

Lier deux racines d'arbres en union-find. La racine de rang inférieur est liée
à la racine de rang supérieur. Si les rangs sont égaux, une des racines est liée
à l'autre et son rang est augmenté de 1.

### Arguments
- `root1` : le premier noeud racine.
- `root2` : le second noeud racine.

### Modification en place
Les parents et les rangs des racines sont potentiellement modifiés pour refléter l'union.
"""
function union_roots!(root1::AbstractNode, root2::AbstractNode)

  # Lie la racine de rang inférieur à la racine de rang supérieur
  if root1.rank > root2.rank
      root2.parent = root1
  elseif root1.rank < root2.rank
      root1.parent = root2
  else
      # Si les deux racines ont le même rang, lie l'une à l'autre et augmentez le rang de la racine parent
      root2.parent = root1
      root1.rank += 1
  end
  return
end

"""
    union_all!(CC1::ConnexComponent, CC2::ConnexComponent)

Unir deux composantes connexes. Trouve les racines des deux composantes
et les unit en utilisant `union_roots!`. Ensuite, les nœuds de la composante
de rang inférieur sont ajoutés à ceux de la composante de rang supérieur.

### Arguments
- `CC1` : la première composante connexe.
- `CC2` : la seconde composante connexe.

### Retourne
La liste des nœuds de la composante connexe qui a absorbé l'autre.

### Modification en place
Les nœuds de la composante connexe de rang inférieur sont déplacés vers celle de rang supérieur.
"""
function union_all!(CC1::ConnexComponent, CC2::ConnexComponent)
  # Trouver les racines des deux composantes
  root1 = find_root!(CC1)
  root2 = find_root!(CC2)

  # Si les racines sont déjà les mêmes, rien à faire
  if root1 === root2
      return
  end

  # Sinon, unir les deux racines
  union_roots!(root1, root2)

  # Ajoute les noeuds de la composante fille aux noeuds de la composante mère
  if root1.rank > root2.rank
    append!(CC1.nodes, CC2.nodes)
    empty!(CC2.nodes)
    return CC1.nodes
  else 
    append!(CC2.nodes, CC1.nodes)
    empty!(CC2.nodes)
    return CC2.nodes
  end
end


############################
#### Algorithme de Prim ####
############################

"""
    neighbours_node(n::AbstractNode, graph::ExtendedGraph)

Retourne un ensemble d'arêtes du graph `graph` contenant le nœud `n`, triées par ordre croissant de leur poids. 
Cela permet de déterminer les voisins d'un nœud dans le cadre d'algorithmes graphiques.

### Arguments
- `n` : Le nœud pour lequel les voisins sont recherchés.
- `graph` : Le graphe de type `ExtendedGraph` contenant le nœud `n`.

### Retourne
Un vecteur des arêtes voisines du nœud `n`, trié par ordre croissant de poids.

### Exemples
```julia
neighbours = neighbours_node(monNode, monGraphe)
"""
function neighbours_node(n::AbstractNode, graph::ExtendedGraph)
  E = graph.edges
  neighbours = [] # vecteur qui contiendra les arêtes voisines

  for e in E
    if e.start_node == n || e.end_node == n # si n appartient à l'arête e
      push!(neighbours, e)
    end
  end
  return sort(neighbours, by=edge -> edge.weight)
end

"""
    Prim(graph::ExtendedGraph; st_node::AbstractNode = graph.nodes[1])

Implémente l'algorithme de Prim pour un graphe donné. Cet algorithme construit un arbre
couvrant de poids minimum à partir d'un graphe pondéré. Le noeud de départ par défaut est le premier
nœud du graphe, mais un noeud de départ différent peut être spécifié.

### Arguments
- `graph` : Le graphe sur lequel appliquer l'algorithme de Prim.
- `st_node` : Le noeud de départ pour l'algorithme. Par défaut, c'est le premier nœud du graphe.

### Retourne
Le graphe résultant après application de l'algorithme de Prim, sous forme d'un `ExtendedGraph`.

### Exemples
```julia
grapheResultant = Prim(monGraphe)
grapheResultant = Prim(monGraphe, st_node=monNode)
"""
function Prim(graph::ExtendedGraph; st_node::AbstractNode=graph.nodes[1])
  N = graph.nodes
  E = graph.edges
  graph_res = ExtendedGraph("res Prim", N, typeof(E[1])[])

  # On recherche st_node dans le graphe donné
  idx = findfirst(x -> x == st_node, N)
  if idx === nothing
    @warn "starting node not in graph"
    return
  end

  # Création de la file de priorité pour traiter les noeuds
  q = PriorityQueue([PriorityItem(Inf, n) for n in N])
  priority!(q.items[idx], 0)
  visited = Set{AbstractNode}() # Set pour vérifier les noeuds visités
  parent_map = Dict{AbstractNode, AbstractNode}() # Map pour les parents des noeuds

  # Boucle principale :
  while !isempty(q.items)
    u = pop_lowest!(q)
    push!(visited, u.data)

    # Vérifie si le noeud a un parent et ajoute l'arête correspondante dans graph_res
    if haskey(parent_map, u.data)
      edge_idx = findfirst(e -> (e.start_node == u.data && e.end_node == parent_map[u.data]) || (e.start_node == parent_map[u.data] && e.end_node == u.data), E)
      edge = E[edge_idx]
      push!(graph_res.edges, edge)
    end

    neighbours = neighbours_node(u.data, graph)

    for edge in neighbours
      v = edge.start_node === u.data ? edge.end_node : edge.start_node
      if !(v in visited) && edge.weight < get_priority(q, v)
        parent_map[v] = u.data
        update_priority!(q, v, edge.weight)
      end
    end
  end

  return graph_res
end


