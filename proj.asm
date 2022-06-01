;print
SET_X  EQU 600CH
SET_Y  EQU 600AH

SET_PIXEL  EQU 6012H
DELETE_WARNING  EQU 6040H

;screen
CLEAR_SCREEN EQU 6002H
SET_BACKGROUND EQU 6042H

MIN_SCREEN_WIDTH EQU 0
MAX_SCREEN_WIDTH EQU 64

MIN_SCREEN_HEIGHT EQU 0
MAX_SCREEN_HEIGHT EQU 32

;keyboard
KEY_LIN EQU 0C000H	; endereço das linhas do teclado (periférico POUT-2)
KEY_COL EQU 0E000H	; endereço das colunas do teclado (periférico PIN)
KEY_MAX_LIN EQU 8		; linha a testar (4ª linha)
MASK EQU 0FH	

;keys
KEY_LEFT EQU 00H
KEY_RIGHT EQU 02H
KEY_DOWN EQU 03H

;colors
;kinda nude 0FFAAH
;black 0F000H
BLACK EQU 0F000H
RED EQU 0FF00H
BROWN EQU 0FA52H
NUDE EQU 0FFB5H
BLUE EQU 0F06FH
WHITE EQU 0FFFFH

;set table address
PLACE 1000H; address where table starts

pilha: 
  STACK 100H

INITIAL_SP:

ENTITIE_MARIO:
  ;entity position
  WORD 30 ;default x
  WORD 25 ;default y

  ;entity sprite index
  WORD 0 ;default sprite index

  ;entity size
  WORD 5 ;lenght value of caracter
  WORD 5 ;height value of caracter
  
  ;sprite 0
  WORD 0, RED, RED, RED, RED		
  WORD 0, BLACK, NUDE, NUDE, 0
  WORD RED, BLUE, RED, BLUE, RED
  WORD WHITE, BLUE, BLUE, BLUE, WHITE
  WORD 0, BLACK, 0, BLACK, 0

  ;sprite 1
  WORD 0, BLUE, BLUE, BLUE, BLUE		
  WORD 0, BLACK, NUDE, NUDE, 0
  WORD BLUE, BLUE, BLUE, BLUE, BLUE
  WORD WHITE, BLUE, BLUE, BLUE, WHITE
  WORD 0, BLACK, 0, BLACK, 0

ENTITIE_GOOMBA:
  WORD 30 ;default x
  WORD 0 ;default y

  ;entity sprite index
  WORD 0 ;default sprite index

  ;entity size
  WORD 5 ;lenght value of caracter
  WORD 5 ;height value of caracter

  ;sprite 0
  WORD 0, 0, RED, 0, 0
  WORD 0, RED, WHITE, RED, 0
  WORD RED, WHITE, RED, RED, RED
  WORD 0, BLACK, NUDE, BLACK, 0
  WORD 0, NUDE, NUDE, NUDE, 0


;codigo
PLACE  0

setup:
  MOV  SP, INITIAL_SP ;init stack pointer
  MOV [DELETE_WARNING], R1 ;delete background warning
  MOV [CLEAR_SCREEN], R1 ;clear pixels on screen
  MOV R1, 0 ;background 0
  MOV [SET_BACKGROUND], R1 ;set background

  MOV R7, +1; value to increment when moving
  ;initial set for momentum
  
start:
  ;render initial entities
  MOV R8, 1 ;set action to "write"

  ;render mario
  MOV R3, ENTITIE_MARIO ;set sprite table to be rendered
  CALL render_sprite

  ;render goomba
  MOV R3, ENTITIE_GOOMBA
  CALL render_sprite

  ;start keyboard listen
  keyboard_handler_loop:  
    CALL handle_keyboard
    JMP keyboard_handler_loop

render_sprite:
  ; R1 is the current "x" position
  ; R2 is the current "y" positioncurrent table index
  ; R4 is the sprite length
  ; R5 is the sprite height

  PUSH R0
  PUSH R1
  PUSH R2
  PUSH R3
  PUSH R4
  PUSH R5
  PUSH R6
  PUSH R7

  ;get entity position
  MOV R1, [R3] ;x
  MOV R2, [R3+2] ;y

  ;get selected sprite
  MOV R7, [R3+4]

  ;get entity length
  MOV R4, [R3+6] ;get entity length
  MOV R5, [R3+8] ;get entity height

  ;get first pixel
  MOV R0, 8
  ADD R3, R0 ;move to starting point of sprite rendering
  ;R3 is set to be the address before 
  
  MOV R6, R4 ;starting iterator value
  
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

  POP R7
  POP R6
  POP R5
  POP R4
  POP R3
  POP R2
  POP R1
  POP R0
  RET

render_pixel:
  PUSH R4
  PUSH R5

  MOV R5, 1 ;set R5 as constant 1

  AND R8, R5 ;check if action is "write"
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

handle_keyboard:
  PUSH R0 ;R0 - column to test
  PUSH R1 ;max background index
  PUSH R2 ;temp store background value
  PUSH R6 ;R6 - line to test (1, 2, 4 ou 8)

  MOV R1, 8 ;set max background index

  MOV R6, 1 ;first line to test 

  test_line:
    CALL listen_keyboard_line
    CMP R0, -1 ;if not pressed
    JNZ handle_actions
    ROL R6, 1
    JMP test_line
  
  handle_actions:
    CMP R0, KEY_LEFT
    JZ move_mario_left

    CMP R0, KEY_RIGHT
    JZ move_mario_right

    CMP R0, KEY_DOWN
    JZ move_goomba_down

    ;the key doesn't have any action associated
    JMP return_handle

  move_mario_left:
    ;set action entity as mario
    MOV R3, ENTITIE_MARIO

    ;get current background index
    MOV R0, [SET_BACKGROUND]
    CMP R0, 0
    JZ cycle_background_left

    ADD R0, -1; increment background index
    JMP set_background_left; 

    cycle_background_left:
      MOV R0, R1 ;set background to max index

    set_background_left:
      MOV [SET_BACKGROUND], R0 ;set new background

    ;move
    MOV R7, -1 ;set momentum to -1

    CALL check_left_boundary
    CALL movement
    JMP return_handle

  move_mario_right:
    ;set action entity as mario
    MOV R3, ENTITIE_MARIO

    ;get current background index
    MOV R0, [SET_BACKGROUND]
    CMP R1, R0
    JZ cycle_background_right

    ADD R0, 1; increment background index
    JMP set_background_right; 

    cycle_background_right:
      MOV R0, 0 ;set background back to 0

    set_background_right:
      MOV [SET_BACKGROUND], R0 ;set new background

    ;move
    MOV R7, +1 ;set momentum to +1

    CALL check_right_boundary
    CALL movement
    JMP return_handle

  move_goomba_down:
    ;set action entity as goomba
    MOV R3, ENTITIE_GOOMBA

    ;move
    MOV R7, 2 ;set momentum as 2 (special value for falling entities)

    CALL check_bottom_boundary
    CALL movement

  return_handle:
    POP R6
    POP R2
    POP R1
    POP R0
    RET

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

; R7 = 0 -> stay in the same position
; R7 = +1 -> move right
; R7 = -1 -> move left
movement:
  PUSH R1
  PUSH R2

  CMP R7, 0
  JZ return_movement ;if R7 is set to 0, then don't move

  ;otherwise start by deleting the old sprite
  MOV R8, 0 ;set action to "delete"
  CALL render_sprite ; delete sprite with action setted previously
  
  ;get entity position
  MOV R1, [R3] ;x 
  MOV R2, [R3+2] ;y

  ;check if we have the special value for falling entities (2)
  CMP R7, 2
  JZ vertical_move

  ;horizontal movement
  ADD R1, R7 ;move entity one pixel to setted direction
  JMP update_position_scope

  vertical_move:
    ADD R2, 1 ;move entity one pixel down

  ;update position on entity scope
  update_position_scope:
    MOV [R3], R1 ;x
    MOV [R3+2], R2 ;y

  MOV R8, 1 ;set action to "write"
  CALL render_sprite ;render sprite with action setted previously

  return_movement:
    POP R2
    POP R1
    RET

check_right_boundary:
  PUSH R1
  PUSH R5
  PUSH R6

  ;get entity X position
  MOV R1, [R3]

  MOV R5, MAX_SCREEN_WIDTH ;get screen max width
  MOV R6, [R3+6] ;get lenght of the entity

  ADD R1, R6 ;get sprite right edge

  CMP R5, R1 ;check if sprite right edge is greater than screen right edge
  JZ if_right_collision
  JMP return_check_right

  if_right_collision:
    CALL stop_movement

  return_check_right:
    POP R6
    POP R5
    POP R1
    RET

check_left_boundary:
  PUSH R5

  ;get entity X postion
  MOV R1, [R3]

  MOV R5, MIN_SCREEN_WIDTH ;get screen min width
  
  CMP R5, R1 ;if this returns 0 then sprite is at left screen boundary and we can't move
  JZ if_left_collision
  JMP return_check_left

  if_left_collision:
    CALL stop_movement

  return_check_left:
    POP R5
    RET

check_bottom_boundary:
  PUSH R1
  PUSH R2
  PUSH R3

  ;get entity Y position
  MOV R1, [R3+2]

  ;get entity height
  MOV R2, [R3+8]

  ;calc max Y position
  MOV R3, MAX_SCREEN_HEIGHT

  ;subtract 2 because of the ground
  SUB R3, 2

  ;get entity bottom edge
  ADD R1, R2

  ;check colision with ground
  CMP R1, R3
  JZ if_bottom_collision
  JMP return_check_bottom

  if_bottom_collision:
    CALL stop_movement

  return_check_bottom:
    POP R3
    POP R2
    POP R1
    RET


stop_movement:
  MOV R7, 0 ;set momentum to 0
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
    JGT not_zero ;if not zero then continue
    
  RET

end:  
  JMP end