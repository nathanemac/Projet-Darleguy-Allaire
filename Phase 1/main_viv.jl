include("node.jl")
include("graph.jl")
include("read_stsp.jl")
include("edge.jl")



"""Construit un graphe à partir d'une instance TSP symétrique dont les poids sont donnés au format EXPLICIT et renvoie l'objet Graph associé"""
function build_graph(instance::String, title::String)
  
  header = read_header(instance)
  if header["EDGE_WEIGHT_TYPE"] != "EXPLICIT"
    @warn "weight type format must be `EXPLICIT`"
    return "Current format is :", header["EDGE_WEIGHT_TYPE"]
  end
  if header["EDGE_WEIGHT_FORMAT"] != "FULL_MATRIX"
    @warn "edge weight format must be `FULL_MATRIX`"
    return "Current format is :", header["EDGE_WEIGHT_FORMAT"]
  end

  nodes_graph = read_nodes(header, instance)
  edges_graph = read_edges(header, instance)

  if isempty(nodes_graph)
    for i = 1:parse(Int64, header["DIMENSION"])
      dict_intermediaire = Dict(i => [])
      merge!(nodes_graph, dict_intermediaire)
    end
  end


  graph_built = ExtendedGraph(title, [Node("1", nodes_graph[1])])
  for i=2:length(nodes_graph)
    node = Node(string(i), nodes_graph[i])
    add_node!(graph_built, node)
  end

  for i=1:length(edges_graph)
    s_node = graph_built.nodes[edges_graph[i][1]]
    e_node = graph_built.nodes[edges_graph[i][2]]
    w_edge = edges_graph[i][3]
    add_edge!(graph_built, s_node, e_node, w_edge)
  end
  show(graph_built)
end

# Exemple d'utilisation du fichier main : 
# build_graph("C:/Users/victo/OneDrive/Documents/Cours/MTH6412B/TP/Projet/Phase 1/instances/stsp/bays29.tsp", "Graph_Test")

# Fonction pour extraire la valeur d'une clé à partir d'un fichier TSP
function get_tsp_field_value(filename::String, field::String)
    value = ""
    file = open(filename, "r")
    for line in eachline(file)
        if startswith(line, field)
            value = strip(split(line, ":")[2])
            break
        end
    end
    close(file)
    return value
end

# Dossier contenant les fichiers TSP
directory = "C:/Users/victo/OneDrive/Documents/Cours/MTH6412B/TP/Projet/Phase 1/instances/stsp/"

# Parcourir les fichiers du dossier
for file in readdir(directory)
    filepath = joinpath(directory, file)
    if isfile(filepath) && endswith(file, ".tsp")
        edge_weight_type = get_tsp_field_value(filepath, "EDGE_WEIGHT_TYPE")
        edge_weight_format = get_tsp_field_value(filepath, "EDGE_WEIGHT_FORMAT")
        println("Nom du fichier: $file")
        if edge_weight_type == "EXPLICIT"
            println("Type de header: EXPLICIT")
            if edge_weight_format == "FULL_MATRIX"
                println("Type de format: FULL_MATRIX")
                build_graph(filepath, "Graph_Test")
            else
                println("Type de format: Non FULL_MATRIX")
                build_graph(filepath, "Graph_Test")
            end
        else
            println("Type de header: Non EXPLICIT")
            build_graph(filepath, "Graph_Test")
        end
        
    end
end