; *********************************************************************************
; * -- GRUPO 17 --
; * Entrega intermédia
; 
; * André Santos - 103597
; * João Correia - 102843
; * Margarida Chinopa - 102991
; *********************************************************************************

;**********************************************************************************
;-----------------------------------CONSTANTS--------------------------------------
;**********************************************************************************

;print
SET_X EQU 600CH
SET_Y EQU 600AH

SET_PIXEL EQU 6012H
DELETE_WARNING EQU 6040H

;screen
CLEAR_SCREEN EQU 6002H
SET_BACKGROUND EQU 6042H

MIN_SCREEN_WIDTH EQU 0
MAX_SCREEN_WIDTH EQU 64

MIN_SCREEN_HEIGHT EQU 0
MAX_SCREEN_HEIGHT EQU 32

;audio
PLAY_SOUND EQU 0605AH

;energy display
SET_ENERGY EQU 0A000H ;address of energy display (POUT-1)
MAX_ENERGY EQU 064H
MIN_ENERGY EQU 0H

;keyboard
SET_KEY_LINE EQU 0C000H ;address of keyboard lines (POUT-2)
READ_KEY_COL EQU 0E000H ;adress of keyboard colums (PIN)
KEY_MAX_LIN EQU 8 ;max keyboard line
MASK EQU 0FH	

;keys
KEY_LEFT EQU 00H
KEY_RIGHT EQU 02H
KEY_DOWN EQU 03H
KEY_ENERGY_UP EQU 04H
KEY_ENERGY_DOWN EQU 05H

KEY_GEN_NUM EQU 06H

;pin
PIN_INPUT EQU 0E000H

;colors
BLACK EQU 0F000H
RED EQU 0FF00H
BROWN EQU 0FA52H
NUDE EQU 0FFB5H
BLUE EQU 0F06FH
WHITE EQU 0FFFFH

;**********************************************************************************
;-------------------------------------DADOS----------------------------------------
;**********************************************************************************

;set table address
PLACE 1000H; address where table starts

pilha: 
  STACK 100H

INITIAL_SP:

num_gen_n:
  WORD 0

; Tabela das rotinas de interrupção
tab:
	WORD rot_int_0			; rotina de atendimento da interrupção 0
	WORD rot_int_1			; rotina de atendimento da interrupção 1
	WORD rot_int_2			; rotina de atendimento da interrupção 2


ENTITY_MARIO:
  ;entity position
  WORD 30 ;default x
  WORD 25 ;default y

  ;entity sprite index
  WORD 1 ;default sprite index

  ;entity size
  WORD 5 ;lenght value of caracter
  WORD 5 ;height value of caracter
  
  ;sprite #0 (mario looking forward)
  WORD 0, RED, RED, RED, 0		
  WORD 0, BLACK, NUDE, BLACK, 0
  WORD RED, BLUE, RED, BLUE, RED
  WORD WHITE, BLUE, BLUE, BLUE, WHITE
  WORD 0, BLACK, 0, BLACK, 0

  ;sprite #1 (mario looking left)
  WORD RED, RED, RED, RED, 0		
  WORD 0, NUDE, NUDE, BLACK, 0
  WORD RED, BLUE, RED, BLUE, RED
  WORD WHITE, BLUE, BLUE, BLUE, WHITE
  WORD 0, BLACK, 0, BLACK, 0

  ;sprite #2 (mario looking right)
  WORD 0, RED, RED, RED, RED		
  WORD 0, BLACK, NUDE, NUDE, 0
  WORD RED, BLUE, RED, BLUE, RED
  WORD WHITE, BLUE, BLUE, BLUE, WHITE
  WORD 0, BLACK, 0, BLACK, 0


ENTITY_GOOMBA:
  WORD 30 ;default x
  WORD 0 ;default y

  ;entity sprite index
  WORD 0 ;default sprite index

  ;entity size
  WORD 5 ;lenght value of caracter
  WORD 5 ;height value of caracter

  ;sprite 0
  WORD 0, 0, BROWN, 0, 0
  WORD 0, BROWN, WHITE, BROWN, 0
  WORD BROWN, WHITE, BROWN, BROWN, BROWN
  WORD 0, BLACK, NUDE, BLACK, 0
  WORD 0, NUDE, NUDE, NUDE, 0

;**********************************************************************************
;--------------------------------------CODE----------------------------------------
;**********************************************************************************

PLACE  0

setup:
  MOV  SP, INITIAL_SP ;init stack pointer
  MOV [DELETE_WARNING], R1 ;delete background warning
  MOV [CLEAR_SCREEN], R1 ;clear pixels on screen
  MOV R1, 0 ;background 0
  MOV [SET_BACKGROUND], R1 ;set background


  MOV  BTE, tab			; inicializa BTE (registo de Base da Tabela de Exceções)

  EI0
  EI1
  EI2
  EI
  
start:
  MOV R2, SET_ENERGY
  MOV R7, 100H
  MOV [R2], R7
  ;render initial entities:

  ;render idling mario
  CALL idle_mario

  ;render goomba
  MOV R8, 1 ;set action to "write"
  MOV R3, ENTITY_GOOMBA ;set entity to goomba
  CALL render_sprite

  ;start keyboard listen
  keyboard_handler_loop:  
    CALL handle_keyboard
    JMP keyboard_handler_loop

; **********************************************************************
; RENDER_SPRITE :
;   - function to render the sprites
;   - loops through all the lines and set each pixel at a time with the 
; colors from the sprite
;   - the x and y positions to start rendering from are grabbed from the entitie
;   - the sprite is set by the sprite index also stored on the entity table
; **********************************************************************
render_sprite:
  PUSH R0 ;register to temp store values
  PUSH R1 ;x
  PUSH R2 ;y
  PUSH R3 ;pixel n 
  PUSH R4 ;lenght
  PUSH R5 ;width
  PUSH R6 ;iterator
  PUSH R7 ;selected sprite

  ;get entity position
  MOV R1, [R3] ;x
  MOV R2, [R3+2] ;y

  ;get selected sprite index
  MOV R7, [R3+4]

  ;get entity length
  MOV R4, [R3+6] ;get entity length
  MOV R5, [R3+8] ;get entity height

  ;get first pixel of the first sprite
  MOV R0, 10
  ADD R3, R0 ;move to starting point of sprite rendering
  ;R3 is set to be the address before 

  ;calc how much bytes we need to skip to render next sprite
  ;skip n lenght pixels * 2
  MUL R7, R5 
  MOV R0, 2;
  MUL R7, R0

  ;skip n height pixels
  MUL R7, R5

  ;get first pixel of the selected sprite
  ADD R3, R7

  MOV R6, R4 ;starting iterator value
  
  render_line:
    ; loop to render line of pixels
    CALL render_pixel
    ADD R3, 2 ;get pixel index to render
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

; **********************************************************************
; RENDER_PIXEL :
;   - function to render or remove a pixel, its color is given by R3
;   - R8 is either "write" (1) or "delete" (0)
; **********************************************************************
render_pixel:
  PUSH R4
    
  ;if action is set to 0 then delete pixel
  CMP R8, 0
  JZ delete_pixel

  ;otherwise
  MOV R4, [R3] ;get pixel color from index R3
  JMP set_pixel

  delete_pixel:
    MOV R4, 0 ;set pixel color to 0

  set_pixel:
    MOV [SET_X], R1 ;set line
    MOV [SET_Y], R2 ;set line
    MOV [SET_PIXEL], R4 ;change pixel color
    
  POP R4
  RET

; **********************************************************************
; HANDLE_KEYBOARD :
;  - loop until a key is pressed on keyboard and execute function accordingly
; **********************************************************************
handle_keyboard:
  PUSH R0 ;key that was listened / current background index
  PUSH R1 ;max line / max background index
  PUSH R2 ;constant to convert hext to decimal
  PUSH R6 ;line to test / sprite to render / constant to convert hext to decimal
  PUSH R7 ;direction to move / constant to convert hext to decimal
  PUSH R8 ;stores R10 to convert from hex to decimal

  MOV R1, 8 ;max line and max background are both 8

  MOV R6, 1 ;start by listening on line 1

  ;loop through all the lines to check if any key was pressed
  test_line:
    CALL listen_keyboard_line
    
    ;if a key is being pressed
    CMP R0, -1
    JNZ handle_actions

    ;otherwise 
    ROL R6, 1 ;test next line by rotating to the left

    ;render mario idle sprite when no key is being pressed
    CALL idle_mario

    ;check if we already listened the whole keyboard
    CMP R6, R1
    JNZ test_line; R6 != 8, just continue listening the keyboard lines ahead

    ;otherwise 
    ;reset last key pressed
    MOV R4, -1

    ;start listening from begining
    JMP test_line
  
  handle_actions:
    CMP R0, KEY_LEFT
    JZ move_mario_left

    CMP R0, KEY_RIGHT
    JZ move_mario_right

    CMP R0, KEY_DOWN
    JZ move_goomba_down

    CMP R0, KEY_ENERGY_UP
    JZ energy_increase

    CMP R0, KEY_ENERGY_DOWN
    JZ energy_decrease

    CMP R0, KEY_GEN_NUM
    JZ gen_number

    ;the key doesn't have any action associated
    JMP return_handle

; **********************************************************************
; MOVE_MARIO_LEFT :
;  - function to move mario left
;  - by pressing the key "0", mario moves left
;  - it enables you to keep pressing the key to continue moving
; **********************************************************************
  move_mario_left:
    ;get current background index
    MOV R0, [SET_BACKGROUND]
    CMP R0, 0 ;0 is the lowest background index
    JZ cycle_background_left

    ADD R0, -1; increment background index
    JMP set_background_left; 

    cycle_background_left:
      MOV R0, R1 ;set background to max index

    set_background_left:
      MOV [SET_BACKGROUND], R0 ;set new background

    ;move:
    ;set action entity as mario
    MOV R3, ENTITY_MARIO

    ;set sprite to render (left)
    MOV R6, 1
    MOV [R3+4], R6

    MOV R7, -1 ;set direction to the left (-1)

    CALL check_left_boundary
    CALL movement
    JMP return_handle

; **********************************************************************
; MOVE_MARIO_RIGHT :
;  - function to move mario right
;  - by pressing the key "2", mario moves right
;  - it enables you to keep pressing the key to continue moving
; **********************************************************************
  move_mario_right:
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

    ;move:
    ;set action entity as mario
    MOV R3, ENTITY_MARIO

    ;set sprite to render (right)
    MOV R6, 2
    MOV [R3+4], R6

    MOV R7, +1 ;set direction to the right (+1)

    CALL check_right_boundary
    CALL movement
    JMP return_handle

; **********************************************************************
; MOVE_GOOMBA_DOWN :
;  - function to move goomba down
;  - by pressing "3", goomba moves down
;  - it only moves one pixel at a time
; **********************************************************************
  move_goomba_down:
    ;if last action was goomba down, skip it
    CMP R4, R0;
    JZ return_handle

    ;set action entity as goomba
    MOV R3, ENTITY_GOOMBA

    ;move
    MOV R7, 2 ;set direction as 2 (special value for falling entities)

    CALL check_bottom_boundary
    CALL movement
    JMP return_handle

; **********************************************************************
; ENERGY_INCREASE :
;  - function to increase energy level
;  - by pressing "4", energy increases by 1
;  - it only increases 1 at a time
; **********************************************************************
  energy_increase:
    ;if last action was energy increase, skip it
    CMP R4, R0
    JZ return_handle

    MOV R7, MAX_ENERGY

    CMP R10, R7
    JZ return_handle

    ; Logic for units
    ;otherwise
    increase_one: 
      ADD R10, 5

    set_increase_energy:
      MOV R2, SET_ENERGY
      MOV R7, R10
      CALL hexa_to_decimal
      MOV [R2], R8

    JMP return_handle

; **********************************************************************
; ENERGY_DECREASE :
;   - function to decrease energy level
;   - by pressing "5", energy decreases by 1
;   - it only decreases 1 at a time
; **********************************************************************
  energy_decrease:
    ;if last action was energy decrease, skip it
    CMP R4, R0
    JZ return_handle

    MOV R7, MIN_ENERGY

    CMP R10, R7
    JZ return_handle

    ;otherwise
    decrease_one:   
      SUB R10, 5

    set_decrease_energy:
      ;save energy value
      MOV R2, SET_ENERGY
      MOV R7, R10
      CALL hexa_to_decimal
      MOV [R2], R8

    JMP return_handle

; **********************************************************************
; GEN_NUMBER:
;  - function to generate a random number
;  - it generates a random number between 0 and 7
; **********************************************************************
  gen_number:
    ;generate a random number between 0 and 7
    MOV R1, [PIN_INPUT]
    MOV R2, 8

    MOD R1, R2

    JMP return_handle

  return_handle:
    ;save pressed key for later checks
    MOV R4, R0

    POP R8
    POP R7
    POP R6
    POP R2
    POP R1
    POP R0
    RET
    
; **********************************************************************
; LISTEN_KEYBOARD_LINE :
;  - function to listen to keyboard line
;  - if key is pressed is moved to register R0
;  - if key is not pressed, R0 is set to -1
; **********************************************************************
listen_keyboard_line:
  PUSH R2
  PUSH R3
  PUSH R5
  
  MOV R2, SET_KEY_LINE ;adress of keyboard lines
  MOV R3, READ_KEY_COL ;adress of keyboard columns
  MOV R5, MASK ;isolate the 4 dominant bits 
  MOVB [R2], R6 ;set the line to be read
  MOVB R0, [R3] ;read the column pressed
  AND R0, R5 ;isolate the 4 dominant bits

  ;if there isn't any key being pressed
  CMP R0, 0
  JZ set_not_found

  ;otherwise
  CALL convert_to_key ;convert column and line to key
  JMP return_key

  set_not_found:
    MOV R0, -1 ;set listened key as -1

  return_key:
    POP	R5
    POP	R3
    POP	R2
    RET

; **********************************************************************
; MOVEMENT :
;  - function that represents sprite movement
;  - R7 represents the momentum of the sprite
;  - R8 represents the action of "writing" (1) or "deleting" (0) the sprite pixels
; **********************************************************************
movement:
  PUSH R1
  PUSH R2
  PUSH R6
  PUSH R7
  PUSH R8

  CMP R7, 0 ;if direction is set to 0, don't move
  JZ return_movement

  ;otherwise start by deleting the old sprite
  MOV R8, 0 ;set action to "delete"
  CALL render_sprite ; delete sprite with action setted previously

  ;check if we have the special value for falling entities (2)
  CMP R7, 2
  JZ vertical_move

  ;horizontal movement
  MOV R1, [R3] ;get entity x postion
  ADD R1, R7 ;add direction to x position (1 or -1)
  ;update entity x
  MOV [R3], R1
  JMP render_new_position

  ;vertical movement
  vertical_move:
    ;play sound #0
    MOV R6, 0
    MOV [PLAY_SOUND], R6

    MOV R2, [R3+2] ;get entity y postion
    ADD R2, 1 ;add 1 to y position
    ;update entity y
    MOV [R3+2], R2
    JMP render_new_position

  ;update position on entity scope
  update_position_scope:
    MOV [R3], R1 ;x
    MOV [R3+2], R2 ;y

  ;render new-position
  render_new_position:
    MOV R8, 1 ;set action to "write"
    CALL render_sprite

  return_movement:
    POP R8
    POP R7
    POP R6
    POP R2
    POP R1
    RET

; **********************************************************************
; CHECK_RIGHT_BOUNDARY :
;  - function to check if sprite is allowed to move right
;  - if it isn't allowed, stop movement is called
; **********************************************************************
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

; **********************************************************************
; CHECK_LEFT_BOUNDARY :
;  - function to check if sprite is allowed to move left
;  - if it isn't allowed, stop movement is called
; **********************************************************************
check_left_boundary:
  PUSH R1
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
    POP R1
    RET

; **********************************************************************
; CHECK_BOTTOM_BOUNDARY :
;  - function to check if sprite is allowed to move down
;  - if it isn't allowed, stop movement is called
; **********************************************************************
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

; **********************************************************************
; STOP_MOVEMENT :
;  - function to set direction as 0, stoping the movement function
; **********************************************************************
stop_movement:
  MOV R7, 0 ;set direction to 0
  RET

; **********************************************************************
; CONVERT_TO_KEY :
;  - function to convert column and line to keyboard key in hexadecimal
; **********************************************************************
convert_to_key:
  PUSH R3
  PUSH R4
  PUSH R5

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

; **********************************************************************
; NORMALIZE_INDEX :
;  - function to normalize index's (1, 2, 4, 8) -> (0,1,2,3)
; **********************************************************************
normalize_index:
  MOV R9, -1 ;init counter as -1

  not_zero:
    ADD R9, 1 ;increment counter
    SHR R0, 1 ;shift to the right
    CMP R0, 0
    JGT not_zero ;if not zero then continue
    
  RET

; **********************************************************************
; IDLE_MARIO :
;  - function to render mario idle sprite
; **********************************************************************
idle_mario:
  PUSH R3
  PUSH R4
  PUSH R6
  PUSH R8

  ;set action entity as mario
  MOV R3, ENTITY_MARIO

  ;get selected sprite
  MOV R4, [R3+4] ;

  ;if mario is already idling return function
  CMP R4, 0 
  JZ return_idle_mario

  ;otherwise
  ;delete old sprite
  MOV R8, 0 ;set action to "delete"
  CALL render_sprite

  ;set sprite to render (idle, looking forward)
  MOV R6, 0
  MOV [R3+4], R6

  ;render new sprite
  MOV R8, 1 ;set action to "write"
  CALL render_sprite

  return_idle_mario:
    POP R8
    POP R6
    POP R4
    POP R3
    RET

; **********************************************************************
; hexa_decimal :
;  - function to convert hexadecimal to decimal
;  - R7 has the hexadecimal value
;  - R8 has the result
; **********************************************************************
; numero R7
; resultado R8
; fator R1
; div constant R2
; digito R3
hexa_to_decimal:
  PUSH R1
  PUSH R2
  PUSH R3
  
  MOV R1, 1000
  MOV R2, 10

  MOV R8, 0

  hexa_to_decimal_loop_start:
    MOD R7, R1 ; número = número MOD fator; número é o valor a converter
    DIV R1, R2 ; fator = fator DIV 10; fator de divisão (começar em 1000 decimal)

    CMP R1, 0 ; se fator for 0, termina o loop
    JZ hexa_to_decimal_loop_end

    MOV R3, R7 ; dígito = número DIV fator; mais um dígito do valor decimal
    DIV R3, R1

    SHL R8, 4  ; resultado = resultado SHL 4; desloca, para dar espaço ao novo dígito
    OR R8, R3  ; resultado = resultado OR dígito; vai compondo o resultado

    JMP hexa_to_decimal_loop_start

  hexa_to_decimal_loop_end:
    POP R3
    POP R2
    POP R1

  RET


; **********************************************************************
; ROT_INT_0 - 
; **********************************************************************
rot_int_0:
  RFE					; Return From Exception (diferente do RET)
; **********************************************************************
; ROT_INT_1 - 
; **********************************************************************
rot_int_1:
  RFE					; Return From Exception (diferente do RET)
; **********************************************************************
; ROT_INT_2 - 
; **********************************************************************
rot_int_2:
  RFE					; Return From Exception (diferente do RET)