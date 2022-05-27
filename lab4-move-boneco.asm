; *********************************************************************************
; * IST-UL
; * Modulo:    lab4-move-boneco.asm
; * Descrição: Este programa ilustra o movimento de um boneco do ecrã, usando um atraso
; *			para limitar a velocidade de movimentação.
; *********************************************************************************

; *********************************************************************************
; * Constantes
; *********************************************************************************
DEFINE_LINHA    		EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA   		EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL    		EQU 6012H      ; endereço do comando para escrever um pixel
APAGA_AVISO     		EQU 6040H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ	 		EQU 6002H      ; endereço do comando para apagar todos os pixels já desenhados
SELECIONA_CENARIO_FUNDO  EQU 6042H      ; endereço do comando para selecionar uma imagem de fundo

LINHA        		EQU  31        ; linha do boneco (a meio do ecrã))
COLUNA			EQU 15        ; coluna do boneco (a meio do ecrã)

MIN_COLUNA		EQU  0		; número da coluna mais à esquerda que o objeto pode ocupar
MAX_COLUNA		EQU  63        ; número da coluna mais à direita que o objeto pode ocupar
ATRASO			EQU	450H		; atraso para limitar a velocidade de movimento do boneco

LARGURA		EQU	5			; largura do boneco
VERMELHO		EQU	0FF00H		; cor do pixel: vermelho em ARGB (opaco e vermelho no máximo, verde e azul a 0)
LARANJA			EQU	0FF95H		; cor do pixel: laranja em ARGB (opaco e vermelho no máximo, verde e azul a 0)
AZULJANELA		EQU	0FCCFH		; cor do pixel: azul em ARGB (opaco e vermelho no máximo, verde e azul a 0)
CINZENTO		EQU	0FDDFH		; cor do pixel: cinzento em ARGB (opaco e vermelho no máximo, verde e azul a 0)

; #######################################################################
; * ZONA DE DADOS 
; #######################################################################
PLACE		0100H				

DEF_BONECO:					; tabela que define o boneco (cor, largura, pixels)
	WORD		LARGURA
	WORD		0, 0, CINZENTO, 0, 0		; # # #   as cores podem ser diferentes
DEF_BONECO:					; tabela que define o boneco (cor, largura, pixels)
	WORD		LARGURA
	WORD		LARANJA, CINZENTO, 0, CINZENTO, AZUL		; # # #   as cores podem ser diferentes
DEF_BONECO:					; tabela que define o boneco (cor, largura, pixels)
	WORD		LARGURA
	WORD		AZUL, CINZENTO, CINZENTO, CINZENTO, AZUL		; # # #   as cores podem ser diferentes
DEF_BONECO:					; tabela que define o boneco (cor, largura, pixels)
	WORD		LARGURA
	WORD		LARANJA, 0, 0, 0, LARANJA		; # # #   as cores podem ser diferentes
     

; *********************************************************************************
; * Código
; *********************************************************************************
PLACE   0                     ; o código tem de começar em 0000H
inicio:
     MOV  [APAGA_AVISO], R1	; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
     MOV  [APAGA_ECRÃ], R1	; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	R1, 0			; cenário de fundo número 0
     MOV  [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo
	MOV	R7, 1			; valor a somar à coluna do boneco, para o movimentar
     
posição_boneco:
     MOV  R1, LINHA			; linha do boneco
     MOV  R2, COLUNA		; coluna do boneco

desenha_boneco:       		; desenha o boneco a partir da tabela
	MOV	R6, R2			; cópia da coluna do boneco
	MOV	R4, DEF_BONECO		; endereço da tabela que define o boneco
	MOV	R5, [R4]			; obtém a largura do boneco
	ADD	R4, 2			; endereço da cor do 1º pixel (2 porque a largura é uma word)
desenha_pixels:       		; desenha os pixels do boneco a partir da tabela
	MOV	R3, [R4]			; obtém a cor do próximo pixel do boneco
	MOV  [DEFINE_LINHA], R1	; seleciona a linha
	MOV  [DEFINE_COLUNA], R6	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R3	; altera a cor do pixel na linha e coluna selecionadas
	ADD	R4, 2			; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
     ADD  R6, 1               ; próxima coluna
     SUB  R5, 1			; menos uma coluna para tratar
     JNZ  desenha_pixels      ; continua até percorrer toda a largura do objeto

	MOV	R11, ATRASO		; atraso para limitar a velocidade de movimento do boneco		
ciclo_atraso:
	SUB	R11, 1
	JNZ	ciclo_atraso
	
apaga_boneco:       		; desenha o boneco a partir da tabela
	MOV	R6, R2			; cópia da coluna do boneco
	MOV	R4, DEF_BONECO		; endereço da tabela que define o boneco
	MOV	R5, [R4]			; obtém a largura do boneco
apaga_pixels:       		; desenha os pixels do boneco a partir da tabela
	MOV	R3, 0			; para apagar, a cor do pixel é sempre 0
	MOV  [DEFINE_LINHA], R1	; seleciona a linha
	MOV  [DEFINE_COLUNA], R6	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R3	; altera a cor do pixel na linha e coluna selecionadas
     ADD  R6, 1               ; próxima coluna
     SUB  R5, 1			; menos uma coluna para tratar
     JNZ  apaga_pixels		; continua até percorrer toda a largura do objeto

testa_limite_esquerdo:		; vê se o boneco chegou ao limite esquerdo
	MOV	R5, MIN_COLUNA
	CMP	R2, R5
	JLE	inverte_para_direita
testa_limite_direito:		; vê se o boneco chegou ao limite direito
	MOV	R6, [DEF_BONECO]	; obtém a largura do boneco (primeira WORD da tabela)
	ADD	R6, R2			; posição a seguir ao extremo direito do boneco
	MOV	R5, MAX_COLUNA
	CMP	R6, R5
	JGT	inverte_para_esquerda
	JMP	coluna_seguinte	; entre limites. Mnatém o valor do R7

inverte_para_direita:
	MOV	R7, 1			; passa a deslocar-se para a direita
	JMP	coluna_seguinte
inverte_para_esquerda:
	MOV	R7, -1			; passa a deslocar-se para a esquerda
	
coluna_seguinte:
	ADD	R2, R7			; para desenhar objeto na coluna seguinte (direita ou esquerda)

	JMP	desenha_boneco		; vai desenhar o boneco de novo
