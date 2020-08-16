; Written by Udi Aharoni
; Based on Axelrod, Robert. “An Evolutionary Approach to Norms.” The American Political Science Review, vol. 80, no. 4, 1986, pp. 1095–1111. JSTOR, www.jstor.org/stable/1960858. Accessed 6 July 2020.

; Global variables:
globals [

  seen             ; chance of being seen (S in the paper)
  step             ; current step in the game

  adjustedSeen     ; experimental stuff
]


; turtle variables
turtles-own [

  ; the two strategy properties
  vengeful
  bold

  defect?  ; did this turtle defect
  sawDefector?    ; has this turtle seen a defector
  punished? ; has this turtle punished a defector

  score ; total score accumulated during the game

  reproduceScore ; 0,1,2 score, used to determined number of offsprings.

  numOffsprings ; number of offsprings this turtle will have

  new?  ; technical stuff: indication whether this turtle belongs to the next generation

]

; Define two types of links (shown as arrows)
directed-link-breed [ observations observation ]     ; link for A observed B defecting
directed-link-breed [ observations2 observation2 ]   ; link for A observed B seeing but not punihsing a defector

; The setup function:
to setup

  ; clear everything and color all patches white
  clear-all
  ask patches [
    set pcolor white
  ]

  ; set the global 'step' variable to 'init'
  ; this variable is monitored in the GUI
  set step "init"

  ; create popSize turtles
  create-turtles popSize

  ; init all turtles

  ask turtles [
    ; draw random values for strategy properties between 0 and 1
    ;set bold  random-float 1
    ;set vengeful  random-float 1

    set bold  random-normal init-mean-boldness init-std-boldness
    set vengeful random-normal init-mean-vengefulness init-std-vengefulness

    ; color, shape, and init flags
    set color 27
    set shape "circle"
    set label-color black
    set size 1.2

    set defect? false
    set new? false
    set sawDefector? false
    set punished? false
    set reproduceScore -1
    set numOffsprings 0


  ]


  ; update turtles (see description below)
  update-turtles-full

  reset-ticks
end

; This procedure is called after init and after reproduce
; It makes sure all turtles are in a valid state
; And updates their display properties
to update-turtles-full
  ask turtles [

    ; this is equivalent to bold=max(bold,0), to make sure bold is not below 0
    set bold  max list  bold  0
    ; this is equivalent to bold=min(bold,1), to make sure bold is not above 1
    set bold  min list  bold  1
    ; same for vengeful
    set vengeful  max list  vengeful  0
    set vengeful  min list  vengeful  1

    ; usually bold and vengeful can take any real number in the range (0,1)
    ; if grid-size>0 we constrain it to a grid.
    ; for example if grid-size=7 (as in the paper), they are rounded up to the nearest multiple of 1/7
    if (grid-size > 0) [
      set bold round( bold * grid-size ) / grid-size
      set vengeful round( vengeful * grid-size ) / grid-size
    ]

    ; locate the turtle on screen according to its bold/vengeful properties
    ; for this we convert the range (0,1) to (-15,15) which is approx. the range of the screen coordinates
    let xx bold * 30 - 15
    let yy vengeful * 30 - 15
    setxy xx yy

  ]

  update-turtles-quick
end


; This procedure is called after every game step except reproduce
; it just updates defect and label
to update-turtles-quick
  ask turtles [


    ; Choose turtle display properties based on whether it is a defector or not
    ifelse defect? [set shape "x" ] [ set shape "circle"]
    ;ifelse defect? [set color [255 50 20]] [ set color [20 255 50] ]

    ; show score as a label
    ifelse (reproduceScore >= 0)
    [ set label (word score ":" reproduceScore ":" numOffsprings)   ]
    [  set label score ]

  ]
end


; The main simulation procedure:
; It runs one tick in the game
;
; It's called once when you click 'step'
; and repeatedly when you click 'go'
;
; The 'step' global variable contains the last game step that was executed.
; based on its value, the procedue decides what game step is next.
; the steps are:
;    init - the initial setup
;    defect - turtles decide whether to defect or not
;    observe - some turtles see defectors
;    punish - some turtles punish defectors
;    observe2 - some turtles see turtles that saw defectors and didn't punish
;    punish2 - some turtles punish turtles that saw defectors and didn't punish
;    calc - calculate reproduction stats
;    reproduce - remaining turtles reproduce

; For each step we call a separate procedure below. This procedure updates the 'step' variable to its new value,
; and executes what's needed for this step
to go
  let prevStep step
  if prevStep = "init" [ stepDefect ]
  if prevStep = "defect" [ stepObserve  ]
  if prevStep = "observe" [ stepPunish ]
  if prevStep = "punish" [ stepObserve2 ]
  if prevStep = "observe2" [ stepPunish2 ]
  if prevStep = "punish2" [ stepCalc ]
  if prevStep = "calc" [ stepReproduce ]
  if prevStep = "reproduce" [ stepDefect ]

  ifelse (step = "reproduce") [ update-turtles-full]
    [ update-turtles-quick ]
  tick
end



;  defect - turtles decide whether to defect or not
to stepDefect

  set step "defect"

  ; Randomly select the model's S variable in the range (0,1)
  set seen random-float 1

  ; experimental stuff
  ;set adjustedSeen 1 - (1 - seen) ^ (1 / (popSize - 1))
  ;set adjustedSeen seen

  ; For each turtle:
  ; decide whether to defect
  ; if defected: receive temptation T, and hurt others with H
  ask turtles [
    set defect? bold > seen
    if defect? [
      set score score + T
      ask other turtles [ set score score + H ]
    ]
  ]


end

;    observe - some turtles see defectors
to stepObserve

  set step "observe"

  ; For each turtle:
  ask turtles [

    ; init its variables to haven't seen, haven't punished
    set sawDefector? false
    set punished? false

    ; create links of type 'observation' to other turtles selected with the following conditions:
    ;     defect? - Other turtle defected
    ;     (random-float 1) < seen - a condition that is true with probability P(seen) regardless of any turtle properties.
    create-observations-to other turtles with [defect? and (random-float 1) < seen] [

      ; In the source of the link (the turtle that created it), we set the 'sawDefector?' property to true
      ; to indicate it saw a defector
      ask end1 [ set sawDefector? true ]

      ; link display properties
      set thickness 0.2
      set color blue

    ]
  ]
end


;    punish - some turtles punish defectors
to stepPunish
  set step "punish"

  ; execute actions for each existing link of type 'observation':
  ask observations  [

    ; copy the vengeful property of the source end of this link to a local variable vv
    let vv [ vengeful] of end1

    ; decide whether this turtle punishes with probability P(vv)
    let ww random-float 1
    let punish? ww < vv

    ; If the turtle decided to punish:
    if punish? [
      ;    add P to the score of the turtle this link points to.
      ask end2 [ set score score + P ]
      ;    add EE to the source turtle's score, and update it's punished? flag to true
      ask end1 [
        set score score + EE
        set punished? true
      ]
      ; color this link red
      set color red
    ]
  ]
end


;    observe2 - some turtles see turtles that saw defectors and didn't punish
to stepObserve2
  set step "observe2"

  ; For each turtle:
  ask turtles [

    ; create link of type 'observations2' to to other turtles selected with the following conditions:
    ;     sawDefector? - Other turtle saw a defector
    ;     not punished? - Other turtle didn't punish anyone
    ;     (random-float 1) < seen - a condition that is true with probability P(seen) regardless of any turtle properties.
    create-observations2-to other turtles with [sawDefector? and not punished? and (random-float 1) < seen] [
      set thickness 0.2
      set color cyan
    ]
  ]
end

;    punish2 - some turtles punish turtles that saw defectors and didn't punish
to stepPunish2
  set step "punish2"

    ; execute actions for each existing link of type 'observation2':
  ask observations2  [

    ; copy the vengeful property of the source end of this link to a local variable vv
    let vv [ vengeful] of end1

    ; decide whether this turtle punishes with probability P(vv)
    let ww random-float 1
    let punish? ww < vv

    ; If the turtle decided to punish:
    if punish? [
      ;    add P2 to the score of the turtle this link points to.
      ask end2 [ set score score + P2 ]
      ;    add E2 to the source turtle's score
      ask end1 [ set score score + E2 ]
      ; color this link orange
      set color orange
    ]
  ]
end


;    calc - calculate reproduction stats
to stepCalc

  set step "calc"

  ; clear all links
  ask observations[ die ]
  ask observations2[ die ]

  ; set default reproduce stats
  ask turtles [
    set reproduceScore 1
    set numOffsprings  1
  ]

  ; calculate score mean and std
  let meanScore mean [score] of turtles
  let stdScore standard-deviation [score] of turtles

  if (stdScore = 0) [ stop ]

  let thresh1 meanScore - stdScore
  let thresh2 meanScore + stdScore

  ;show (list meanScore stdScore thresh1 thresh2)

  ; set the 0 and 2 reproduceScores
  ask turtles with [score < thresh1] [ set reproduceScore 0 ]
  ask turtles with [score > thresh2] [ set reproduceScore 2 ]

  let remainOffsprings popSize
  let sumReproduceScores sum [ reproduceScore ] of turtles

  ; clear num offstrings before calculating
  ask turtles [set numOffsprings 0]


  ; divide numOffsprings according to ratios of reproduceScore
  ask turtles [

    if remainOffsprings > 0 and reproduceScore > 0 [
      let myShare  round( reproduceScore / sumReproduceScores * remainOffsprings)
      set numOffsprings  myShare
      set remainOffsprings remainOffsprings - myShare
      set sumReproduceScores sumReproduceScores - reproduceScore
    ]
  ]

  ;show [(list numOffsprings reproduceScore score)] of turtles;
  ;show sum [numOffsprings] of turtles

end


;    reproduce - turtles reproduce
to stepReproduce
  set step "reproduce"

  ; each turtle hatches new ones according to numOffSprings
  ask turtles with [not new? and numOffsprings > 0] [
    hatch numOffsprings [
      ; new turtle's properties are its parent's + normal noise
      set bold bold + random-normal 0 mutation-std
      set vengeful vengeful + random-normal 0 mutation-std

      ; set some initial properties
      set defect? false
      set punished? false
      set sawDefector? false
      set score 0
      set reproduceScore -1
      set numOffsprings 0
      set new? true
    ]
  ]

  ; remove all previous genereration turtles
  ask turtles with [not new?] [ die ]
  ; clear the new? flag to the new ones
  ask turtles [ set new? false]

end
@#$#@#$#@
GRAPHICS-WINDOW
325
30
762
468
-1
-1
13.0
1
14
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
120.0

BUTTON
220
45
283
78
NIL
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
220
135
310
168
NIL
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
220
90
310
123
one step
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

MONITOR
220
270
290
315
NIL
seen
3
1
11

MONITOR
220
215
290
260
NIL
step
17
1
11

MONITOR
220
325
309
370
NIL
adjustedSeen
3
1
11

SLIDER
20
45
192
78
popSize
popSize
2
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
20
85
192
118
T
T
-20
20
3.0
1
1
NIL
HORIZONTAL

SLIDER
20
165
192
198
P
P
-20
20
-9.0
1
1
NIL
HORIZONTAL

SLIDER
20
125
192
158
H
H
-20
20
-1.0
1
1
NIL
HORIZONTAL

SLIDER
20
205
192
238
EE
EE
-20
20
-2.0
1
1
NIL
HORIZONTAL

TEXTBOX
20
245
170
263
Meta norm:
11
0.0
1

SLIDER
20
265
192
298
P2
P2
-20
20
0.0
1
1
NIL
HORIZONTAL

SLIDER
20
305
192
338
E2
E2
-20
20
0.0
1
1
NIL
HORIZONTAL

SLIDER
445
495
617
528
mutation-std
mutation-std
0
0.25
0.05
0.01
1
NIL
HORIZONTAL

TEXTBOX
770
30
970
256
Legend:\nsquare: defector\nblue-arrow: seen defecting\nred-arrow: punished\ncyan-arrow: observed not punishing\norange-arrow: punished for not punishing\n\nSet grid-size param (bottom-left) to non-zero to run on a grid
15
0.0
1

SLIDER
260
495
432
528
grid-size
grid-size
0
100
0.0
1
1
NIL
HORIZONTAL

PLOT
840
315
1040
465
Bold/Vengeful
NIL
NIL
0.0
1000.0
0.0
3.0
true
true
"" ""
PENS
"Bold" 1.0 0 -16777216 true "" "plot mean [bold] of turtles"
"Vengeful" 1.0 0 -5298144 true "" "plot mean [vengeful] of turtles "

SLIDER
20
355
192
388
init-mean-boldness
init-mean-boldness
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
20
395
197
428
init-mean-vengefulness
init-mean-vengefulness
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
20
435
192
468
init-std-boldness
init-std-boldness
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
20
475
192
508
init-std-vengefulness
init-std-vengefulness
0
1
0.2
0.01
1
NIL
HORIZONTAL

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
NetLogo 6.1.1
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
1
@#$#@#$#@
