;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-abbr-reader.ss" "lang")((modname 1-space-invaders) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
(require 2htdp/universe)
(require 2htdp/image)

;; Space Invaders



;; =================
;; Constants:

(define WIDTH  300)
(define HEIGHT 500)

(define INVADER-X-SPEED 1.5)  ;speeds (not velocities) in pixels per tick
(define INVADER-Y-SPEED 1.5)
(define TANK-SPEED 2)
(define MISSILE-SPEED 10)

(define HIT-RANGE 10)
 
(define INVADE-RATE 10)              ; INVADE-RATE / INVADE-RATE-COMPARATOR is probability of invader
(define INVADE-RATE-COMPARATOR 200)  ; spawning on a single tick (28 ticks per second)

(define BACKGROUND (empty-scene WIDTH HEIGHT))

(define INVADER
  (overlay/xy (ellipse 10 15 "outline" "blue")              ;cockpit cover
              -5 6
              (ellipse 20 10 "solid"   "blue")))            ;saucer

(define TANK
  (overlay/xy (overlay (ellipse 28 8 "solid" "black")       ;tread center
                       (ellipse 30 10 "solid" "green"))     ;tread outline
              5 -14
              (above (rectangle 5 10 "solid" "black")       ;gun
                     (rectangle 20 10 "solid" "black"))))   ;main body

(define TANK-HEIGHT/2 (/ (image-height TANK) 2))

(define MISSILE (ellipse 5 15 "solid" "red"))

(define MISSILE-LAUNCH-HEIGHT (- HEIGHT (image-height TANK)))

(define END-SCREEN (overlay
                    (text "GAME OVER" 24 "BLACK")
                    (empty-scene 200 50 "orange")))



;; =================
;; Data Definitions:

(define-struct game (invaders missiles tank))
;; Game is (make-game  (listof Invader) (listof Missile) Tank)
;; interp. the current state of a space invaders game
;;         with the current invaders, missiles and tank position

;; Game constants defined below Missile data definition

#;
(define (fn-for-game s)
  (... (fn-for-loinvader (game-invaders s))
       (fn-for-lom (game-missiles s))
       (fn-for-tank (game-tank s))))


(define-struct tank (x dir))
;; Tank is (make-tank Number Integer[-1, 1])
;; interp. the tank location is x, HEIGHT - TANK-HEIGHT/2 in screen coordinates
;;         the tank moves TANK-SPEED pixels per clock tick left if dir -1, right if dir 1

(define T0 (make-tank (/ WIDTH 2) 1))   ;center going right
(define T1 (make-tank 50 1))            ;going right
(define T2 (make-tank 50 -1))           ;going left

#;
(define (fn-for-tank t)
  (... (tank-x t) (tank-dir t)))


(define-struct invader (x y dx))
;; Invader is (make-invader Number Number Number)
;; interp. the invader is at (x, y) in screen coordinates
;;         the invader moves along x by dx pixels per clock tick

(define I1 (make-invader 150 100 12))           ;not landed, moving right
(define I2 (make-invader 150 HEIGHT -10))       ;exactly landed, moving left
(define I3 (make-invader 150 (+ HEIGHT 10) 10)) ;> landed, moving right

#;
(define (fn-for-invader invader)
  (... (invader-x invader) (invader-y invader) (invader-dx invader)))


;; ListOfInvader is one of:
;; - empty
;; - (cons Invader ListOfInvader)
;; interp. a list of invaders

(define LOI0 empty)
(define LOI1 (list I1))
(define LOI2 (list I1 I2))

#;
(define (fn-for-loi loi)
  (cond [(empty? loi) (...)]
        [else (... (fn-for-invader (first loi))
                   (fn-for-loi (rest loi)))]))


(define-struct missile (x y))
;; Missile is (make-missile Number Number)
;; interp. the missile's location is x y in screen coordinates

(define M1 (make-missile 150 300))                               ;not hit U1
(define M2 (make-missile (invader-x I1) (+ (invader-y I1) 10)))  ;exactly hit U1
(define M3 (make-missile (invader-x I1) (+ (invader-y I1)  5)))  ;> hit U1

#;
(define (fn-for-missile m)
  (... (missile-x m) (missile-y m)))


;; ListOfMissile is one of:
;; - empty
;; - (cons Missile ListOfMissiles)
;; interp. a list of missiles

(define LOM0 empty)
(define LOM1 (list M1))
(define LOM2 (list M1 M2))

#;
(define (fn-for-lom lom)
  (cond [(empty? lom) (...)]
        [else (... (fn-for-missile (first lom))
                   (fn-for-lom (rest lom)))]))


; Game examples
(define G0 (make-game empty empty T0))
(define G1 (make-game empty empty T1))
(define G2 (make-game (list I1) (list M1) T1))
(define G3 (make-game (list I1 I2) (list M1 M2) T1))
(define G4 (make-game (list I1 I2) (list M1 M2) T2))



;; =================
;; Functions:


;; Game -> Game
;; start the world with (main (make-game empty empty T0))
;; 
(define (main s)
  (big-bang s                         ; Game
    (on-tick   update-game)           ; Game -> Game
    (to-draw   render)                ; Game -> Image
    (stop-when game-over? show-end)   ; Game -> Boolean
    (on-key    handle-key)))          ; Game KeyEvent -> Game


;; Game -> Game
;; produce the next game state, moving missiles up, invaders diagonally down, tank left/right
;; and detecting any missle / invader collisions, removing both the missile and invader involved
(check-random (update-game G2)
              (make-game
               (spawn-invaders (move-invaders (destroy-invaders (game-invaders G2) (game-missiles G2))))
               (move-missiles (destroy-missiles (game-invaders G2) (game-missiles G2)))
               (move-tank (game-tank G2))))

; (define (update-game s) s) ; Stub

; <use function composition with the Game template>

(define (update-game s)
  (make-game
   (spawn-invaders (move-invaders (destroy-invaders (game-invaders s) (game-missiles s))))
   (move-missiles (destroy-missiles (game-invaders s) (game-missiles s)))
   (move-tank (game-tank s))))


;; ListOfInvader -> ListOfInvader
;; randomly spawn additional invaders according to INVADE-RATE and INVADE-RATE-COMPARATOR
;; invaders spawn at a random x position at the top of the screen, with a random direction
;; NOTE: newly spawned invaders added to end of ListOfInvader so that invaders are sorted from
;; lowest position on screen to highest position on screen
(check-random (spawn-invaders empty) ; Spawn invader when no invaders present
              (if (< (random INVADE-RATE-COMPARATOR) INVADE-RATE)
                  (list (spawn-invader INVADER-X-SPEED))
                  empty))

(check-random (spawn-invaders (list I1 I2)) ; Spawn invader when invaders already exist
              (if (< (random INVADE-RATE-COMPARATOR) INVADE-RATE)
                  (list I1 I2 (spawn-invader INVADER-X-SPEED))
                  (list I1 I2)))

;(define (spawn-invaders loi) loi) ; Stub

;<use template from ListOfInvader>

(define (spawn-invaders loi)
  (if (< (random INVADE-RATE-COMPARATOR) INVADE-RATE)
      (append loi (cons (spawn-invader INVADER-X-SPEED) empty)) 
      loi))                                     


;; Number -> Invader
;; produces an Invader at random x position at top of screen (y = 0)
;; its x speed is set to the given number, randomly positive or negative (moving left/right)
(check-random (spawn-invader INVADER-X-SPEED)
              (make-invader
               (random WIDTH)
               0
               (if (< (random 10) 5)
                   (- INVADER-X-SPEED)
                   INVADER-X-SPEED)))

;(define (spawn-invader n) I1) ; Stub

;<use template for single atomic non-distinct parameter>

(define (spawn-invader n)
  (make-invader
   (random WIDTH)          ; Random initial X location
   0                       ; Start at y = 0
   (if (< (random 10) 5)   ; 50% chance of moving left or right initially
       (- n)
       n)))


;; ListOfInvader -> ListOfInvader
;; move all invaders in list down the screen at 45deg angle, bouncing off the l/r screen edges
(check-expect (move-invaders empty) empty) ; No invaders to move

(check-expect (move-invaders (list I1)) (list (move-invader I1))) ; Move a single invader

(check-expect (move-invaders (list I1 (make-invader (/ WIDTH 4) (/ HEIGHT 4) -10))) ; Move 2 invaders
              (list (move-invader I1) (move-invader (make-invader (/ WIDTH 4) (/ HEIGHT 4) -10))))
              
;(define (move-invaders loi) loi) ; Stub

;<use template from ListOfInvader>

(define (move-invaders loi)
  (cond [(empty? loi) empty]
        [else
         (cons (move-invader (first loi)) (move-invaders (rest loi)))]))


;; Invader -> Invader
;; move a single invader down and left/right according to its speed and direction
(check-expect (move-invader ; Invader moving to the right, not striking sides
               (make-invader
                (/ WIDTH 2)
                (/ HEIGHT 2)
                INVADER-X-SPEED))
              (make-invader
               (+ (/ WIDTH 2) INVADER-X-SPEED)
               (+ (/ HEIGHT 2) INVADER-Y-SPEED)
               INVADER-X-SPEED))

(check-expect (move-invader ; Invader moving to the left, striking the left side and bouncing
               (make-invader
                0
                (/ HEIGHT 2)
                (- INVADER-X-SPEED)))
              (make-invader
               INVADER-X-SPEED
               (+ (/ HEIGHT 2) INVADER-Y-SPEED)
               INVADER-X-SPEED))

(check-expect (move-invader ; Invader moving to the right, striking the right side and bouncing
               (make-invader
                WIDTH
                (/ HEIGHT 2)
                INVADER-X-SPEED))
              (make-invader
               (- WIDTH INVADER-X-SPEED)
               (+ (/ HEIGHT 2) INVADER-Y-SPEED)
               (- INVADER-X-SPEED)))

;(define (move-invader invader) invader) ; Stub

;<use template from Invader>

(define (move-invader invader)
  (cond [(< (+ (invader-x invader) (invader-dx invader)) 0)
         (make-invader
          (- (- (invader-dx invader)) (invader-x invader))
          (+ (invader-y invader) INVADER-Y-SPEED)
          (- (invader-dx invader)))]
        [(> (+ (invader-x invader) (invader-dx invader)) WIDTH)
         (make-invader
          (- WIDTH (- (invader-dx invader) (- WIDTH (invader-x invader))))
          (+ (invader-y invader) INVADER-Y-SPEED)
          (- (invader-dx invader)))]
        [else
         (make-invader
          (+ (invader-x invader) (invader-dx invader))
          (+ (invader-y invader) INVADER-Y-SPEED)
          (invader-dx invader))]))


;; ListOfInvader ListOfMissile -> ListOfInvader
;; produces an updated ListOfInvader, removing any invaders that have collided with a missile
(check-expect (destroy-invaders empty empty)                   ; No invaders or missiles
              empty)

(check-expect (destroy-invaders (list I1) empty)               ; No missiles to destroy invaders
              (list I1))

(check-expect (destroy-invaders empty (list M1 M2))            ; No invaders to be destroyed
              empty)

(check-expect (destroy-invaders (list I1) (list M2))           ; M2 hits I1, I1 destroyed
              empty)

(check-expect (destroy-invaders (list I2) (list M2))           ; M2 is far above I2, I2 not hit
              (list I2))
 
(check-expect (destroy-invaders (list                          ; M2 hits I1, other invader remains
                                 I1
                                 (make-invader (/ WIDTH 2) 0 -10))
                                (list M1 M2))
              (list (make-invader (/ WIDTH 2) 0 -10)))

(check-expect (destroy-invaders (list                          ; M2 hits first I1, other invaders remain
                                 I1
                                 I1
                                 (make-invader (/ WIDTH 2) 0 -10))
                                (list M1 M2))
              (list I1 (make-invader (/ WIDTH 2) 0 -10)))

;(define (destroy-invaders loi lom) loi) ; Stub

;<use combined templates from ListOfInvader and ListOfMissile>

(define (destroy-invaders loi lom)
  (cond [(empty? loi) empty]
        [(empty? lom) loi]
        [(collision? (first loi) (first lom))      ; If missile hits invader, remove invader
         (destroy-invaders (rest loi) (rest lom))]  ; and skip to the next missile
        [(< (invader-y (first loi)) (missile-y (first lom))) ; If current missile below invader
         (destroy-invaders loi (rest lom))]                  ; check the next missile against current invader
        [else                                                    ; If current missile above invader
         (cons (first loi) (destroy-invaders (rest loi) lom))])) ; this invader is safe, keep it in list


;; ListOfMissile -> ListOfMissile 
;; produces updated ListOfMissile, where all missiles have moved vertically up by MISSILE-SPEED
;; any missiles that have moved past the top of the screen (y < 0) are removed
(check-expect (move-missiles empty) empty) ; No missiles to move

(check-expect (move-missiles (list (make-missile (/ WIDTH 2) (/ HEIGHT 2)))) ; One missile to move
              (list (make-missile (/ WIDTH 2) (- (/ HEIGHT 2) MISSILE-SPEED))))

(check-expect (move-missiles
               (list
                (make-missile (/ WIDTH 2) (/ HEIGHT 2))
                (make-missile (/ WIDTH 4) (/ HEIGHT 4)))) ; Two missiles to move, none to remove
              (list
               (make-missile (/ WIDTH 2) (- (/ HEIGHT 2) MISSILE-SPEED))
               (make-missile (/ WIDTH 4) (- (/ HEIGHT 4) MISSILE-SPEED))
               ))

(check-expect (move-missiles
               (list
                (make-missile (/ WIDTH 2) (/ HEIGHT 2))
                (make-missile (/ WIDTH 2) 0)     ; Missile just reached top of screen don't remove
                (make-missile (/ WIDTH 2) -10))) ; Missile past top of screen, remove
              (list
               (make-missile (/ WIDTH 2) (- (/ HEIGHT 2) MISSILE-SPEED))
               (make-missile (/ WIDTH 2) (- MISSILE-SPEED))))
              
;(define (move-missiles lom) lom) ; Stub

;<use template from ListOfMissile>

(define (move-missiles lom)
  (cond [(empty? lom) empty]
        [else
         (if (left-screen? (first lom))
             (move-missiles (rest lom))
             (cons (move-missile (first lom)) (move-missiles (rest lom))))]))


;; Missile -> Boolean
;; produces whether the given missile has left the game screen (y pos < 0)
(check-expect (left-screen? (make-missile (/ WIDTH 2) (/ HEIGHT 2))) false) ; Missile in middle
(check-expect (left-screen? (make-missile (/ WIDTH 2) -10)) true)           ; Missile off-screen

;(define (left-screen? m) false) ; Stub

;<use template from Missile>

(define (left-screen? m)
  (< (missile-y m) 0))


;; Missile -> Missile
;; produces a new missile moved vertically upwards from given missile position at MISSILE-SPEED
(check-expect (move-missile (make-missile (/ WIDTH 2) (/ HEIGHT 2)))
              (make-missile (/ WIDTH 2) (- (/ HEIGHT 2) MISSILE-SPEED)))

;(define (move-missile m) m) ; Stub

;<use template from Missile>

(define (move-missile m)
  (make-missile (missile-x m) (- (missile-y m) MISSILE-SPEED)))


;; ListOfInvader ListOfMissile -> ListOfMissile
;; produces an updated ListOfMissile, removing any missiles that have collided with an invader
;; ASSUME ListOfMissile and ListOfInvader are both sorted from smallest y-pos to largest y-pos
(check-expect (destroy-missiles empty empty)                  ; No invaders or missiles
              empty)                   
(check-expect (destroy-missiles (list I1) empty)               ; No missiles to be destroyed
              empty)              
(check-expect (destroy-missiles empty (list M1 M2))            ; No invaders to destroy missiles
              (list M1 M2))    
(check-expect (destroy-missiles (list I1) (list M2))           ; M2 hits I1 and is destroyed
              empty)
(check-expect (destroy-missiles (list I1) (list M1 M2))        ; M2 hits I1 and is destroyed
              (list M1)) 
(check-expect (destroy-missiles (list I1 I2) (list M1 M2 M2))  ; First M2 hits I1 and is destroyed
              (list M1 M2))

;(define (destroy-missiles loi lom) lom) ; Stub

;<use combined templates from ListOfInvader and ListOfMissile>

(define (destroy-missiles loi lom)
  (cond [(empty? loi) lom]
        [(empty? lom) empty]
        [(collision? (first loi) (first lom))      ; If missile hits invader, remove missile
         (destroy-missiles (rest loi) (rest lom))] ; and skip to the next invader
        [(< (invader-y (first loi)) (missile-y (first lom)))   ; If current invader higher than missile
         (cons (first lom) (destroy-missiles loi (rest lom)))] ; nothing can hit this missile, keep it
        [else                                      ; If invader is below this missile, check next invader
         (destroy-missiles (rest loi) lom)]))


;; Invader Missile -> Boolean
;; produces whether or not the Invader and Missile have collided (within HIT-RANGE of each other)
(check-expect (collision? I1 M1) false) ; No Collision
(check-expect (collision? I1 M2) true)  ; Collision at max distance
(check-expect (collision? I1 M3) true)  ; Colliding closer than max distance

;(define (collision? invader m) false) ; Stub

;<use combined templates for invader and missile>

(define (collision? invader m)
  (and (<= (- (invader-x invader) HIT-RANGE) (missile-x m) (+ (invader-x invader) HIT-RANGE))
       (<= (- (invader-y invader) HIT-RANGE) (missile-y m) (+ (invader-y invader) HIT-RANGE))))


;; Tank -> Tank
;; produces updated Tank, moving its position according to its current direction and TANK-SPEED
;; if Tank is at left/right edge of screen, it stops moving
(check-expect (move-tank (make-tank (/ WIDTH 2) 1))  ; Tank moving right from middle of screen
              (make-tank (+ (/ WIDTH 2) (* TANK-SPEED 1)) 1))

(check-expect (move-tank (make-tank (/ WIDTH 2) -1)) ; Tank moving left from middle of screen
              (make-tank (+ (/ WIDTH 2) (* TANK-SPEED -1)) -1))

(check-expect (move-tank (make-tank 0 -1))           ; Tank moving left at left edge, do not move 
              (make-tank 0 -1))

(check-expect (move-tank (make-tank WIDTH 1))        ; Tank moving right at right edge, do not move 
              (make-tank WIDTH 1))
                         
;(define (move-tank t) t) ; Stub

;<use template from Tank>

(define (move-tank t)
  (cond [(<= (+ (tank-x t) (* TANK-SPEED (tank-dir t))) 0)
         (make-tank 0 (tank-dir t))]
        [(>= (+ (tank-x t) (* TANK-SPEED (tank-dir t))) WIDTH)
         (make-tank WIDTH (tank-dir t))]
        [else
         (make-tank (+ (tank-x t) (* TANK-SPEED (tank-dir t))) (tank-dir t))]))


;; Game -> Image
;; render the tank, invaders and missiles at given positions on the game scene
(check-expect (render G0) ; Initial game state with no missiles or invaders
              (place-image
               TANK (tank-x T0) (- HEIGHT TANK-HEIGHT/2)
               BACKGROUND))

(check-expect (render G2) ; Game state with one missile and one invader
              (place-image
               TANK (tank-x T1) (- HEIGHT TANK-HEIGHT/2)
               (place-image
                INVADER (invader-x I1) (invader-y I1)
                (place-image
                 MISSILE (missile-x M1) (missile-y M1)
                 BACKGROUND))))

(check-expect (render G3) ; Game state with two missiles and two invaders
              (place-image
               TANK (tank-x T1) (- HEIGHT TANK-HEIGHT/2)
               (place-image
                INVADER (invader-x I1) (invader-y I1)
                (place-image
                 INVADER (invader-x I2) (invader-y I2)                         
                 (place-image
                  MISSILE (missile-x M1) (missile-y M1)
                  (place-image
                   MISSILE (missile-x M2) (missile-y M2)
                   BACKGROUND))))))
     
;(define (render s) BACKGROUND) ; Stub

;<use template from Game>

(define (render s)
  (render-invaders (game-invaders s)
                   (render-missiles (game-missiles s)
                                    (render-tank (game-tank s)))))


;; ListOfInvader Image -> Image
;; renders all invaders onto a transparent scene at their (x,y) positions
(check-expect (render-invaders empty BACKGROUND) ; No invaders
              BACKGROUND)

(check-expect (render-invaders (list I1) BACKGROUND) ; One invader
              (place-image
               INVADER (invader-x I1) (invader-y I1)
               BACKGROUND))

(check-expect (render-invaders (list I1 I2) BACKGROUND) ; Two invaders
              (place-image
               INVADER (invader-x I1) (invader-y I1)
               (place-image
                INVADER (invader-x I2) (invader-y I2)
                BACKGROUND)))

;(define (render-invaders loi img) BACKGROUND) ; Stub

;<use template for ListOfInvaders with additional atomic non-distinct parameter>

(define (render-invaders loi img)
  (cond [(empty? loi) img]
        [else (place-image
               INVADER (invader-x (first loi)) (invader-y (first loi))
               (render-invaders (rest loi) img))]))


;; ListOfMissile Image -> Image
;; renders all missiles onto the given image at their (x,y) positions
(check-expect (render-missiles empty BACKGROUND) ; No missiles
              BACKGROUND) 

(check-expect (render-missiles (list M1) BACKGROUND) ; One missile
              (place-image
               MISSILE (missile-x M1) (missile-y M1)
               BACKGROUND))

(check-expect (render-missiles (list M1 M2) BACKGROUND) ; Two missiles
              (place-image
               MISSILE (missile-x M1) (missile-y M1)
               (place-image
                MISSILE (missile-x M2) (missile-y M2)
                BACKGROUND)))
              
;(define (render-missiles lom img) BACKGROUND) ; Stub

;<use template from ListOfMissiles with additional atomic-non distinct parameter>

(define (render-missiles lom img)
  (cond [(empty? lom) img]
        [else (place-image
               MISSILE (missile-x (first lom)) (missile-y (first lom))
               (render-missiles (rest lom) img))]))


;; TANK -> Image
;; renders the tank onto the background at the given (x,y) position
(check-expect (render-tank T0)
              (place-image
               TANK (tank-x T0) (- HEIGHT TANK-HEIGHT/2)
               BACKGROUND))

;(define (render-tank t) BACKGROUND) ; Stub

;<use template from Tank>

(define (render-tank t)
  (place-image
   TANK (tank-x t) (- HEIGHT TANK-HEIGHT/2)
   BACKGROUND))


;; Game -> Boolean
;; produces true if any invader reaches the bottom of the screen (ending the game), else false.
(check-expect (game-over? G0) false) ; No invaders on the screen - game is not over

(check-expect (game-over? G1) false) ; One non-landed invader - game not over

(check-expect (game-over?
               (make-game (list I1 (make-invader (/ WIDTH 2) (/ HEIGHT 2) -5)) empty T0))
              false) ; Two invaders, neither have landed - game not over

(check-expect (game-over?
               (make-game (list I3) (list M1 M2) T0))
              true) ; One landed invader - game is over

(check-expect (game-over? G3) true)  ; Two invaders, one has landed - game is over

;(define (game-over? s) false) ; Stub

;<use template from Game>

(define (game-over? s)
  (landed-invader? (game-invaders s)))


;; Game -> Image
;; renders a final ending screen when the game is over
(check-expect (show-end G0)
              (overlay
               END-SCREEN
               (render G0)))

;(define (show-end s) BACKGROUND) ; Stub

;<use template from Game>

(define (show-end s)
  (overlay
   END-SCREEN
   (render s)))
   

;; ListOfInvader -> Boolean
;; produces true if any invader has reached the bottom of the screen (y pos >= HEIGHT)
(check-expect (landed-invader? empty) false)     ; No invaders on the screen - game is not over

(check-expect (landed-invader? (list I1)) false) ; One non-landed invader - game is not over

(check-expect (landed-invader?
               (list I1 (make-invader (/ WIDTH 2) (/ HEIGHT 2) -5)))
              false)                     ; Two non-landed invaders - game is not over

(check-expect (landed-invader? (list I3)) true)  ; One landed invader - game is over

(check-expect (landed-invader? (list I1 I2)) true) ; Two invaders, one has landed - game is over

;(define (landed-invader? loi) false) ; Stub

;<use template from ListOfInvader>

(define (landed-invader? loi)
  (cond [(empty? loi) false]
        [else
         (if (landed? (first loi))
             true
             (landed-invader? (rest loi)))]))


;; Invader -> Boolean
;; produces true if the given invader has landed (reached the bottom of the screen, y pos >= HEIGHT)
(check-expect (landed? I1) false) ; Non-landed invader
(check-expect (landed? I2) true)  ; exactly landed invader
(check-expect (landed? I3) true)  ; invader has moved beyond bottom of screen

;(define (landed? invader) false) ; Stub

;<use template from Invader>

(define (landed? invader)
  (>= (invader-y invader) HEIGHT))


;; Game KeyEvent -> Game
;; - update tank direction on left / right key press
;; - fire missile on spacebar press
(check-expect (handle-key G0 "a") G0)     ; Pressing key apart from space or left/right, no change

(check-expect (handle-key G0 "right") G0) ; Pressing right when tank is already going right, no change

(check-expect (handle-key G0 "left")      ; Pressing left when tank is moving right, swap tank direction
              (make-game empty empty (make-tank (/ WIDTH 2) -1)))

(check-expect (handle-key G4 "right")     ; Pressing right when tank is going left, swap tank direction
              (make-game (game-invaders G4) (game-missiles G4) (make-tank 50 1)))

(check-expect (handle-key G4 "left") G4)  ; Pressing left when tank is going left, no change

(check-expect (handle-key G0 " ")     ; Pressing space adds missile at tank position
              (make-game
               empty
               (list (make-missile (tank-x T0) MISSILE-LAUNCH-HEIGHT))
               T0))

;(define (handle-key s ke) s) ; Stub

;<use template from on-key handler>

(define (handle-key s ke)
  (cond [(or (key=? ke "left") (key=? ke "right"))
         (make-game
          (game-invaders s)
          (game-missiles s)
          (update-tank-direction (game-tank s) ke))]
        [(key=? ke " ")
         (make-game
          (game-invaders s)
          (add-missile (game-missiles s) (game-tank s))
          (game-tank s))]
        [else s]))


;; Tank KeyEvent -> Tank
;; produces updated tank, moving in the direction specified by the key event
;; ASSUME KeyEvent can only be "left" or "right" (filtered by handle-key function)
(check-expect (update-tank-direction T0 "right")
              T0)                                    ; Tank already moving right

(check-expect (update-tank-direction T0 "left")
              (make-tank (tank-x T0) -1))            ; Tank switches to moving left

(check-expect (update-tank-direction T2 "right")
              (make-tank (tank-x T2) 1))             ; Tanks switches to moving right

(check-expect (update-tank-direction T2 "left")
              T2)                                    ; Tank already moving left


;(define (update-tank-direction t ke) t) ; Stub

;<use template from Tank with additional KeyEvent parameter>

(define (update-tank-direction t ke)
  (if (key=? ke "left")
      (make-tank (tank-x t) -1)
      (make-tank (tank-x t) 1)))


;; ListOfMissile Tank -> ListOfMissile
;; adds a new missile to the ListOfMissile at the tanks current location (i.e. tank fires a missile)
(check-expect (add-missile empty T0)     ; Add missile to empty lom
              (list (make-missile (tank-x T0) MISSILE-LAUNCH-HEIGHT)))

(check-expect (add-missile (list M1) T1) ; Add missile to lom containing a missile
              (list (make-missile (tank-x T1) MISSILE-LAUNCH-HEIGHT) M1))

;(define (add-missile lom t) lom) ; Stub

;<use template from ListOfMissile with additional compound parameter (Tank)>

(define (add-missile lom t)
  (cond [(empty? lom)
         (list (make-missile (tank-x t) MISSILE-LAUNCH-HEIGHT))]
        [else
         (cons (make-missile (tank-x t) MISSILE-LAUNCH-HEIGHT) lom)]))


;(main (make-game empty empty T0)) ; Drive the Game