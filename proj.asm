;print
SET_X  EQU 600CH
SET_Y  EQU 600AH

SET_PIXEL  EQU 6012H
DELETE_WARNING  EQU 6040H

;screen
CLEAR_SCREEN  EQU 6002H
SET_BACKGROUND  EQU 6042H

MIN_SCREEN_WIDTH EQU 0
MAX_SCREEN_WIDTH EQU 64

MIN_SCREEN_HEIGHT EQU 0
MAX_SCREEN_HEIGHT EQU 32

;starting space ship coords
X  EQU 0
Y  EQU 28

;colors
RED  EQU 0FF00H
ORANGE  EQU 0FF95H
BLUE  EQU 0FCCFH
GRAY EQU 0FDDFH

;set table address
PLACE 0100H; address where table starts

pilha: 
  STACK 100H

INITIAL_SP:

DEF_SPACE_SHIP:
  WORD  5 ;lenght value of space ship
  WORD  4 ;height value of space ship
  
  ;define colors of space ship
	WORD  0, 0, GRAY, 0, 0		
	WORD  0, GRAY, 0, GRAY, 0
	WORD  BLUE, GRAY, GRAY, GRAY, BLUE
  WORD  ORANGE, 0, 0, 0, ORANGE


;codigo
PLACE 0

setup:
  MOV  SP, INITIAL_SP ;init stack pointer
  MOV [DELETE_WARNING], R1 ;delete background warning
  MOV [CLEAR_SCREEN], R1 ;clear pixels on screen
  MOV R1, 0 ;background 0
  MOV [SET_BACKGROUND], R1 ;set background

  MOV R7, +1; value to increment when moving
  ;initial set for momentum
  
start:
  ;set starting render position 
  MOV R1, X 
  MOV R2, Y

  ;set starting sprite and write action
  MOV R3, DEF_SPACE_SHIP ;set sprite table to be rendered
  MOV R8, 1 ;set action to "write"

  ;first render of the space ship
  CALL render_sprite
  JMP movement

render_sprite:
  ; R1 is the current "x" position
  ; R2 is the current "y" positioncurrent table index
  ; R4 is the sprite length
  ; R5 is the sprite height

  PUSH R1
  PUSH R2
  PUSH R3 ;save table address
  PUSH R4
  PUSH R5

  MOV R4, [R3]   ;get lenght of sprite
  MOV R5, [R3+2] ;get height of sprite

  ;get first pixel
  ADD R3, 2 ;move to  starting point of pixel rendering
  ; R3 is set to be the pixel before 
  
  MOV R6, R4 ;value of current index color of pixel to render
  
render_line:
  ; loop to render line of pixels
  ADD R3, 2 ;get pixel index to render
  CALL render_pixel
  ADD R1, 1 ;move to next horizontal render position
  SUB R6, 1 ;decrement index of column iterator
  JNZ render_line

  ;otherwise
  MOV R6, R4 ;reset index of column iterator
  SUB R1, R4 ;go back to the first column position
  ADD R2, 1 ;move to next "y" render position
  SUB R5, 1 ;decrement height of sprite
  JNZ render_line

  POP  R5
  POP  R4
  POP  R3
  POP  R2
  POP  R1
  RET
  

; function to render pixel 
; at line of address SET_LINE and column of address SET_COLUMN
; pixel color is in R3
render_pixel:
  PUSH R4
  PUSH R5

  MOV R5, 1 ;set R5 as constant 1

  AND R8, R5  ;check if action is "write"
  JZ delete_pixel ;if 0 then delete pixel
  MOV R4, [R3] ;get pixel color from index R3
  JMP set_pixel

  delete_pixel:
    MOV R4, 0 ;set pixel color to 0

  set_pixel:
    MOV [SET_X], R1 ;set line
    MOV [SET_Y], R2 ;set line
    MOV [SET_PIXEL], R4 ;change pixel color
    POP R5
    POP R4
    RET

movement:
  CALL check_right_boundary
  
  MOV R8, 0 ;set action to "delete"
  CALL render_sprite ; delete sprite with action setted previously

  ; R7 = +1 -> move right
  ; R7 = -1 -> move left
  ADD R1, R7 ;move sprite one pixel to setted direction

  MOV R8, 1 ;set action to "write"
  CALL render_sprite ;render sprite with action setted previously

  JMP movement

check_right_boundary:
  PUSH R1
  PUSH R5
  PUSH R6

  MOV R5, MAX_SCREEN_WIDTH ;get sprite table
  MOV R6, [R3] ;get lenght of sprite

  ADD R1, R6 ;get sprite right edge

  CMP R5, R1 ;check if sprite right edge is greater than screen right edge
  JZ else_check_right_boundary
  JMP endif_check_right_boundary

  else_check_right_boundary:
    CALL stop_movement

  endif_check_right_boundary:
    POP R6
    POP R5
    POP R1
    RET

check_left_boundary:
  PUSH R5

  MOV R5, MIN_SCREEN_WIDTH ;get screen min width
  
  CMP R5, R1 ;if this returns 0 then sprite is at left screen boundary and we can't move
  JZ else_check_left_boundary
  JMP endif_check_left_boundary

  else_check_left_boundary:
    CALL stop_movement

  endif_check_left_boundary:
    POP R5
    RET

;function to stop movement
stop_movement:
  MOV R7, 0 ;set momentum to 0
  RET
  
end:  
  JMP end