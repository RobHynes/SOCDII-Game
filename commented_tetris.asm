3; Single Cycle Computer (SCC) 
; tetris videogame
; Uses timer interrup for 1 second delay
;
; Created by Robert Hynes and Caireann Kennedy, National University of Ireland, Galway
; Creation date: Mar 2020
;
; ASSEMBLY INSTRUCTION    ; DECRIPTION 
main:                     ; main program label
CALL clearNumIntCount	 
CALL initialisePaddleInMemAddr10
CALL Cfg_DownTimer_T80ns_Interrupt
SETBSFR SFR0, 4 
END

ORG 116                  ; Places timer interrupt service routine ISR2 program extract start address (116 decimal). 
                         ; Can also use ORG 74h (hex)
CALL updateInterruptCount
CALL movePaddleDown
CALL checkDirection
RETI  

; toggle LED(0) on each interrupt
updateInterruptCount:
 INVBSFR SFR5, 0	   
RET

; clear mem[64d] 
clearNumIntCount: 	 
 XOR R2, R2, R2          
 SETBR R0, 6 		     
 MOVBAMEM @R0, R2        
RET

; configure (but don't start) 1 second reloadable, down timer, and timer interrupt control  
Cfg_DownTimer_T80ns_Interrupt:  
 CALL SetupTimer1Sec
 MOVRSFR SFR9, R7	
 MOVRSFR SFR2, R7	
 MOVRSFR SFR8, R6	
 MOVRSFR SFR1, R6	
 
 SETBSFR SFR0, 6    
 SETBSFR SFR0, 5    
 SETBSFR SFR0, 3    
 SETBSFR SFR0, 0    
RET

SetupTimer1Sec:       
 MOVDPTR BEh          
 MOVSFRR R7, SFR15 
 MOVDPTR C1Fh         
 MOVSFRR R6, SFR15 
 SETBR R6, 15
 SETBR R6, 13
 SETBR R6, 12
RET     

; Checks if the right or left switch is on. Push R4 and R0 onto stack. Clear R0 and R4. 
; Put input from InPort into R4 and then check if bit 2/3 are set by ANDing with R0. 
; If bit 2 is set, call rotatePaddleRight and if bit 3 is set, call rotatePaddleLeft
checkDirection:
 PUSH R4
 PUSH R0
 XOR R0,R0,R0
 XOR R4,R4,R4
 MOVIN R4
 SETBR R0, 2
 AND R0, R0, R4
 JNZ R0, right
 CLRBR R0, 2
 SETBR R0, 3
 AND R0, R0, R4
 JNZ R0, left
 right:
  CALL rotatePaddleRight
  JNZ R0, skip
 left:
  CALL rotatePaddleLeft
 skip:
 POP R0
 POP R4
RET

; move the game piece move down the screen one row at a time every second
; stop paddle moving down when it reaches memory location 12 by comparing 
; current memory location value in R3 with 000Cxh (12xd)
; after moving into a new memory row, check if there is something in the 
; space below the paddle (the bits of the next row of memory that the 
; paddle is about to move into)
; if there is something below it, the paddle stops in the current memory 
; row instead of going to the next row and initialisePaddleInMemAddr10 
; is called to create a new piece at the top of the screen
; also if the paddle stops call checkIfLineIsFilled, as this will need 
; to be deleted and the score increased
; also if the paddle stops call checkIfAtTop as this will be end game
movePaddleDown:
XOR R5, R5, R5
SETBR R5, 2
SETBR R5, 3     ; set R5 to value Ch to use as a mask so it will stop at the bottom
XOR R5, R5, R3
JZ R5, stop
XOR R5, R5, R5

MOVAMEMR R4, @R3 ; save current row shape and position
MOVRSFR SFR6, R3 
DEC R3, R3       ; move row down and save new psoition
MOVAMEMR R5, @R3 
MOVSFRR R1, SFR11 
XOR R4, R1, R4
AND R1, R4, R5   ; check if there will be a collision and stop if there is
JNZ R1, stop     

MOVSFRR R3, SFR6 
MOVSFRR R1, SFR11
MOVBAMEM @R3, R1 
DEC R3, R3
OR R4, R5, R4    ; if no collision clear past row and add old & new rows
MOVRSFR SFR11, R5 
MOVBAMEM @R3, R4 

JNZ R3, jump     
stop:            ; Once the row stops check if any lines are full, if any reached the top and then create a new row if not at top
 XOR R1, R1, R1
 CALL checkIfLineIsFilled
 CALL checkIfAtTop
 CALL initialisePaddleInMemAddr10  
jump:
RET

; initialise a random sized paddle in data mem(31). Paddle can be 1 to 7 bits long
; paddle size is determined using the first 3 bits of the random number generated in SFR7 
initialisePaddleInMemAddr10:
PUSH R5
PUSH R6
MOVRSFR  SFR11, R1    ; SFR11 held past positions but now is new row so can clear
MOVSFRR R1, SFR7      ; get random number and mask out the last three bits
ADDI R5, R5, 7         
AND R1, R5, R1

XOR R5, R5, R5         ; check the value of the last three bits from 0-7 and set row length based on value
XOR R6, R5, R1
JZ R6, setPaddle1

INC R5, R5             
XOR R6, R5, R1
JZ R6, setPaddle1

INC R5, R5             
XOR R6, R5, R1
JZ R6, setPaddle2

INC R5, R5             
XOR R6, R5, R1
JZ R6, setPaddle3

INC R5, R5             
XOR R6, R5, R1
JZ R6, setPaddle4

INC R5 ,R5             
XOR R6, R5, R1
JZ R6, setPaddle5

INC R5, R5             
XOR R6, R5, R1
JZ R6, setPaddle6

INC R5, R5             
XOR R6, R5, R1
JZ R6, setPaddle7

setPaddle1:
 MOVDPTR 001h
 MOVSFRR  R2, SFR15 
 JZ R6, assignPaddleValue
setPaddle2:
 MOVDPTR 003h
 MOVSFRR  R2, SFR15 
 JZ R6, assignPaddleValue
setPaddle3:
 MOVDPTR 007h
 MOVSFRR  R2, SFR15 
 JZ R6, assignPaddleValue
setPaddle4:
 MOVDPTR 00Fh
 MOVSFRR  R2, SFR15 
 JZ R6, assignPaddleValue
setPaddle5:
 MOVDPTR 001Fh
 MOVSFRR  R2, SFR15 
 JZ R6, assignPaddleValue
setPaddle6:
 MOVDPTR 03Fh
 MOVSFRR  R2, SFR15 
 JZ R6, assignPaddleValue
setPaddle7:
 MOVDPTR 07Fh
 MOVSFRR  R2, SFR15 
 JZ R6, assignPaddleValue
assignPaddleValue:         ; once length is set assign the row to Mem[31]
MOVDPTR  1fh          
MOVSFRR  R3, SFR15   
MOVBAMEM @R3, R2      
XOR R1, R1, R1
POP R6
POP R5
RET

; check if any memory row is filled (FFFFxh)
; if a row is full, it is cleared again and the contents of the rows above it are shifted down one row
; the score is incremented by one and displayed on the 7-segment display
checkIfLineIsFilled:
SETBR R1, 2  
SETBR R1, 3
PUSH R5
PUSH R2
PUSH R6
XOR R2, R2, R2 
INV R2, R2            ; set R2 as mask for a full row
checkMem:             ; check if current mem location is full
 MOVSFRR  R6, SFR15   
 MOVAMEMR R5, @R1 
 XOR R5, R2, R5   
 MOVRSFR SFR10, R1 
 XOR R6, R1, R6       ; check if at the top before checking if next mem location is full
 JZ R6, fin
 INC R1, R1
 JNZ R5, checkMem     ; if not at top increase current mem location and check again if full
moveMemDown:          ; if a row is full move mem locations above that line down one position
 MOVSFRR R5, SFR10 
 MOVAMEMR R6, @R1 
 MOVBAMEM @R5, R6 
 MOVRSFR SFR10, R1 
 MOVSFRR  R6, SFR15
 INC R1, R1
 XOR R6, R1, R6 
 JNZ R6, moveMemDown
MOVSFRR R5, SFR4
INC R5, R5
MOVRSFR SFR4, R5     ; increase the score
fin:
POP R6
POP R2
POP R5
XOR R1, R1, R1
MOVRSFR SFR10, R1
RET

; check if the current game piece has stopped at the top of the game area, which means that the player has lost the game
; if the game is over, clear the game area and print END to the LEDs of the game area and end the program
checkIfAtTop:
PUSH R6
PUSH R5
PUSH R2
XOR R6, R6, R6
MOVSFRR  R6, SFR15 
MOVAMEMR R5, @R6
JZ R5, notAtTop

XOR R5, R5, R5    ; if at top clear top row and move down in mem locations and set LEDs to print END
MOVBAMEM @R6, R5

DEC R6, R6
MOVDPTR A2Ch
MOVSFRR  R5, SFR15 
SETBR R5, 12
SETBR R5, 13
SETBR R5, 14
MOVBAMEM @R6, R5

DEC R6, R6
MOVDPTR 32Ah
MOVSFRR  R5, SFR15 
SETBR R5, 14
MOVBAMEM @R6, R5

DEC R6, R6
MOVDPTR 2AAh
MOVSFRR  R5, SFR15 
SETBR R5, 13
SETBR R5, 14
MOVBAMEM @R6, R5

DEC R6, R6
MOVDPTR 26Ah
MOVSFRR  R5, SFR15 
SETBR R5, 14
MOVBAMEM @R6, R5

DEC R6, R6
MOVDPTR A2Ch
MOVSFRR  R5, SFR15 
SETBR R5, 12
SETBR R5, 13
SETBR R5, 14
MOVBAMEM @R6, R5

clearRestOfMem:
 DEC R6, R6
 XOR R5, R5, R5
 MOVBAMEM @R6, R5
 XOR R2, R2, R2
 SETBR R2, 2
 SETBR R2, 3
 XOR R5, R2, R6
JNZ R5, clearRestOfMem
END
notAtTop:
POP R2
POP R5
POP R6
RET

; if the left button is clicked, move the paddle left in the game area
; if the paddle has reached the left side of the screen, do not move any further left
rotatePaddleLeft:
 PUSH R1
 XOR R1, R1, R1 
 SETBR R1, 15   
 MOVAMEMR R6, @R3    
 AND R1, R1, R6      
 JNZ R1, dontMoveLeft 
 ROTL     R6, 1		  
 MOVBAMEM @R3, R6     
 dontMoveLeft:
 POP R1
RET

; if the right button is clicked, move the paddle right in the game area
; if the paddle has reached the right side of the screen, do not move any further right
rotatePaddleRight:  
 PUSH R1
 XOR R1, R1, R1 
 SETBR R1, 0   
 MOVAMEMR R6, @R3    
 AND R1, R1, R6      
 JNZ R1, dontMoveRight
 ROTR     R6, 1		  
 MOVBAMEM @R3, R6     
 dontMoveRight:
 POP R1
RET
