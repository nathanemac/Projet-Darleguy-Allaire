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

#############################################################################################
#############################################################################################
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
function create_tour_HK(graph::ExtendedGraph)
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

function cost_tour(graph::ExtendedGraph, tour::Vector{String})
  cost = 0.
  edge_weights1 = Dict((edge.start_node.name, edge.end_node.name) => edge.weight for edge in graph.edges)
  edge_weights2 = Dict((edge.end_node.name, edge.start_node.name) => edge.weight for edge in graph.edges)
  dict_weights = merge(edge_weights1, edge_weights2)

  for i=2:length(tour)
    n1 = tour[i-1]
    n2 = tour[i]
    cost += dict_weights[n1, n2]
  end
  return cost
end

write_tour("tour cours", create_tour(r), Float32(cost_tour_HK(r)))
# Ok fonctionne. A faire ensuite avec une tournée de RSL (vu que HL converge pas)

# Test avec un tour donné
tour_test = "Phase 4/shredder-julia/tsp/tours/alaska-railroad.tour"
reconstruct_picture(tour_test, "Phase 4/shredder-julia/images/shuffled/alaska-railroad.png", "photo_train.png")
# Ok fonctionne pour un fichier tour donné. 

#### Depuis le début avec un tsp : ####
graph_bays29_rsl = build_graph("Phase 1/instances/stsp/bays29.tsp", "Graph_Test")
graph = deepcopy(graph_bays29_rsl)
prim = Prim(graph)
visited_nodes = Set{Node}()
root_node = prim.nodes[1]  
r = RSL!(prim, root_node, root_node, visited_nodes) 

cost = cost_tour(graph_bays29_rsl, r)
#############################################################################################
#############################################################################################

### On passe aux vraies images ###
# 1)
photo = build_graph("Phase 4/shredder-julia/tsp/instances/alaska-railroad.tsp", "Alaska Railroad")
photo_sans_0 = remove_node_and_edges(photo, photo.nodes[1])
tour = RSL(photo_sans_0)
tour_parsed = parse.(Int, tour)
tour_parsed .-= 1
write_tour("alaska-railroad RSL.tour", tour_parsed, Float32(cost_tour(photo, tour)))
tour_filename = "alaska-railroad RSL.tour"
reconstruct_picture(tour_filename, "Phase 4/shredder-julia/images/shuffled/alaska-railroad.png", "photo_train_rsl.png", view=true)
cost_1 = cost_tour(photo_sans_0, tour)

function tour_opti1()
  tour_opti = [
  173
  355
  65
  398
  424
  169
  276
  425
  387
  561
  383
  579
  285
  539
  130
  301
  588
  60
  580
  344
  540
  106
  121
  391
  551
  61
  505
  279
  129
  220
  55
  482
  568
  590
  5
  370
  108
  452
  601
  150
  465
  385
  198
  298
  77
  289
  281
  34
  572
  273
  417
  483
  463
  152
  453
  39
  21
  365
  373
  237
  567
  167
  192
  435
  509
  494
  498
  323
  549
  522
  576
  448
  48
  473
  488
  555
  367
  33
  171
  508
  470
  67
  75
  10
  486
  441
  519
  80
  409
  49
  163
  381
  484
  306
  430
  340
  497
  45
  266
  227
  128
  427
  421
  194
  212
  326
  433
  54
  309
  458
  592
  552
  578
  481
  255
  179
  244
  485
  257
  548
  518
  149
  42
  312
  571
  105
  200
  256
  199
  489
  182
  337
  502
  263
  528
  404
  52
  415
  87
  13
  104
  402
  560
  235
  477
  583
  144
  570
  24
  177
  107
  311
  374
  261
  219
  450
  479
  575
  260
  86
  359
  239
  236
  563
  117
  536
  547
  203
  354
  457
  462
  47
  342
  157
  331
  511
  64
  334
  165
  500
  272
  103
  189
  395
  109
  526
  322
  240
  414
  532
  209
  507
  384
  382
  32
  436
  226
  123
  351
  294
  233
  598
  135
  168
  112
  147
  51
  22
  186
  70
  172
  78
  375
  287
  506
  19
  480
  320
  245
  524
  499
  41
  594
  250
  72
  460
  232
  455
  88
  440
  419
  445
  408
  503
  431
  58
  504
  293
  197
  332
  125
  313
  201
  31
  258
  360
  204
  247
  217
  16
  243
  443
  545
  286
  444
  265
  422
  211
  521
  584
  207
  297
  329
  595
  454
  318
  350
  231
  308
  569
  113
  541
  20
  392
  159
  234
  269
  577
  96
  596
  411
  300
  268
  53
  469
  14
  538
  529
  472
  196
  126
  206
  139
  85
  346
  413
  525
  397
  589
  352
  558
  259
  491
  358
  305
  290
  378
  116
  467
  447
  423
  122
  23
  191
  599
  63
  299
  246
  59
  316
  146
  439
  94
  566
  127
  29
  71
  464
  556
  336
  325
  137
  99
  225
  396
  136
  131
  91
  394
  92
  362
  399
  69
  366
  371
  330
  4
  438
  582
  6
  215
  513
  74
  185
  145
  564
  345
  176
  230
  134
  535
  496
  170
  372
  175
  339
  284
  224
  35
  228
  543
  468
  114
  554
  349
  124
  356
  319
  242
  557
  164
  393
  216
  89
  310
  341
  120
  38
  66
  143
  187
  600
  410
  386
  277
  111
  412
  432
  353
  79
  267
  156
  118
  83
  162
  253
  363
  15
  238
  493
  335
  184
  520
  307
  252
  76
  459
  28
  110
  214
  102
  587
  283
  9
  36
  368
  218
  8
  328
  348
  73
  12
  44
  380
  451
  442
  153
  155
  474
  84
  188
  271
  100
  475
  530
  17
  40
  581
  181
  2
  314
  565
  478
  405
  501
  429
  195
  487
  324
  57
  407
  292
  93
  389
  166
  544
  46
  280
  160
  151
  364
  183
  531
  56
  221
  533
  361
  222
  449
  302
  26
  296
  282
  428
  403
  420
  213
  241
  418
  369
  133
  98
  437
  90
  376
  274
  7
  446
  101
  190
  390
  154
  434
  574
  43
  288
  516
  562
  132
  495
  275
  347
  321
  593
  388
  315
  416
  148
  115
  138
  317
  490
  140
  264
  591
  249
  585
  400
  426
  333
  95
  456
  223
  262
  68
  377
  254
  174
  586
  461
  81
  559
  327
  158
  119
  142
  141
  514
  205
  573
  3
  303
  270
  471
  161
  527
  25
  304
  180
  295
  512
  178
  510
  357
  401
  210
  251
  542
  476
  50
  338
  278
  466
  11
  291
  534
  343
  202
  97
  248
  597
  37
  193
  379
  406
  537
  492
  517
  546
  30
  523
  229
  27
  82
  62
  550
  515
  208
  18
  553]
  return map(string, tour_opti)
end
tour_opti_1 = tour_opti1()
cost_1_opti = cost_tour(photo_sans_0, tour_opti_1)


# 2)
photo2 = build_graph("Phase 4/shredder-julia/tsp/instances/pizza-food-wallpaper.tsp", "Pizza")
photo2_sans_0 = remove_node_and_edges(photo2, photo2.nodes[1])
tour2 = RSL(photo2_sans_0)
tour_parsed2 = parse.(Int, tour2)
tour_parsed2 .-= 1
write_tour("pizza RSL.tour", tour_parsed2, Float32(cost_tour(photo2, tour2)))
tour_filename = "pizza RSL.tour"
reconstruct_picture(tour_filename, "Phase 4/shredder-julia/images/shuffled/pizza-food-wallpaper.png", "photo_pizza_rsl.png", view=true)
cost_2 = cost_tour(photo2, tour2)

# 3)
photo3 = build_graph("Phase 4/shredder-julia/tsp/instances/blue-hour-paris.tsp", "Paris")
photo3_sans_0 = remove_node_and_edges(photo3, photo3.nodes[1])
tour3 = RSL(photo3_sans_0)
tour_parsed3 = parse.(Int, tour3)
tour_parsed3 .-= 1
write_tour("paris RSL.tour", tour_parsed3, Float32(cost_tour(photo3, tour3)))
tour_filename = "paris RSL.tour"
reconstruct_picture(tour_filename, "Phase 4/shredder-julia/images/shuffled/blue-hour-paris.png", "photo_paris_rsl.png", view=true)
cost_3 = cost_tour(photo3, tour3)

# 4)
photo4 = build_graph("Phase 4/shredder-julia/tsp/instances/nikos-cat.tsp", "Cat")
photo4_sans_0 = remove_node_and_edges(photo4, photo4.nodes[1])
tour4 = RSL(photo4_sans_0)
tour_parsed4 = parse.(Int, tour4)
tour_parsed4 .-= 1
write_tour("cat RSL.tour", tour_parsed4, Float32(cost_tour(photo4, tour4)))
tour_filename = "cat RSL.tour"
reconstruct_picture(tour_filename, "Phase 4/shredder-julia/images/shuffled/nikos-cat.png", "photo_cat_rsl.png", view=true)
cost_4 = cost_tour(photo4, tour4)
