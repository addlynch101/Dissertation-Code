extensions [vid
py]

turtles-own [
  flockmates         ;; agentset of nearby turtles
  nearest-neighbor   ;; closest one of flockmates
  nearest-neighbors  ;; all flockmates within minimum-separation
  thresholdIndividuals ;; individuals within the threshold of groupmates
  ]
breed [type1s type1]    ; The first input defines the name of the agentset associated with the breed. The second input defines the name of a single member of the breed.
breed [type2s type2]
breed [type3s type3]
breed [tick_counter tick_counters]    ; for plotting the tick number
breed [predators predator]

globals [
  my-seed
  type12s
  preyTypes
  outputList
  currentGeneration
  currentEvaluation
  predatorContact
  averageFitness
  bestFitness

  attackedIndividualType
  numberNoneCaught
  numberSolitaryCaught
  numberUnalignedCaught
  numberLeadingCaught
  numberTrailingCaught
  numberMiddleCaught

  numberSolitaryPresentAttackTime
  numberUnalignedPresentAttackTime
  numberLeadingPresentAttackTime
  numberTrailingPresentAttackTime
  numberMiddlePresentAttackTime

  numberSolitaryPresentRandomPolling
  numberUnalignedPresentRandomPolling
  numberLeadingPresentRandomPolling
  numberTrailingPresentRandomPolling
  numberMiddlePresentRandomPolling
  ]

to setup
  file-close-all
  clear-all
  set currentGeneration 0
  set currentEvaluation 0
  set numberNoneCaught 0
  set numberSolitaryCaught 0
  set numberUnalignedCaught 0
  set numberLeadingCaught 0
  set numberTrailingCaught 0
  set numberMiddleCaught 0

  set numberSolitaryPresentRandomPolling 0
  set numberUnalignedPresentRandomPolling 0
  set numberLeadingPresentRandomPolling 0
  set numberTrailingPresentRandomPolling 0
  set numberMiddlePresentRandomPolling 0

  set numberSolitaryPresentAttackTime 0
  set numberUnalignedPresentAttackTime 0
  set numberLeadingPresentAttackTime 0
  set numberTrailingPresentAttackTime 0
  set numberMiddlePresentAttackTime 0
;  set averageFitness 0
;  set bestFitness 0

  set my-seed read-from-string user-input "Enter a random seed (an integer):"
  output-print word "Seed: " my-seed

  py:setup py:python
  py:set "networkInputNumber" predator-input-value
  py:set "populationNumber" predator-population
  py:set "maxSpeed" max-predator-speed
  py:set "seed" my-seed
  py:set "crossoverRate" crossOverRate
  py:set "stablePopulation" stablePopulation
  (py:run
    "import disPythonCode as dpc"
    "ga = dpc.geneticAlgorithm(networkInputNumber,maxSpeed,populationNumber,seed,crossoverRate,stablePopulation)"
  )

  random-seed my-seed
  set-default-shape turtles "default"
  create-type1s prey1                  ;; this creates the number of this type set by the slider.
  [
      right random-float 360.0         ;; random orientation at start
      setxy (-19 + random-float 39) (-19 + random-float 39)      ;; random positions at start between particular coordinates
      set color red
    ]
  create-type2s prey2
  [
      right random-float 360.0         ;; random orientation at start
      setxy (-19 + random-float 39) (-19 + random-float 39)      ;; random positions at start between particular coordinates
      set color orange
    ]
    create-type3s prey3
  [
      right random-float 360.0         ;; random orientation at start
      setxy (-19 + random-float 39) (-19 + random-float 39)      ;; random positions at start between particular coordinates
      set color green
    ]

  create-tick_counter 1
  [   set size 0.5
      setxy (0) (-20)    ;; positioned in centre near bottom of arena
    ]
  set type12s (turtle-set type1s type2s)   ;; just the follower and leader types

  set preyTypes (turtle-set type1s type2s type3s)
  set predatorContact False

  file-open    (word my-seed "_Coordinates.csv")
  reset-ticks
  ; setup-movie          ;; creates movie of simulation
end


to setup-movie
   carefully [ vid:start-recorder ] [ user-message error-message ]
   repeat 1500           ; Movie length in frames
     [ go
     vid:record-view ]
   vid:save-recording "out"
end

to go
  ;; the model runs faster if we don't update the screen until after all turtles have moved
  no-display
  ask type1s [ flock1 ]
    ask type1s [
    carefully [bounce1] [setxy (-19 + random-float 39) (-19 + random-float 39)]                     ;; relfective boundaries (see next routine)
    fd 0.1]
  ask type2s [ flock2 ]
    ask type2s [
    carefully [bounce2] [setxy (-19 + random-float 39) (-19 + random-float 39)]                     ;; relfective boundaries (see next routine)
    fd 0.1]
  ask type3s [ flock2 ]
    ask type3s [
    carefully [bounce2] [setxy (-19 + random-float 39) (-19 + random-float 39)]                     ;; relfective boundaries (see next routine)
    fd 0.1]

  if ticks = predator-intro-delay [
    create-predators 1
  [
      right random-float 360.0         ;; random orientation at start
      setxy (-19 + random-float 39) (-19 + random-float 39)     ;; random positions at start between particular coordinates
      set color yellow
  ]
  ]

  if (ticks mod 100) = 0 [ask one-of preyTypes [class-prey-random-polling]] ;Random Sampling of individual types

  if ticks >= predator-intro-delay [
    ask predators [getpredatorview]
    py:set "netlogoInputs" outputList
    py:run "ga.step(netlogoInputs)"
    ask predators [predator-move py:runresult "ga.getHeadingDirection()" py:runresult "ga.getSpeed()" ]
    ask predators [carefully [bounce1] [setxy (-19 + random-float 39) (-19 + random-float 39)]]
    ask predators [checkpredatorcontact]
  ]

  ifelse ticks > cycleTime [set attackedIndividualType "none"
    set numberNoneCaught numberNoneCaught + 1
    endOfCycle
    reset-ticks]
  [ifelse predatorContact [
    ask one-of preyTypes [class-prey-attack-time] ;turn on for sampling only at capture time
    endOfCycle
    reset-ticks] [tick]]

  display
  ; ask turtles [ file-print (word ticks "," self "," xcor "," ycor)]       ;; writes coordinates to the file that was opened in set up
  ; write-to-file
  ask tick_counter [set label-color red set label (word "Seed: " my-seed)]
  clear-links
end

to endOfCycle
  py:set "tickCounter" ticks
  py:set "attackedIndividualType" attackedIndividualType
  py:run "ga.endOfSimulation(tickCounter, attackedIndividualType)"

  clear-turtles

  set currentGeneration py:runresult "ga.getCurrentGeneration()"
  set currentEvaluation py:runresult "ga.getCurrentEvaluation()"
  set averageFitness py:runresult "ga.getAverageFitness()"
  set bestFitness py:runresult "ga.getBestFitness()"
  set my-seed py:runresult "ga.getSeed()"

  random-seed my-seed
  set-default-shape turtles "default"
  create-type1s prey1                  ;; this creates the number of this type set by the slider.
  [   right random-float 360.0         ;; random orientation at start
      setxy (-19 + random-float 39) (-19 + random-float 39)      ;; random positions at start between particular coordinates
      set color red
    ]
  create-type2s prey2
  [
      right random-float 360.0         ;; random orientation at start
      setxy (-19 + random-float 39) (-19 + random-float 39)      ;; random positions at start between particular coordinates
      set color orange
    ]
    create-type3s prey3
  [
      right random-float 360.0         ;; random orientation at start
      setxy (-19 + random-float 39) (-19 + random-float 39)     ;; random positions at start between particular coordinates
      set color green
    ]
  create-tick_counter 1
  [   set size 0.5
      setxy (0) (-20)    ;; positioned in centre near bottom of arena
    ]
  set type12s (turtle-set type1s type2s)   ;; just the follower and leader types

  set preyTypes (turtle-set type1s type2s type3s)
  set predatorContact False

  file-open    (word my-seed "_Coordinates.csv")
end

to write-to-file
  ;; use SORT so the turtles print their data in order by who number, rather than in random order
  foreach sort turtles [ x ->
    ask x [
      file-print (word ticks "," self "," xcor "," ycor)
    ]
  ]
end

to save-top-of-population
  let filename user-input "Enter a file name to save population to:"
  py:set "saveFileName" filename
  py:run "ga.savePop(saveFileName)"
end

to load-population
  let filename user-input "Enter a file name to load population from:"
  py:set "loadFileName" filename
  py:run "ga.loadPop(loadFileName)"
end

;; this procedure checks the coordinates and makes the turtles
;; reflect according to the law that the angle of reflection is
;; equal to the angle of incidence

to bounce1  ;; turtle procedure
  if [pxcor] of patch-ahead 0.5 = -19
    ; if so, reflect heading around x axis
     [ set heading (- heading) ]
  if [pxcor] of patch-ahead 0.5 = 19
    ; if so, reflect heading around x axis
    [ set heading (- heading) ]
  if [pycor] of patch-ahead 0.5 = -19
      ; if so, reflect heading around y axis
    [ set heading (180 - heading) ]
  if [pycor] of patch-ahead 0.5 = 19
     ; if so, reflect heading around y axis
    [ set heading (180 - heading) ]
end

to bounce2  ;; turtle procedure
  if [pxcor] of patch-ahead 0.5 = -19
    ; if so, reflect heading around x axis
     [ set heading (- heading) ]
  if [pxcor] of patch-ahead 0.5 = 19
    ; if so, reflect heading around x axis
     [ set heading (- heading) ]
  if [pycor] of patch-ahead 0.5 = 19
      ; if so, reflect heading around y axis
    [ set heading (180 - heading) ]
  if [pycor] of patch-ahead 0.5 = -19
      ; if so, reflect heading around y axis
    [ set heading (180 - heading) ]
end

to flock1 ;; turtle procedure
  find-flockmates
  ifelse any? flockmates
    [ find-nearest-neighbor
      find-nearest-neighbors1
      ifelse distance nearest-neighbor < minimum-separation1 ; minimum-separation is replusion zone
        [ separate1 ]
        [ align1                                             ; alignment is set to 0 in experimental trials but can be changed in the Interface tab
          cohere1 ] ]
    [set heading (heading + random-normal 0 turning-noise)]
    fd speed
end

to flock2  ;; turtle procedure
    set heading (heading + random-normal 0 turning-noise)    ; leaders and asocials have no social behaviour
    fd speed
end

to find-flockmates  ;; turtle procedure
  set flockmates (other type12s in-cone vision-distance vision-cone)      ;; type12s are follower and leader types, this is where the followers ignore the asocial individuals
end

to find-nearest-neighbors1 ;; turtle procedure
  set nearest-neighbors (turtles in-radius minimum-separation1) with [self != myself]
end

to find-nearest-neighbor ;; turtle procedure
  set nearest-neighbor min-one-of flockmates [distance myself]
end

;;; SEPARATE

to separate1  ;; turtle procedure
  ; turn-away ([heading] of nearest-neighbor) max-separate-turn             ;; this is original implementation of separation (repulsion)
  turn-away average-heading-towards-nearest-neighbors max-separate-turn     ;; this gives them greater ability to avoid overlapping
end

to-report average-heading-towards-nearest-neighbors  ;; turtle procedure
  report atan mean [sin (towards myself + 180)] of nearest-neighbors
              mean [cos (towards myself + 180)] of nearest-neighbors
end

;;; ALIGN   ;

to align1  ;; turtle procedure
  turn-towards average-flockmate-heading max-align-turn1
end

to-report average-flockmate-heading  ;; turtle procedure
  report atan mean [sin heading] of flockmates
              mean [cos heading] of flockmates
end

;;; COHERE

to cohere1  ;; turtle procedure
  turn-towards average-heading-towards-flockmates max-cohere-turn1
end

to-report average-heading-towards-flockmates  ;; turtle procedure
  report atan mean [sin (towards myself + 180)] of flockmates
              mean [cos (towards myself + 180)] of flockmates
end

to find-threshold-individuals
  set thresholdIndividuals (other preyTypes in-radius group-threshold-distance)
end

to-report num-agent-following
  let agents-ahead []
  let num-ahead 0
  set agents-ahead (other preyTypes in-cone group-threshold-distance 180)
  ask agents-ahead [if (facing-same-direction myself) [set num-ahead num-ahead + 1]]
  report num-ahead
end

to-report following-agent [agent]
  let agents-ahead []
  set agents-ahead (other preyTypes in-cone group-threshold-distance 180)
  ifelse member? agent agents-ahead [
    ifelse facing-same-direction agent [report 1] [report 0]
  ] [report 0]

end

to-report facing-same-direction [agent]
  let myselfDirection 0
  let agentDirection 0
  ask myself [set myselfDirection heading]
  ask agent [set agentDirection heading]
  report (min (list abs(myselfDirection - agentDirection) (360 - abs(myselfDirection - agentDirection)))) < threshold-for-facing-same-way
end

to class-prey-random-polling
  let numberIndividualFollowing 0
  let numberFollowingIndividual 0
  let individualThresholdIndividuals []

  find-threshold-individuals
  set numberIndividualFollowing num-agent-following
  ask thresholdIndividuals [set numberFollowingIndividual numberFollowingIndividual + (following-agent myself)]
  set individualThresholdIndividuals thresholdIndividuals

  ifelse not any? individualThresholdIndividuals [set numberSolitaryPresentRandomPolling numberSolitaryPresentRandomPolling + 1]
  [
    ifelse numberIndividualFollowing = 0 and numberFollowingIndividual = 0 [set numberUnalignedPresentRandomPolling numberUnalignedPresentRandomPolling + 1]
    [ifelse numberIndividualFollowing > 0 and numberFollowingIndividual = 0 [set numberTrailingPresentRandomPolling numberTrailingPresentRandomPolling + 1]
      [ifelse numberIndividualFollowing = 0 and numberFollowingIndividual > 0 [set numberLeadingPresentRandomPolling numberLeadingPresentRandomPolling + 1]
        [if numberIndividualFollowing > 0 and numberFollowingIndividual > 0 [set numberMiddlePresentRandomPolling numberMiddlePresentRandomPolling + 1]]]]
  ]
end

to class-prey-attack-time
  let numberIndividualFollowing 0
  let numberFollowingIndividual 0
  let individualThresholdIndividuals []

  find-threshold-individuals
  set numberIndividualFollowing num-agent-following
  ask thresholdIndividuals [set numberFollowingIndividual numberFollowingIndividual + (following-agent myself)]
  set individualThresholdIndividuals thresholdIndividuals

  ifelse not any? individualThresholdIndividuals [set numberSolitaryPresentAttackTime numberSolitaryPresentAttackTime + 1]
  [
    ifelse numberIndividualFollowing = 0 and numberFollowingIndividual = 0 [set numberUnalignedPresentAttackTime numberUnalignedPresentAttackTime + 1]
    [ifelse numberIndividualFollowing > 0 and numberFollowingIndividual = 0 [set numberTrailingPresentAttackTime numberTrailingPresentAttackTime + 1]
      [ifelse numberIndividualFollowing = 0 and numberFollowingIndividual > 0 [set numberLeadingPresentAttackTime numberLeadingPresentAttackTime + 1]
        [if numberIndividualFollowing > 0 and numberFollowingIndividual > 0 [set numberMiddlePresentAttackTime numberMiddlePresentAttackTime + 1]]]]
  ]
end

;;; PREDATOR PROCEDURES

to getpredatorview
  set flockmates (other preyTypes in-cone predator-vision-distance predator-vision-cone)
  set outputList []
  ask flockmates [set outputList insert-item 0 outputList distance myself
    create-link-from myself
    ask link [who] of myself who [set outputList insert-item 0 outputList link-heading]
  ]
end

to predator-move [headingDirection movingSpeed]
  turn-towards headingDirection max-predator-turn
  fd movingSpeed
end

to checkpredatorcontact
  let distanceList []
  ask flockmates [set distanceList insert-item 0 distanceList distance myself]
  if not empty? distanceList [
    if min distanceList < predator-hit-threshold [set predatorContact True
      find-nearest-neighbor
      findattackedindividualtype nearest-neighbor
    ]
  ]
end

to findattackedindividualtype [individual]
  let numberIndividualFollowing 0
  let numberFollowingIndividual 0
  let individualThresholdIndividuals []

  ask individual [find-threshold-individuals
    set numberIndividualFollowing num-agent-following
    ask thresholdIndividuals [set numberFollowingIndividual numberFollowingIndividual + (following-agent individual)]
    set individualThresholdIndividuals thresholdIndividuals]

  ifelse not any? individualThresholdIndividuals [set attackedIndividualType "solitary"
  set numberSolitaryCaught numberSolitaryCaught + 1]
  [
    ifelse numberIndividualFollowing = 0 and numberFollowingIndividual = 0 [set attackedIndividualType "unaligned"
    set numberUnalignedCaught numberUnalignedCaught + 1]
    [ifelse numberIndividualFollowing > 0 and numberFollowingIndividual = 0 [set attackedIndividualType "trailing"
      set numberTrailingCaught numberTrailingCaught + 1]
      [ifelse numberIndividualFollowing = 0 and numberFollowingIndividual > 0 [set attackedIndividualType "leading"
        set numberLeadingCaught numberLeadingCaught + 1]
        [if numberIndividualFollowing > 0 and numberFollowingIndividual > 0 [set attackedIndividualType "middle"
    set numberMiddleCaught numberMiddleCaught + 1]]]]
  ]
end

;;; HELPER PROCEDURES

to turn-towards [new-heading max-turn]                                  ;; turtle procedure
  turn-at-most (subtract_headings (new-heading + random-normal 0 turning-noise) heading) max-turn
end

to turn-away [new-heading max-turn]                                     ;; turtle procedure
  turn-at-most (subtract_headings heading (new-heading + random-normal 0 turning-noise)) max-turn
end

;; turn right by "turn" degrees (or left if "turn" is negative),
;; but never turn more than "max-turn" degrees
to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end

to-report subtract_headings [h1 h2]
  ifelse abs (h1 - h2) <= 180
    [ report h1 - h2 ]
    [ ifelse h1 > h2
        [ report h1 - h2 - 360 ]
        [ report h1 - h2 + 360 ] ]
end
@#$#@#$#@
GRAPHICS-WINDOW
294
30
703
440
-1
-1
9.802
1
30
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
56
13
137
46
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
56
53
137
86
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

SLIDER
0
319
238
352
prey1
prey1
0
4
1.0
1
1
NIL
HORIZONTAL

SLIDER
5
136
207
169
max-separate-turn
max-separate-turn
0
40
4.5
0.5
1
degrees
HORIZONTAL

SLIDER
3
283
163
316
minimum-separation1
minimum-separation1
0
10
2.5
0.25
1
NIL
HORIZONTAL

SLIDER
6
174
165
207
speed
speed
0
0.1
0.013
0.001
1
NIL
HORIZONTAL

SLIDER
9
96
169
129
turning-noise
turning-noise
0
11.5
2.1
0.1
1
degrees
HORIZONTAL

INPUTBOX
12
427
114
487
max-align-turn1
0.0
1
0
Number

INPUTBOX
11
501
113
561
max-cohere-turn1
90.0
1
0
Number

SLIDER
2
355
235
388
prey2
prey2
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
-1
249
171
282
vision-distance
vision-distance
0
40
13.0
1
1
NIL
HORIZONTAL

SLIDER
0
216
172
249
vision-cone
vision-cone
0
270
178.0
1
1
deg
HORIZONTAL

SLIDER
2
391
234
424
prey3
prey3
0
4
2.0
1
1
NIL
HORIZONTAL

MONITOR
738
25
852
70
NIL
currentGeneration
17
1
11

SLIDER
619
491
794
524
max-predator-speed
max-predator-speed
0
0.2
0.165
0.001
1
NIL
HORIZONTAL

SLIDER
620
537
792
570
predator-population
predator-population
0
200
15.0
1
1
NIL
HORIZONTAL

SLIDER
723
92
912
125
predator-vision-cone
predator-vision-cone
0
180
135.0
1
1
deg
HORIZONTAL

SLIDER
725
140
910
173
predator-vision-distance
predator-vision-distance
0
100
19.0
1
1
NIL
HORIZONTAL

SLIDER
619
577
791
610
predator-input-value
predator-input-value
2
16
10.0
2
1
NIL
HORIZONTAL

TEXTBOX
621
454
771
482
Set these 5 values before setup
11
0.0
1

SLIDER
727
183
900
216
predator-hit-threshold
predator-hit-threshold
0
3
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
728
224
900
257
cycleTime
cycleTime
100
5000
1500.0
100
1
NIL
HORIZONTAL

SLIDER
728
267
900
300
max-predator-turn
max-predator-turn
3
45
7.0
1
1
deg
HORIZONTAL

MONITOR
870
26
981
71
NIL
currentEvaluation
17
1
11

SLIDER
619
619
798
652
crossOverRate
crossOverRate
0
1
0.5
0.01
1
NIL
HORIZONTAL

PLOT
139
458
581
689
GA-Fitness-Curve
Generation
Ticks
0.0
10.0
0.0
10.0
true
false
"" "clear-plot"
PENS
"average-fitness" 1.0 0 -16777216 true "" "plotxy currentGeneration averageFitness\n"
"best-fitness" 1.0 0 -13840069 true "" "plotxy currentGeneration bestFitness"

SLIDER
728
319
918
352
predator-intro-delay
predator-intro-delay
0
100
50.0
5
1
ticks
HORIZONTAL

BUTTON
1159
74
1259
107
NIL
setup-movie
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
991
73
1151
107
NIL
save-top-of-population
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
992
26
1109
59
NIL
load-population
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
249
329
399
347
red
11
0.0
1

TEXTBOX
247
366
397
384
orange\n
11
0.0
1

TEXTBOX
245
405
395
423
green\n
11
0.0
1

SWITCH
620
662
767
695
stablePopulation
stablePopulation
0
1
-1000

SLIDER
721
364
915
397
group-threshold-distance
group-threshold-distance
0
10
6.0
0.5
1
NIL
HORIZONTAL

SLIDER
722
400
943
433
threshold-for-facing-same-way
threshold-for-facing-same-way
10
90
45.0
1
1
NIL
HORIZONTAL

PLOT
809
457
1039
770
Catching Tracker
NIL
NIL
0.0
6.0
0.0
10.0
true
true
"" "clear-plot"
PENS
"none" 1.0 1 -5987164 true "" "plotxy 0 numberNoneCaught"
"solitary" 1.0 1 -11783835 true "" "plotxy 1 numberSolitaryCaught"
"trailing" 1.0 1 -4079321 true "" "plotxy 2 numberTrailingCaught"
"unaligned" 1.0 1 -16777216 true "" "plotxy 3 numberUnalignedCaught"
"leading" 1.0 1 -14070903 true "" "plotxy 4 numberLeadingCaught"
"middle" 1.0 1 -14439633 true "" "plotxy 5 numberMiddleCaught"

PLOT
1071
455
1314
768
Caputure Time Random Selection
NIL
NIL
0.0
5.0
0.0
10.0
true
true
"" "clear-plot"
PENS
"solitary" 1.0 1 -11783835 true "" "plotxy 0 numberSolitaryPresentAttackTime"
"trailing" 1.0 1 -4079321 true "" "plotxy 1 numberTrailingPresentAttackTime"
"unaligned" 1.0 1 -16777216 true "" "plotxy 2 numberUnalignedPresentAttackTime"
"leading" 1.0 1 -13345367 true "" "plotxy 3 numberLeadingPresentAttackTime"
"middle" 1.0 1 -14439633 true "" "plotxy 4 numberMiddlePresentAttackTime"

PLOT
979
123
1209
440
Random Polling
NIL
NIL
0.0
5.0
0.0
10.0
true
true
"" "clear-plot"
PENS
"solitary" 1.0 1 -11783835 true "" "plotxy 0 numberSolitaryPresentRandomPolling"
"trailing" 1.0 1 -4079321 true "" "plotxy 1 numberTrailingPresentRandomPolling"
"unaligned" 1.0 1 -16777216 true "" "plotxy 2 numberUnalignedPresentRandomPolling"
"leading" 1.0 1 -13345367 true "" "plotxy 3 numberLeadingPresentRandomPolling"
"middle" 1.0 1 -14439633 true "" "plotxy 4 numberMiddlePresentRandomPolling"

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 151 152 137 77 105 67 89 67 66 74 48 85 36 100 24 116 14 134 0 151 15 167 22 182 40 206 58 220 82 226 105 226 134 222
Polygon -16777216 true false 151 150 149 128 149 114 155 98 178 80 197 80 217 81 233 95 242 117 246 141 247 151 245 177 234 195 218 207 206 211 184 211 161 204 151 189 148 171
Polygon -7500403 true true 246 151 241 119 240 96 250 81 261 78 275 87 282 103 277 115 287 121 299 150 286 180 277 189 283 197 281 210 270 222 256 222 243 212 242 192
Polygon -16777216 true false 115 70 129 74 128 223 114 224
Polygon -16777216 true false 89 67 74 71 74 224 89 225 89 67
Polygon -16777216 true false 43 91 31 106 31 195 45 211
Line -1 false 200 144 213 70
Line -1 false 213 70 213 45
Line -1 false 214 45 203 26
Line -1 false 204 26 185 22
Line -1 false 185 22 170 25
Line -1 false 169 26 159 37
Line -1 false 159 37 156 55
Line -1 false 157 55 199 143
Line -1 false 200 141 162 227
Line -1 false 162 227 163 241
Line -1 false 163 241 171 249
Line -1 false 171 249 190 254
Line -1 false 192 253 203 248
Line -1 false 205 249 218 235
Line -1 false 218 235 200 144

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144
@#$#@#$#@
NetLogo 6.2.2
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
