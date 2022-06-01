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

;keyboard
KEY_LIN				EQU 0C000H	; endereço das linhas do teclado (periférico POUT-2)
KEY_COL				EQU 0E000H	; endereço das colunas do teclado (periférico PIN)
KEY_MAX_LIN		EQU 8		; linha a testar (4ª linha)
MASK				  EQU 0FH	

;keys
KEY_0 EQU 00H
KEY_4 EQU 04H

;starting space ship coords
X  EQU 0
Y  EQU 28

;colors
RED  EQU 0FF00H
ORANGE  EQU 0FF95H
BLUE  EQU 0FCCFH
GRAY EQU 0FDDFH

;set table address
PLACE 1000H; address where table starts

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

  ;start keyboard listen
  JMP handle_keyboard

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
  MOV R8, 0 ;set action to "delete"
  CALL render_sprite ; delete sprite with action setted previously

  ; R7 = +1 -> move right
  ; R7 = -1 -> move left
  ADD R1, R7 ;move sprite one pixel to setted direction

  MOV R8, 1 ;set action to "write"
  CALL render_sprite ;render sprite with action setted previously

  RET

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
  
handle_keyboard:
  PUSH R0 ; R0 - column to test
  PUSH R6 ; R6 - line to test (1, 2, 4 ou 8)

  MOV R6, 1 ;first line to test 

  test_line:
    CALL listen_keyboard_line
    CMP R0, -1 ;if not pressed
    JNZ key_found
    ROL R6, 1
    JMP test_line
  
  key_found:
    CMP R0, KEY_0
    JZ key_0_func

    CMP R0, KEY_4
    JZ key_4_func

  ; Move space ship left
  key_0_func:
    MOV R7, -1 ;set momentum to -1
    CALL check_left_boundary
    CALL movement
    JMP handle_keyboard

  ; Move space ship right
  key_4_func:
    MOV R7, +1 ;set momentum to +1
    CALL check_right_boundary
    CALL movement
    JMP handle_keyboard


  POP R6
  POP R0

  JMP handle_keyboard

listen_keyboard_line:
  PUSH  R2
  PUSH  R3
  PUSH  R5
  
	MOV  R2, KEY_LIN ;adress of keyboard lines
	MOV  R3, KEY_COL ;adress of keyboard columns
	MOV  R5, MASK ;isolate the 4 dominant bits 
	MOVB [R2], R6 ;set the line to be read
	MOVB R0, [R3] ;read the column pressed
	AND  R0, R5 ;isolate the 4 dominant bits

  CMP R0, 0 ;check if there isn't any key pressed
  JZ set_not_found
  CALL convert_to_key ;convert column and line to key
  JMP return_key

  set_not_found:
    MOV R0, -1 ;set listened key as -1

  return_key:
    POP	R5
    POP	R3
    POP	R2
    RET


convert_to_key:
  PUSH R3
  PUSH R4
  PUSH R5

  ;first we need to normalize both line and column
  ;normalize column
  CALL normalize_index
  MOV R5, R9 ;save the normalized column value
  
  ;normalize line
  MOV R0, R6 ;set R0 to be the line value
  CALL normalize_index ;normalize line value
  MOV R4, R9 ;save the normalized line value

  MOV R3, 4 ;regist with constant 4 to multiply

  ;now we need to convert line and column to key
  MUL R4, R3 ;convert line and column to hexadecimao
            ; Value = (line * 4) + column

  ADD R4, R5 ;add column to line

  MOV R0, R4 ;save key on R0

  POP R5
  POP R4
  POP R3
  RET

normalize_index:
  MOV R9, -1 ;init counter as -1

    not_zero:
      ADD R9, 1 ;increment counter
      SHR R0, 1 ;shift to the right
      CMP R0, 0
      JNZ not_zero
    
  RET

end:  
  JMP end