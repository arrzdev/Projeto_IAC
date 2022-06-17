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

;pin
PIN_INPUT EQU 0E000H

;keys
KEY_LEFT EQU 00H
KEY_RIGHT EQU 02H
KEY_SHOOT EQU 01H
KEY_ENERGY_UP EQU 04H
KEY_ENERGY_DOWN EQU 05H

;colors
BLACK EQU 0F000H
GRAY EQU 0F888H
RED EQU 0FF00H
DARKRED EQU	0FE00H
GREEN EQU	0F0F0H	
DARKGREEN EQU	0F0A0H	
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

CURRENT_PRESSED_KEY:
  WORD -1 ;default value for current pressed key

LAST_PRESSED_KEY:
  WORD -1 ;default value for last pressed key

CURRENT_ENERGY:
  WORD 064H ;starting value (100% energy)

;FLAGS
ENERGY_FLAG:
  WORD 0 ;by default flag is 0 (no energy update)

AGENTS_FLAG:
  WORD 0 ;by default flag is 0 (no agents update)

PROJECTILE_FLAG:
  WORD 0 ;by default flag is 0 (no projectile update)
;EXCEPTIONS TABLE
TAB:
  WORD rot_agents
  WORD rot_projectile
  WORD rot_energy
;ENTITIES:
AGENTS:
  ;number of agents
  WORD 4

  ;agent 1
  WORD 0, 0, -1, ENEMY_SPRITES ;(x, y, stage, sprites)

  ;agent 2
  WORD 0, 0, -1, FRIEND_SPRITES ;(x, y, stage, sprites)

  ;agent 3
  WORD 0, 0, -1, ENEMY_SPRITES ;(x, y, stage, sprites)

  ;agent 4
  WORD 0, 0, -1, FRIEND_SPRITES ;(x, y, stage, sprites)

PLAYER:
  WORD 30, 25, -1, PLAYER_SPRITES ;(x, y, stage, current_sprite)

PROJECTILE:
  WORD 0, 0, -1, PROJECTILE_SPRITES ;(x, y, stage, sprites)

;SPRITES
PLAYER_SPRITES:
  ;sprite #0 (player looking forward)
  WORD 5 ;lenght
  WORD 5 ;height
  WORD 0, RED, RED, RED, 0		
  WORD 0, BLACK, NUDE, BLACK, 0
  WORD RED, BLUE, RED, BLUE, RED
  WORD WHITE, BLUE, BLUE, BLUE, WHITE
  WORD 0, BLACK, 0, BLACK, 0

  ;sprite #1 (player looking left)
  WORD 5 ;lenght
  WORD 5 ;height
  WORD RED, RED, RED, RED, 0		
  WORD 0, NUDE, NUDE, BLACK, 0
  WORD RED, BLUE, RED, BLUE, RED
  WORD WHITE, BLUE, BLUE, BLUE, WHITE
  WORD 0, BLACK, 0, BLACK, 0

  ;sprite #2 (player looking right)
  WORD 5 ;lenght
  WORD 5 ;height
  WORD 0, RED, RED, RED, RED		
  WORD 0, BLACK, NUDE, NUDE, 0
  WORD RED, BLUE, RED, BLUE, RED
  WORD WHITE, BLUE, BLUE, BLUE, WHITE
  WORD 0, BLACK, 0, BLACK, 0

ENEMY_SPRITES:
  ;sprite #0 
  WORD 1 ;lenght
  WORD 1 ;height
  WORD GRAY		

  ;sprite #1
  WORD 2 ;lenght
  WORD 2 ;height
  WORD GRAY, GRAY
  WORD GRAY, GRAY

  ;sprite #2 
  WORD 3 ;lenght
  WORD 3 ;height
  WORD 0, NUDE, 0
  WORD NUDE, RED, NUDE
  WORD 0, NUDE, 0

  ;sprite #3 
  WORD 4 ;lenght
  WORD 4 ;height
  WORD 0, NUDE, NUDE, 0
  WORD NUDE, RED, RED, NUDE
  WORD NUDE, RED, RED, NUDE
  WORD 0, NUDE, NUDE, 0

  ;sprite #4 
  WORD 5 ;lenght
  WORD 5 ;height
  WORD 0, NUDE, NUDE, NUDE, 0
  WORD NUDE, DARKRED, RED, DARKRED, NUDE
  WORD NUDE, RED, DARKRED, RED, NUDE
  WORD NUDE, DARKRED, RED, DARKRED, NUDE
  WORD 0, NUDE, NUDE, NUDE, 0


FRIEND_SPRITES:
  ;sprite #0 
  WORD 1 ;lenght
  WORD 1 ;height
  WORD GRAY		

  ;sprite #1
  WORD 2 ;lenght
  WORD 2 ;height
  WORD GRAY, GRAY
  WORD GRAY, GRAY

  ;sprite #2 
  WORD 3 ;lenght
  WORD 3 ;height
  WORD 0, NUDE, 0
  WORD NUDE, GREEN, NUDE
  WORD 0, NUDE, 0

  ;sprite #3 
  WORD 4 ;lenght
  WORD 4 ;height
  WORD 0, NUDE, NUDE, 0
  WORD NUDE, GREEN, GREEN, NUDE
  WORD NUDE, GREEN, GREEN, NUDE
  WORD 0, NUDE, NUDE, 0

  ;sprite #4 
  WORD 5 ;lenght
  WORD 5 ;height
  WORD 0, NUDE, NUDE, NUDE, 0
  WORD NUDE, DARKGREEN, GREEN, DARKGREEN, NUDE
  WORD NUDE, GREEN, DARKGREEN, GREEN, NUDE
  WORD NUDE, DARKGREEN, GREEN, DARKGREEN, NUDE
  WORD 0, NUDE, NUDE, NUDE, 0

PROJECTILE_SPRITES:
  WORD 1 ;lenght
  WORD 1 ;width
  WORD GREEN

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
  MOV R2, 100H
  MOV [SET_ENERGY], R2 ;set initial energy
  MOV BTE, TAB			; inicializa BTE (registo de Base da Tabela de Exceções)

  ;init exceptions
  EI0
  EI1
  EI2
  EI
  
start:
  ;start keyboard listen
  game_handler_loop:  
    ;read the lines of the keyboard and return the read key at R0
    CALL handle_keyboard

    ;handle updates
    CALL energy_update
    CALL agents_update
    CALL projectile_update

    ;handle keyboard actions
    CALL handle_actions

    JMP game_handler_loop

; **********************************************************************
; RENDER_SPRITE :
;   - function to render the sprites
;   - loops through all the lines and set each pixel at a time with the 
; colors from the sprite
;   - the x and y positions to start rendering from are grabbed from the entity
;   - the sprite is set by the sprite index also stored on the entity table
; **********************************************************************
render_sprite:
  PUSH R0 ;register to temp store values
  PUSH R6 ;iterator

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

  POP R6
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
  PUSH R0
  PUSH R1 ;max line / max background index
  PUSH R6 ;line to test / sprite to render / constant to convert hext to decimal

  MOV R1, 8 ;max line and max background are both 8

  MOV R6, 1 ;start by listening on line 1

  ;loop through all the lines to check if any key was pressed
  test_line:
    CALL listen_keyboard_line
    
    ;if a key is being pressed
    CMP R0, -1
    JNZ return_handle_keyboard
    
    ;check if we already listened the whole keyboard
    CMP R6, R1 ;R6 == 8
    JZ return_handle_keyboard

    ;otherwise 
    ROL R6, 1 ;test next line by rotating to the left
    JMP test_line

  return_handle_keyboard:
    ;save the pressed key
    MOV [CURRENT_PRESSED_KEY], R0

    POP R6
    POP R1
    POP R0
    RET
  
handle_actions:
  PUSH R0 ;key that was listened / current background index
  PUSH R1 ;max line / max background index
  PUSH R2
  PUSH R3
  PUSH R4
  PUSH R6
  PUSH R7
  PUSH R8
  PUSH R10

  ;if key pressed == -1 skip key checks
  MOV R0, [CURRENT_PRESSED_KEY]
  CMP R0, -1
  JZ no_key_pressed

  MOV R1, 8 ;max background index

  CMP R0, KEY_LEFT
  JZ move_player_left

  CMP R0, KEY_RIGHT
  JZ move_player_right

  CMP R0, KEY_SHOOT
  JZ shoot_projectile

  ;the key doesn't have any action associated
  JMP return_handle_actions

  ; **********************************************************************
  ; MOVE_MARIO_LEFT :
  ;  - function to move mario left
  ;  - by pressing the key "0", mario moves left
  ;  - it enables you to keep pressing the key to continue moving
  ; **********************************************************************
  move_player_left:
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
    ;set entity as player
    MOV R3, PLAYER

    ;change entity state to 1 (left)
    MOV R6, 1
    MOV [R3+4], R6

    MOV R7, -1 ;set direction to the left (-1)

    CALL check_left_boundary
    CALL movement
    JMP return_handle_actions

  ; **********************************************************************
  ; MOVE_MARIO_RIGHT :
  ;  - function to move mario right
  ;  - by pressing the key "2", mario moves right
  ;  - it enables you to keep pressing the key to continue moving
  ; **********************************************************************
  move_player_right:
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
    MOV R3, PLAYER

    ;change entity state to 2 (right)
    MOV R6, 2
    MOV [R3+4], R6

    MOV R7, +1 ;set direction to the right (+1)

    CALL check_right_boundary
    CALL movement
    JMP return_handle_actions

  shoot_projectile:
    ;check if a projectile already exist
    MOV R0, [PROJECTILE+4] ;get projectile stage
    CMP R0, 0 ;check if projectile exists
    JZ return_handle_actions ;if projectile already exists don't do anything

    ;create projectile
    ;get player current position
    MOV R4, [PLAYER] ;x
    MOV R5, [PLAYER+2] ;y

    ;set projectile position
    ADD R4, 2 ;add 2 to shoot in the midle of the player
    SUB R5, 1 ;add 1 to shoot above the player
    MOV [PROJECTILE], R4 ;set x on the middle of mario
    MOV [PROJECTILE+2], R5

    ;set projectile stage to 0
    MOV R0, 0
    MOV [PROJECTILE+4], R0

    ;render
    MOV R3, PROJECTILE ;set render entity 
    MOV R8, 1 ;set action as write
    CALL render_entity

    ;remove 5 energy
    CALL energy_decrease

    JMP return_handle_actions

  no_key_pressed:
    ;save this key as last pressed key
    MOV [LAST_PRESSED_KEY], R0

    ;render player idle
    CALL player_idle

  return_handle_actions:
    POP R10
    POP R8
    POP R7
    POP R6
    POP R4
    POP R3
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
  PUSH R4
  
  MOV R2, SET_KEY_LINE ;adress of keyboard lines
  MOV R3, READ_KEY_COL ;adress of keyboard columns
  MOV R4, MASK ;isolate the 4 dominant bits 
  MOVB [R2], R6 ;set the line to be read
  MOVB R0, [R3] ;read the column pressed
  AND R0, R4 ;isolate the 4 dominant bits

  ;if there isn't any key being pressed
  CMP R0, 0
  JZ set_not_found

  ;otherwise
  CALL convert_to_key ;convert column and line to key
  JMP return_key

  set_not_found:
    MOV R0, -1 ;set listened key as -1

  return_key:
    POP	R4
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
  CALL render_entity ; delete sprite with action setted previously

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
    CALL render_entity

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
  MOV R6, 5 ;get lenght of the entity

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
; ENERGY_INCREASE :
;  - function to increase energy level
;  - by pressing "4", energy increases by 1
;  - it only increases 1 at a time
; **********************************************************************
energy_increase:
  PUSH R2
  PUSH R7
  PUSH R8
  PUSH R10

  MOV R10, [CURRENT_ENERGY] ;get current energy
  
  ;if current energy is 100 skip it
  MOV R7, MAX_ENERGY
  CMP R10, R7
  JZ return_energy_encrease

  ;otherwise
  ADD R10, 5
  CALL hexa_to_decimal

  ;save new energy
  MOV [CURRENT_ENERGY], R10

  ;set new energy on display
  MOV R2, SET_ENERGY
  MOV [R2], R8

  return_energy_encrease:
    POP R10
    POP R8
    POP R7
    POP R2
    RET

; **********************************************************************
; ENERGY_DECREASE :
;   - function to decrease energy level
;   - by pressing "5", energy decreases by 1
;   - it only decreases 1 at a time
; **********************************************************************
energy_decrease:
  PUSH R2
  PUSH R7
  PUSH R8
  PUSH R10

  MOV R10, [CURRENT_ENERGY] ;get current energy
  
  ;if current energy is 0 skip it
  MOV R7, MIN_ENERGY
  CMP R10, R7
  JZ return_energy_decrease

  ;otherwise
  SUB R10, 5
  CALL hexa_to_decimal

  ;save new energy
  MOV [CURRENT_ENERGY], R10

  ;set new energy on display
  MOV R2, SET_ENERGY
  MOV [R2], R8

  return_energy_decrease:
    POP R10
    POP R8
    POP R7
    POP R2
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
  PUSH R10
  
  MOV R1, 1000
  MOV R2, 10

  MOV R8, 0

  hexa_to_decimal_loop_start:
    MOD R10, R1 ; número = número MOD fator; número é o valor a converter
    DIV R1, R2 ; fator = fator DIV 10; fator de divisão (começar em 1000 decimal)

    CMP R1, 0 ; se fator for 0, termina o loop
    JZ return_hexa_to_decimal

    MOV R3, R10 ; dígito = número DIV fator; mais um dígito do valor decimal
    DIV R3, R1

    SHL R8, 4  ; resultado = resultado SHL 4; desloca, para dar espaço ao novo dígito
    OR R8, R3  ; resultado = resultado OR dígito; vai compondo o resultado

    JMP hexa_to_decimal_loop_start

  return_hexa_to_decimal:
    POP R10
    POP R3
    POP R2
    POP R1
    RET

; **********************************************************************
; GEN_NUMBER:
;  - function to generate a random number
;  - it generates a random number between 0 and 7
; **********************************************************************
gen_number:
  ;receives a range on R10 (0-R10)
  ;generate a random number between 0 and 7
  MOV R1, [PIN_INPUT]
  MOD R1, R10
  RET

player_idle:
  PUSH R3
  PUSH R6
  PUSH R8

  ;set entity as player
  MOV R3, PLAYER

  ;change entity state to 0 (idle)
  MOV R6, 0
  MOV [R3+4], R6

  ;set action as write
  MOV R8, 1  

  CALL render_entity

  POP R8
  POP R6
  POP R3
  RET

render_entity:
  PUSH R1
  PUSH R2
  PUSH R3
  PUSH R5
  PUSH R6
  PUSH R7
  PUSH R9

  ;get entity position
  MOV R1, [R3] ;x
  MOV R2, [R3+2] ;y

  ;get entity state (sprite index)
  MOV R6, [R3+4]

  ;get entity sprites
  MOV R3, [R3+6]

  ;get sprite to render
  get_sprite:
    ;get sprite size
    MOV R4, [R3] ;length
    MOV R5, [R3+2] ;height

    ADD R3, 4 ;skip size (lenght and height)

    ;check if we are already are in the correct sprite
    CMP R6, 0
    JZ render

    ;calc bytes to skip
    MOV R7, R4 ;save R4 value
    MUL R7, R5 ;calculate area of the sprite (bytes/2)
    MOV R9, 2 ;constant 2
    MUL R7, R9 ;R7 now have the number of bytes we need to skip

    ;skip pixel bytes
    ADD R3, R7 ;skip pixels
    
    ;subtract 1
    SUB R6, 1
    JMP get_sprite

  render:
    ;render
    CALL render_sprite

  POP R9
  POP R7
  POP R6
  POP R5
  POP R3
  POP R2
  POP R1
  RET

rot_energy:
  PUSH R0

  MOV R0, 1
  MOV [ENERGY_FLAG], R0 ;set flag as 1

  POP R0
  RFE

rot_agents:
  PUSH R0

  MOV R0, 1
  MOV [AGENTS_FLAG], R0 ;set flag as 1

  POP R0
  RFE

rot_projectile:
  PUSH R0

  MOV R0, 1
  MOV [PROJECTILE_FLAG], R0 ;set flag as 1

  POP R0
  RFE

energy_update:
  PUSH R0

  MOV R0, [ENERGY_FLAG] ;get energy flag

  ;if flag is off skip update
  CMP R0, 0
  JZ return_energy_update

  ;otherwise handle the update
  CALL energy_decrease
  MOV R0, 0
  MOV [ENERGY_FLAG], R0 ;set energy flag to 0

  return_energy_update:
    POP R0
    RET

agents_update:
  PUSH R0
  PUSH R1
  PUSH R2
  PUSH R3
  PUSH R4
  PUSH R10

  ;if flag is off skip update
  MOV R0, [AGENTS_FLAG] ;get agents flag
  CMP R0, 0
  JZ return_agents_update

  ;get number of agents
  MOV R0, [AGENTS]

  ;get agents
  MOV R3, AGENTS
  ADD R3, 2

  update_loop:
    ;check if we ended the loop
    CMP R0, 0
    JZ end_update_loop

    ;update agent   
    ;check if agent is dead
    MOV R2, [R3+4] ;get agent stage
    CMP R2, -1
    JNZ update_agent

    ;otherwise generate stats for the new agent

    ;set y position as -1 becuase it's going to be incremented ahead
    MOV R10, -1
    MOV [R3+2], R10

    ;set stage as 0
    MOV R10, 0
    MOV [R3+4], R10

    ;generate random column
    MOV R10, 58 ;range of the random number to be generated (column)
    CALL gen_number ;returns random number on R1

    ;set agent column
    MOV [R3], R1 ;set the column as the randomly generated number

    ;generate probability of being hostile or friendly
    MOV R10, 100 ;range of the random number to be generated
    CALL gen_number ;returns random number on R1
  
    ;check if random number is less than 25 (25% chance)
    MOV R2, 25
    CMP R1, R2
    JLT gen_friendly

    ;otherwise generate hostile
    MOV R2, ENEMY_SPRITES
    MOV [R3+6], R2
    JMP update_agent

    gen_friendly:
    MOV R2, FRIEND_SPRITES
    MOV [R3+6], R2

    update_agent:
      ;delete old agent
      MOV R8, 0
      CALL render_entity
      
      ;update y of the agent
      ;add 1 to the y axis
      MOV R1, [R3+2]
      ADD R1, 1

      ;save new y position value
      MOV [R3+2], R1

      ;update stage
      MOV R2, 3
      DIV R1, R2 ;divide y position by 3

      ;check if calculated stage is greater than 3
      MOV R2, R1 ;backup of the stage
      SUB R2, 3
      JLE update_stage

      ;otherwise rewrite stage
      MOV R1, 4

    update_stage:
      ;save new stage value
      MOV [R3+4], R1

    ;render new updated agent
    MOV R8, 1 ;set action as write
    CALL render_entity

    ;check if touching bottom
    MOV R1, [R3+2] ;get updated y position
    MOV R2, [R3+4] ;get updated stage

    ;get agent bottom edge position
    ADD R1, R2 
    ADD R1, 1 ;stage+1 is the sprite height

    ;get max possible y position
    MOV R2, MAX_SCREEN_HEIGHT
    SUB R2, 1

    CMP R1, R2
    JNZ thank_you_next

    ;delete agent
    MOV R8, 0
    CALL render_entity

    ;otherwise set state as "deleted"
    MOV R2, -1
    MOV [R3+4], R2

    thank_you_next:
      ;go to next agent
      MOV R1, 8
      ADD R3, R1

      SUB R0, 1 ;decrease loop iterator
      JMP update_loop

  end_update_loop:
    ;reset flag
    MOV R1, 0
    MOV [AGENTS_FLAG], R0 ;set energy flag to 0

  return_agents_update:
    POP R10
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    RET

projectile_update:
  PUSH R0
  PUSH R1
  PUSH R2
  PUSH R3
  PUSH R4
  PUSH R5
  PUSH R6
  PUSH R7
  PUSH R8

  ;if flag is off skip update
  MOV R0, [PROJECTILE_FLAG] ;get projectile flag
  CMP R0, 0
  JZ return_projectile_update

  MOV R3, PROJECTILE

  ;if projectile stage is -1 projectile doesnt exist
  MOV R0, [R3+4] ;get projectile stage
  CMP R0, -1
  JZ return_projectile_update
  
  ;delete old projectile sprite
  MOV R8, 0 ;set action as delete
  CALL render_entity

  MOV R4, [R3] ;get projectile x
  MOV R5, [R3+2] ;get current projectile y
  SUB R5, 1 ;change y position to make projectile go up

  ;check for colision
  MOV R0, [AGENTS];get number of agents 

  ;get agents
  MOV R7, AGENTS
  ADD R7, 2

  check_colisions_loop:
    CMP R0, 0 ;check if we ended the loop
    JZ no_colisions

    MOV R1, R7 ;get current agent

    ;get current agent bottom edge
    MOV R2, [R1+2] ;get current agent y position

    ;add the current sprite height (=stage+1)
    MOV R6, [R1+4]
    ADD R2, R6
    ADD R2, 1

    ;check if current agent is at the same line as projectile
    CMP R2, R5
    JLT go_next_colision_check

    ;check if projectile is on the right of the left edge of the agent
    MOV R2, [R1] ;get current agent x position
    CMP R4, R2
    JLT go_next_colision_check

    ;check if projectile is on the left of the right edge of the agent
    ;making it between the 2 edges
    ;add the current sprite width (=stage+1)
    MOV R6, [R1+4] ;get current agent stage
    ADD R6, 1
    ADD R2, R6 ;R2 now have the right edge position
    
    CMP R2, R4
    JLT go_next_colision_check
    
    ;otherwise delete agent
    MOV R8, 0 ;set action as delete
    MOV R3, R1 ;set entity to delete as the current agent
    CALL render_entity

    ;set stage to -1 to be regenerated at next agents update
    MOV R6, -1
    MOV [R1+4], R6

    ;check if it's a bad agent in that case increase energy by 5
    MOV R8, ENEMY_SPRITES
    MOV R6, [R1+6]
    CMP R6, R8
    JNZ delete_projectile

    ;otherwise increase
    CALL energy_increase
    JMP delete_projectile

    go_next_colision_check:
      ;set pointer to the next agent
      MOV R6, 8
      ADD R7, R6

      ;subtract 1 from the iterator
      SUB R0, 1
      JMP check_colisions_loop

  no_colisions:
    ;check if value is 14
    MOV R0, 14 ;14 instead of 12 because our player is 2 pixels higher 

    ;if we are not on the max height yet render
    CMP R0, R5
    JZ delete_projectile

    ;otherwise
    ;render updated projectile
    ;update y position value
    MOV [R3+2], R5
    MOV R8, 1
    CALL render_entity
    JMP reset_projectile_flag

  ;render new projectile position
  delete_projectile:
    MOV R3, PROJECTILE
    MOV R0, -1
    MOV [R3+4], R0 ;set stage as -1

  reset_projectile_flag:
    ;reset flag
    MOV R0, 0
    MOV [PROJECTILE_FLAG], R0
  

  return_projectile_update:
    POP R8
    POP R7
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    RET
