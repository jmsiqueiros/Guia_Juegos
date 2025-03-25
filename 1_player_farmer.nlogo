extensions [ sound ]

globals [
  max-grass-height
  ;;densidad --- Ya está definida estar variable en donde se usa, como no se usa más en otros proceso, no vale la pena declararla como global, creo.
  temp_real ;;Temperartura promedio de la suma de los patches.
  temp_vecinos ;;Es la temperatura promedio de los vecinos
  T ;; Es la temperatura del sistema. Es una variable independiente
  years ;; Es la cuenta de años que pasan en el modelo
  count-ticks
  action
  ;weight_list
  avg_weight
  initial-weight ;; suma total inicial de las vacas antes de venderalas
  sold-weight ;; suma de los kg de vaca vendidos
  pesos ;; money owned by the player
]

breed [ cows cow ]
breed [trees tree ] ;; leucaena

patches-own [
  grass
  temperatura
]

cows-own[
  weight
  max-weight
]

trees-own[
 foliage

]

to setup
  clear-all

  set max-grass-height 10 ;; podría ser un slide

  set pesos n-pesos

  create-cows n-cows [
    move-to one-of patches ;; ver si quremos que sea aleatorio
    set shape "cow"
    set color 125 ;;black
    set weight 250 ;; ver si lo queremos así con un slide, o bien como variable global en el código
    set max-weight 650
  ]

  create-trees n-arboles [
    move-to one-of patches ;; ver si queremos que sea aleatorio
    set shape "tree"
  ]

 ask patches [
    if random 100 < densidad [
        set grass 10
    ]
   ifelse grass >= 0.5 [
      set pcolor scale-color (green) grass (max-grass-height) 0
  ] [
    set pcolor 38
  ]
]

  ask patches [
  set temperatura 23;; + random 15
  ]

  ask trees [
    set foliage 5
    set color 62
    set size 1
  ]

  reset-ticks
  set count-ticks 0
end

to go

  ;;if ticks mod 30 != 0  [ stop ]
  if count cows = 0 [ stop ] ;Detiene la simulación cuando ya no hay vacas

   ask cows [
    vaca-dead
    vacas-se-mueven
    vacas-comen-foliage
    vaca-eat-grass
    vaca-set-temperature

    ;;vaca-explora
  ]

  size-foliage ;; corregir la cuenta regresiva en el tamaño y la muerte de los árboles. Mueren en el 4 paso.

  tree-dead

  ask patches [
    grow-grass
    color-grass
  ]


  temp_patch
  years_passed
  update-global
  ;set weight_list [ (list weight ) ] of cows
  ;print weight_list

  tick
  set count-ticks count-ticks + 1

  ifelse Juego? [if count-ticks mod revisar_rancho = 0 ;Esto es para que la simulación pare cada 360 ticks y el jugador pueda tomar una decisión
    [ stop ]
  ] [set count-ticks count-ticks + 1]

plant

end

;; Procedures

;;Procedimientos relativos a la hierba

to grow-grass  ;; patch procedure
  (ifelse grass >= 9.5 [
      set grass max-grass-height
    ]
    grass = 0 [
      set grass 0
    ] [
    set grass grass + 0.1 ;; antes estaba a 0.5. Lo cambié para que la hierba tarde más en crecer.
    ]
    )

end

to color-grass  ;; patch procedure
   ifelse grass >= 0.5 [
      set pcolor scale-color (green) grass (max-grass-height) 0
  ] [
    set pcolor 38
  ]

end

;;Procedimientos relativos a los árboles

to size-foliage
  ask trees  [
  ifelse any? other cows-here
    [ set foliage foliage - 0.5 ] ;; cambié estos valores para que los árboles puedan terminarse
    [ set foliage foliage + 0.5 ]  ;; cambié de 0.1 a 0.5 porque si no las vacas se los comían enseguida
  ]

end

to tree-dead ;;COMENTE ESTO PARA QUE LOS ÁRBOLES NO SE MUERAN Y VER EL EFECTO QUE TIENEN EN LA DINÁMICA DEL SISTEMA
  ask trees [
    if foliage <= 1 [ die ]
    ;; Lo que voy a intentar hacer ahora es que en lugar de que mueran, esperen un n de ticks antes de comenzar a crecer foliage de nuevo
  ]

end

;; PROCEDIMIENTOS RELATIVOS A LAS VACAS

;;to move
;;  ifelse (si no hay árboles ni hierba) ; tal vez también quiera moverse si no encuentra sombra
  ;; primero que busque árboles
  ;; segundo que busque hierba si no hay árboles
;;  rt random-float 360
;;  fd random-float 1

;;end

to vaca-set-temperature
;  ask cows-here [
;    (ifelse
;      temperatura >= 40 [ ;;reduje la temperatura máx que pueden soportar la vacas
;        set weight weight - 1.5 ;; originalmente decía 0.2
;      ]
;      temperatura < 30 [
;        set weight weight
;      ]
;      [
;        set weight weight - 1.0 ;; originalmente decía 0.1
;      ]
;      )

    ask cows-here [
    (ifelse
      temperatura >= 36 [ ;;reduje la temperatura máx que pueden soportar la vacas
        set weight weight - 1.5 ;; originalmente decía 0.2
      ]
      temperatura < 10 [
        set weight weight - 1.0 ;; originalmente decía 0.1
      ]
      [
        set weight weight
      ]
      )
  ]

end

to vaca-eat-grass
  ask cows-here [
    if pcolor != 38 [
      set grass grass - 0.51
    if weight < max-weight
    [ set weight weight + 0.4 ] ;Leí en el internet que las vacas pueden subir alrededor de 2 kilos por día, pero vi que oscilaba entre 330 y 800 gramos al día.
    ]
  ]

end

;; Cambio el aumento de peso de 10 a 0.4
to vacas-comen-foliage
  ask cows-here  [
  if any? other trees-here [
    if weight < max-weight
    [ set weight weight + 0.7 ] ;;Leí en el internet que las vacas pueden subir alrededor de 2 kilos por día, pero vi que oscilaba entre 330 y 800 gramos al día.
  ] ]

end

;; Cambio la variación de peso diaria a -0.1 en lugar de -2
to vacas-se-mueven ;; Las vacas se deben mover cuando no hay comida. Ahora las vacas no se mueven de donde hay un árbol porque el árbol sigue ahí
                   ;; aun cuando tienen foliage negativo. Lo que hay que hacer es que cuando foliage = 0, y no hay hierba, la vaca se mueve
ask cows-here [
  ifelse not any? trees-here and grass < 1
    [ rt random 360
      fd random-float 3
      set weight weight - 1.5
    ]
    [ stop ]
  ]
  ;;set weight weight - 1.0 ;;  Puse esta linea dentro de las acciones del "if" porque estando afuera, las vacas perdían peso aun si estaban comiendo, de este modo, sólo pierden peso si no hay comida y se mueven

end

to vaca-dead
  ask cows-here [
    if weight < 200 [ die ]
  ]

end

;; PROCEDIMIENTOS RELATIVOS A LA TEMPERATURA

to temp_patch
  ;;cambiar_temp
  change_in_cycle
  ask patches [

;  COMENTÉ ESTAS LINEAS PORQUE OBTENER LA TEMPERATURA DE UN PATCH EN FUNCIÓN DE SUS VECINOS HACE QUE LA TEMPERATURA DEL RANCHO SE HOMOGENICE
;  DE MODO QUE NO HAY PATCHES VERDADERAMENTE CALIENTES
    ;;set temp_vecinos mean [ temperatura ] of  neighbors ;; Calcula la temperatura promedio de los patches vecinos de un patch cualquiera
    ;let delta temp_vecinos - temperatura ;; delta es la diferencia entre la temperatura promedio de los patches vecinos y el patch interrogado
    ;set temperatura temperatura + delta ;; EL EFECTO DEL PROMEDIADO ES EL DE UN BUFFER DE LA TEMPERATURA

    ;;set temperatura temp_vecinos ;; el parch adopta la teperatura promedio del sus vecinos
    set temperatura T

;    set temperatura temperatura + T ;; La actualización de la temperatura del patch es su temperatura en en t_1 + la Temperatura global

    (ifelse

      any? other trees-here [
        set temperatura temperatura - ( T * 0.25 )

      ]

      grass < 4 [

        set temperatura temperatura + ( T * 0.25)

      ]

      grass > 3 [

       set temperatura temperatura - ( T * 0.1)

      ]

    )

]



end

;to cambiar_temp
;  change_in_cycle
;  ;;let theta random-float ruido_clima ; debe ser entre un número negativo y uno positivo, por ejemolo random-float -1,1
;  ;;set ruido ( theta * A )
;
;end

to update-global
  let all-patches_temp sum [ temperatura ] of patches
  set temp_real ( all-patches_temp / 121 )
  ;set avg_weight sum(weight)/ count cows
  ;;show all-patches_temp
  ;;show temp_real

end

to change_in_cycle ;; es el valor de la curva en cada tick o día. Puede verse cómo la temperatura de cada día o el cambio de la temperatura de cada día
                   ;; respecto al baseline (que tipicamente es 0). Hay dos opciones para resolver el problema: a) Que los máx y min sean las temperaturas
                   ;; reales, por decir 45 y 15; o b) que la amplitud en un tiempo específico marque cuántos grado se aleja ese día de la temperatura promedio
                   ;; Por ejemplo, que la temperatura máxima que se separa del promedio sea 10ºC, es decir la Amplitud de pico a pico sea de 20ºC.
  let dia ticks
  set T 26 + (sin(dia) * 8.7 ) ;definir la temperatura global. 26 es la temperatura promedio anaul de Yucatán y multiplicado por 8.x para que la amplitud max y min crezcan a temperaturas reales
  ;;set T sin(dia) ;la formula orginal de amplitud en cada tick

end

;; ACCIONES DEL JUGADOR7 GANADERO

to plant

  decisions

end


to decisions
  if (action != 0)
    [ if (action = 1)
      [ plant_trees_b ]
      if (action = 2)
        [ plant_grass ]
      if (action = 3)
        [ sell_cows]
      if (action = 4)
        [ add_cows]
      ;sound:play-drum "COWBELL" 50
      sound:play-note "TINKLE BELL" 72 64 1 ;;El primer número es la nota --60 es Do central en el piano-, el sgundo es "loudness" y el tercero el tiempo que suena. Ver: https://ccl.northwestern.edu/netlogo/docs/sound.html
      set action 0
    ]
end

to plant_trees ;; Falta definir cuánto cuesta pagar por cada árbol sembrado
               ;; hatch-trees reproduce a los árboles el n-arboles-plantar
               ;; Si hay 2 arboles y n-arboles-plantar es 3, entonces habrá 6 árboles
  ask trees [
    hatch-trees n-arboles-plantar - 1 [
       move-to one-of patches ;;
       set shape "tree"
    ]

     set pesos pesos - (n-arboles-plantar * precio-arbol)

  ]

end

;to plant_trees_b ;; Falta definir cuánto cuesta pagar por cada árbol sembrado
;                 ;; Esta es la alternativa con create-trees; tampoco funciona con srpout
;  create-trees n-arboles-plantar
;    ask trees [
;       move-to one-of patches ;;
;       set shape "tree"
;       set color 62
;    ]
;
;
;end

to plant_trees_b
  (ifelse pesos - (n-arboles-plantar * precio-arbol) < 0 [
    user-message (word "En este momento no dispones de " (n-arboles-plantar * precio-arbol) " pesos.")
  ] [
    ask n-of n-arboles-plantar patches [
      sprout-trees 1 [
        set shape "tree"
        set foliage 5
        set color 62
        set size 1
        set pesos pesos - precio-arbol
      ]
    ]
    ]
    )

end

to plant_grass ;;Falta definir cuánto cuesta pagar por área de hierba sembrada
               ;; Al parecer añadir hierba funciona bien
  (ifelse pesos - ((superficie_zacate * precio-zacate) * 121 / 100) < 0 [
    user-message (word "En este momento no dispones de " (superficie_zacate * precio-zacate) " pesos.")
    ] [
    ask patches [
      if random 100 < superficie_zacate[
        set grass 10
        set pesos pesos - precio-zacate * 121 / 100 ;; he añadido esto para controlar el número de patches y poder calcular los pesos, pero parece que es aleatorio
      ]
    ]
    ]
    )

end

to sell_cows
  set initial-weight (sum [weight] of cows)

  (ifelse (count cows) - n-vacas-vender >= 0 [
    ask n-of n-vacas-vender cows [die] ] [
    user-message (word "En este momento no dispones de " n-vacas-vender " vacas.")
    ]
    ) ;; funciona pero vende las vacas de manera aleatoria (igual podríamos hacer que venda las más gordas...)

  set sold-weight initial-weight - (sum [weight] of cows)

  set pesos pesos + (sold-weight * precio-kilo) ;; según http://infosiap.siap.gob.mx/anpecuario_siapx_gobmx/CarneenCanal.do;jsessionid=9172D4E0F19EF33C57C42608DEE15435

  ;; numero de vacas a vender, sumar su peso y multiplicarlo por el precio del kilo de ganado y eso es igual al dinero ganado. Se actualiza la variable ganado

end

to add_cows

  (ifelse pesos - (n-terneros * precio-ternero) < 0 [
    user-message (word "En este momento no dispones de " (n-terneros * precio-ternero) " pesos.")
  ] [
    create-cows n-terneros [
    move-to one-of patches ;; ver si quremos que sea aleatorio
    set shape "cow"
    set color 125 ;;black
    set weight 250 ;; ver si lo queremos así con un slide, o bien como variable global en el código
    set max-weight 650
    set pesos pesos - (n-terneros * precio-ternero)
    ]
  ]
    )

;to add_cows
  ;; Esta otra versión del añadir terneros no tiene un precio fijo, sino que depende del precio por kilo. Los terneros pesan 250 y su precio sería 250 por lo que cuesta el kilo.
  ;; Ahora asumiendo que el kilo del ternero cuesta lo mismo que el kilo de vaca a la venta. Seguro, es distinto el precio de compra y el precio de venta. Esto se puede arreglar en el slide de peso-tenero
;  set precio-ternero 250 * precio-kilo
;  (ifelse pesos - (n-terneros * precio-ternero) < 0 [
;    user-message (word "En este momento no dispones de " (n-terneros * precio-ternero) " pesos.")
;  ] [
;    create-cows n-terneros [
;    move-to one-of patches ;; ver si quremos que sea aleatorio
;    set shape "cow"
;    set color 125 ;;black
;    set weight 250 ;; ver si lo queremos así con un slide, o bien como variable global en el código
;    set max-weight 650
;    set pesos pesos - (n-terneros * precio-ternero)
;    ]
;  ]
;    )



end

to years_passed ;;cuenta de años

  let cuenta ticks mod 360

  if cuenta = 0

  [ set years years + 1 ]

end
@#$#@#$#@
GRAPHICS-WINDOW
770
28
1198
457
-1
-1
38.2
1
10
1
1
1
0
0
0
1
-5
5
-5
5
0
0
1
ticks
30.0

BUTTON
75
41
141
74
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
167
42
230
75
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
252
44
315
77
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
74
136
317
169
n-arboles
n-arboles
0
350
71.0
1
1
NIL
HORIZONTAL

MONITOR
83
279
187
324
Dinero
pesos
17
1
11

PLOT
559
42
759
192
Vacas
tiempo
N-vacas
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count cows"

PLOT
350
41
550
191
Árboles
tiempo
N-árboles
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count trees"

PLOT
351
201
758
440
Temperatura del rancho (Avg. de temp. de patches)
Temp-global
Temp-local
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot temp_real"

SLIDER
74
184
317
217
densidad
densidad
0
100
36.0
1
1
NIL
HORIZONTAL

SLIDER
73
231
318
264
n-pesos
n-pesos
0
1000
500.0
1
1
NIL
HORIZONTAL

BUTTON
69
390
202
423
sembrar árboles
set action 1
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
70
435
203
468
sembrar zacate
set action 2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
71
521
204
554
vender vacas
sell_cows
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
208
391
323
424
n-arboles-plantar
n-arboles-plantar
0
50
5.0
1
1
NIL
HORIZONTAL

SLIDER
209
436
325
469
superficie_zacate
superficie_zacate
0
100
38.0
1
1
NIL
HORIZONTAL

SLIDER
209
521
325
554
n-vacas-vender
n-vacas-vender
0
100
7.0
1
1
NIL
HORIZONTAL

PLOT
353
464
759
719
Temperatura global
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot T"

MONITOR
219
278
315
323
Años
years
17
1
11

SLIDER
74
96
318
129
n-cows
n-cows
0
100
9.0
1
1
NIL
HORIZONTAL

MONITOR
219
333
315
378
Días
count-ticks
17
1
11

CHOOSER
65
564
203
609
revisar_rancho
revisar_rancho
15 30 90 180 360
1

SWITCH
75
617
178
650
Juego?
Juego?
0
1
-1000

PLOT
771
466
1198
717
Peso promedio de las vacas
Tiempo
Peso
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [weight] of cows"

SLIDER
209
559
325
592
precio-kilo
precio-kilo
0
100
10.0
1
1
NIL
HORIZONTAL

BUTTON
71
479
205
512
comprar terneros
set action 4
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
208
478
327
511
n-terneros
n-terneros
0
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
208
600
327
633
precio-ternero
precio-ternero
0
3000
462.0
1
1
NIL
HORIZONTAL

SLIDER
208
638
329
671
precio-arbol
precio-arbol
0
2000
100.0
1
1
NIL
HORIZONTAL

SLIDER
209
679
330
712
precio-zacate
precio-zacate
0
100
20.0
1
1
NIL
HORIZONTAL

MONITOR
83
333
168
378
Num. Vacas
count cows
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
