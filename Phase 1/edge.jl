#################################
########### Phase 1 #############
#################################
import Base.==
abstract type AbstractEdge{T, U} end

mutable struct Edge{T, U} <: AbstractEdge{T, U}
  start_node::Node{T}
  end_node::Node{T}
  weight::U
end

Edge(s::Node{T}, e::Node{T}) where T = Edge(s, e, nothing)

start_node(edge::AbstractEdge) = edge.start_node
end_node(edge::AbstractEdge) = edge.end_node
weight(edge::AbstractEdge) = edge.weight

function show(edge::AbstractEdge)
    if edge.weight === nothing
        println("Edge from ", name(start_node(edge)), " to ", name(end_node(edge)))
    else
        println("Edge from ", name(start_node(edge)), " to ", name(end_node(edge)), ", weight: ", weight(edge))
    end
end  


"""Analyse un fichier .tsp et renvoie l'ensemble des arêtes sous la forme d'un tableau."""
function read_edges(header::Dict{String, String}, filename::String)

  edges = []
  edge_weight_format = header["EDGE_WEIGHT_FORMAT"]
  known_edge_weight_formats = ["FULL_MATRIX", "UPPER_ROW", "LOWER_ROW",
  "UPPER_DIAG_ROW", "LOWER_DIAG_ROW", "UPPER_COL", "LOWER_COL",
  "UPPER_DIAG_COL", "LOWER_DIAG_COL"]

  if !(edge_weight_format in known_edge_weight_formats)
      @warn "unknown edge weight format" edge_weight_format
      return edges, edge_weights
  end

  file = open(filename, "r")
  dim = parse(Int, header["DIMENSION"])
  edge_weight_section = false
  k = 0
  n_edges = 0
  i = 0
  n_to_read = n_nodes_to_read(edge_weight_format, k, dim)
  flag = false

  for line in eachline(file)
      line = strip(line)
      if !flag
          if occursin(r"^EDGE_WEIGHT_SECTION", line)
              edge_weight_section = true
              continue
          end

          if edge_weight_section
              data = split(line)
              n_data = length(data)
              start = 0
              while n_data > 0
                  n_on_this_line = min(n_to_read, n_data)

                  for j = start : start + n_on_this_line - 1
                    # Les lignes suivantes ont été modifiées pour tenir compte du poids des arêtes
                    n_edges = n_edges + 1
                    edge_weight_value = parse(Float64, data[start+j+1])
                    if edge_weight_format in ["UPPER_ROW", "LOWER_COL"]
                      edge = (k+1, i+k+2, edge_weight_value)
                    elseif edge_weight_format in ["UPPER_DIAG_ROW", "LOWER_DIAG_COL"]
                      edge = (k+1, i+k+1, edge_weight_value)
                    elseif edge_weight_format in ["UPPER_COL", "LOWER_ROW"]
                      edge = (i+k+2, k+1, edge_weight_value)
                    elseif edge_weight_format in ["UPPER_DIAG_COL", "LOWER_DIAG_ROW"]
                      edge = (i+1, k+1, edge_weight_value)
                    elseif edge_weight_format == "FULL_MATRIX"
                      edge = (k+1, i+1, edge_weight_value)
                    else
                      warn("Unknown format - function read_edges")
                    end
                    push!(edges, edge)
                    i += 1
                  end

                  n_to_read -= n_on_this_line
                  n_data -= n_on_this_line

                  if n_to_read <= 0
                      start += n_on_this_line
                      k += 1
                      i = 0
                      n_to_read = n_nodes_to_read(edge_weight_format, k, dim)
                  end

                  if k >= dim
                      n_data = 0
                      flag = true
                  end
              end
          end
      end
  end
  close(file)
  return edges
end

"""Compare deux arêtes"""
function ==(e1::Edge, e2::Edge)
  return (e1.start_node==e2.start_node && e1.end_node==e2.end_node && e1.weight==e2.weight) ||
        (e1.start_node == e2.end_node && e1.end_node == e2.start_node && e1.weight == e2.weight)
end
