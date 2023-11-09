import Base.isless, Base.==, Base.popfirst!

# AbstractPriorityItem est une structure de données abstraite pour les éléments de file de priorité.
"""
    AbstractPriorityItem{T}

Structure de base abstraite pour les éléments qui seront utilisés dans une file de priorité.
`T` est le type de donnée encapsulé dans l'élément de priorité.
"""
abstract type AbstractPriorityItem{T} end

# PriorityItem est une implémentation concrète d'un élément de file de priorité.
"""
    mutable struct PriorityItem{T} <: AbstractPriorityItem{T}

Implémente un élément de priorité avec une `priorité` et des `données`.
- `priority` est un `Number` indiquant la priorité de l'élément.
- `data` est la donnée de type `T` stockée dans l'élément.
"""
mutable struct PriorityItem{T} <: AbstractPriorityItem{T}
  priority::Number
  data::T
end

# PriorityItem est le constructeur pour créer un nouvel élément de priorité.
"""
    PriorityItem(priority::Number, data::T)

Constructeur pour `PriorityItem`. Prend en compte une `priorité` et des `données` pour créer un nouvel élément.
La priorité est ajustée pour ne jamais être inférieure à zéro.
"""
function PriorityItem(priority::Number, data::T) where T
  PriorityItem{T}(max(0, priority), data)
end

# priority retourne la priorité d'un PriorityItem.
"""
    priority(p::PriorityItem)

Renvoie la priorité de l'élément de priorité `p`.
"""
priority(p::PriorityItem) = p.priority

# priority! modifie la priorité d'un PriorityItem.
"""
    priority!(p::PriorityItem, priority::Number)

Modifie la valeur de la priorité de l'élément `p` avec la nouvelle `priorité`.
La nouvelle priorité est ajustée pour ne jamais être inférieure à zéro.
"""
function priority!(p::PriorityItem, priority::Number)
  p.priority = max(0, priority)
  p
end

# Redéfinition des opérateurs isless et == pour PriorityItem.
isless(p::PriorityItem, q::PriorityItem) = priority(p) < priority(q)
==(p::PriorityItem, q::PriorityItem) = priority(p) == priority(q)

# AbstractQueue est une structure de données abstraite pour les files.
"""
    AbstractQueue{T}

Structure de base abstraite pour les files qui seront utilisées pour gérer les éléments de priorité.
`T` est le type spécifique des éléments de priorité utilisés dans la file.
"""
abstract type AbstractQueue{T} end

# PriorityQueue est une implémentation concrète d'une file de priorité.
"""
    mutable struct PriorityQueue{T <: AbstractPriorityItem} <: AbstractQueue{T}

Implémente une file de priorité qui utilise un `Vector` pour stocker les éléments de type `T`.
"""
mutable struct PriorityQueue{T <: AbstractPriorityItem} <: AbstractQueue{T}
  items::Vector{T}
end

# PriorityQueue est le constructeur pour créer une nouvelle file de priorité.
PriorityQueue{T}() where T = PriorityQueue(T[])

# pop_lowest! retire et renvoie l'élément avec la plus faible priorité.
"""
    pop_lowest!(q::PriorityQueue)

Retire et renvoie l'élément ayant la plus faible priorité de la file de priorité `q`.
"""
function pop_lowest!(q::PriorityQueue)
  lowest = q.items[1]
  for item in q.items[2:end]
    if item < lowest
      lowest = item
    end
  end
  idx = findfirst(x -> x == lowest, q.items)
  deleteat!(q.items, idx)
  lowest
end

# update_priority! modifie la priorité d'un élément dans la file.
"""
    update_priority!(q::PriorityQueue, item_data, new_priority)

Modifie la priorité d'un élément spécifique dans la file de priorité `q`.
`item_data` est la donnée de l'élément à modifier.
`new_priority` est la nouvelle priorité à attribuer à l'élément.
"""
function update_priority!(q::PriorityQueue, item_data, new_priority)
  for pi in q.items
    if pi.data == item_data
      priority!(pi, new_priority)
      return
    end
  end
end

# get_priority renvoie la priorité d'un élément spécifique ou Inf si non trouvé.
"""
    get_priority(q::PriorityQueue, item_data)

Renvoie la priorité d'un élément spécifique dans la file de priorité `q`.
`item_data` est la donnée de l'élément dont la priorité est demandée.
Renvoie `Inf` si l'élément n'est pas trouvé dans la file.
"""
function get_priority(q::PriorityQueue, item_data)
  for pi in q.items
    if pi.data == item_data
      return pi.priority
    end
  end
  return Inf # Si l'élément n'est pas trouvé dans la file de priorité
end
