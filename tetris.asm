; Single Cycle Computer (SCC) 
; Rotate4BitPaddleLeftEachSecond_UsingProgramCounterDelay
; Assert 3-bit paddle in memory, rotate left every second
; Use decrementing loop counter(s) for 1 second delay
; Not using timer interrup for 1 second delay
;
; Created by Robert Hynes and Caireann Kennedy, National University of Ireland, Galway
; Creation date: Jan 2020
; viciLogic Single Cycle Computer: https://www.vicilogic.com/static/ext/SCC/
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

; store number of interrupts count in mem[64], i.e, address 01000000b
updateInterruptCount:
PUSH R0				  ; using R2 and R0 internally, so PUSH stack and POP before RET`
PUSH R2
 INVBSFR SFR5, 0	  ; toggle LED(0) on each interrupt
 SETBR R0, 6          ; 64d (data memory address)
 MOVAMEMR R2, @R0     ; read value from data memory 
 INC R2, R2
 MOVBAMEM @R0, R2     ; store value on data memory(128)
 MOVRSFR SFR4, R2	  ; Update 7-segment display 
POP R2
POP R0
RET

clearNumIntCount: 	 
 XOR R2, R2, R2          ; clear reg
 SETBR R0, 6 		     ; use R(0) as mem address = 64d  
 MOVBAMEM @R0, R2        ; clear mem[R0] 
RET

; configure (but don't start) 1 second reloadable, down timer, and timer interrupt control  
Cfg_DownTimer_T80ns_Interrupt:  
 CALL SetupTimer1Sec	 ; setup values for 1 second timer interrupt (assuming 80ns, 12.5MHz clk period)
 MOVRSFR SFR9, R7	     ; setup TMRH
 MOVRSFR SFR2, R7	     ; setup TMRH_LDVAL
 MOVRSFR SFR8, R6	     ; setup TMRL
 MOVRSFR SFR1, R6	     ; setup TMRL_LDVAL
 ; Update SFR0 control signals for timer and interrupts
 SETBSFR SFR0, 6         ; setup down timer
 SETBSFR SFR0, 5         ; setup timer auto reload`
 SETBSFR SFR0, 3         ; enable timer interrupt
 SETBSFR SFR0, 0         ; enable global interrupts  
RET

SetupTimer1Sec:       ; 0x00BEBC1F = 12,499,999 (counting 12.5M x 12.5MHz clk periods)
 MOVDPTR BEh          ; High word 32-bit timer values = BEh, 1011 1110      
 MOVSFRR R7, SFR15 
 MOVDPTR C1Fh         ; Low word 32-bit timer values = BC1Fh  1011110000011111
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
 XOR R0,R0,R0 ; clear R0 and R4
 XOR R4,R4,R4
 MOVIN R4 ; read in inout from inport (SFR12)
 SETBR R0, 2 ; set bit 2 of R0 to 1 to check right
 AND R0, R0, R4 ; if R0 is not 0, then right
 JNZ R0, right ; jump to rotatePaddleRight call
 CLRBR R0, 2 ; clear R0 again
 SETBR R0, 3 ; set bit 3 of R0 to 1 to check left
 AND R0, R0, R4 ; if R0 is not 0, then left
 JNZ R0, left ; jump to rotatePaddleRight call
 right:
  CALL rotatePaddleRight
  JNZ R0, skip ; check R0 to skip rotatePaddleLeft call if returning from rotatePaddleRight call
 left:
  CALL rotatePaddleLeft
 skip:
 POP R0
 POP R4
RET

movePaddleDown:
MOVSFRR R5, SFR7 ; to make paddle stop moving when it reaches memory 12 by comparing mem location value in R3 with 000Cxh (12xd)
SETBR R5, 2
SETBR R5, 3
XOR R5, R5, R3
JZ R5, stop
MOVSFRR R5, SFR7 ;clear r5 again

MOVAMEMR R4, @R3 ; save current paddle shape 
MOVRSFR SFR6, R3 ; save past position
DEC R3, R3       ; dec R3 so move down in position
MOVAMEMR R5, @R3 ; get what is in new position
MOVSFRR R1, SFR11 
XOR R4, R1, R4
AND R1, R4, R5   ; check if there will be a collision with what is in new position
JNZ R1, stop     ; if will be collision stop

MOVSFRR R3, SFR6 ; get back past position
MOVSFRR R1, SFR11
MOVBAMEM @R3, R1 ; clear past paddle position
DEC R3, R3
OR R4, R5, R4    ; if no collison add old paddle and new paddle
MOVRSFR SFR11, R5 
MOVBAMEM @R3, R4 ; save joined paddle to new position

JNZ R3, jump     ; skip if new shape if not at stopping position
stop:
 XOR R1, R1, R1
 CALL initialisePaddleInMemAddr10  ; create new shape if at stopping position
jump:
RET

initialisePaddleInMemAddr10: ; initialise paddle value = 0b0000001111000000 in data mem(31)
MOVRSFR  SFR11, R1
MOVDPTR  3C0h         ; assert bits (9:6)
MOVSFRR  R2, SFR15 
MOVDPTR  1fh          ; mem address
MOVSFRR  R3, SFR15   
MOVBAMEM @R3, R2      ; write paddle value in data mem
RET

rotatePaddleLeft:
 PUSH R1
 XOR R1, R1, R1 ; clear R1
 SETBR R1, 15   ; set MSB of R1 to 1 to set a mask (1000h)
 MOVAMEMR R6, @R3    ; read paddle row memory -> R6
 AND R1, R1, R6      ; check if paddle is at the left side using R1 mask
 JNZ R1, dontMoveLeft ; skip move left commands if result is not zero
 ROTL     R6, 1		  ; rotate left 1 bit
 MOVBAMEM @R3, R6     ; write updated paddle pattern R6 to paddle row memory  
 dontMoveLeft:
 POP R1
RET

rotatePaddleRight:  
 PUSH R1
 XOR R1, R1, R1 ; clear R1
 SETBR R1, 0   ; set LSB of R1 to 1 to set a mask (0001h)
 MOVAMEMR R6, @R3    ; read paddle row memory -> R6
 AND R1, R1, R6      ; check if paddle is at the left side using R1 mask
 JNZ R1, dontMoveRight ; skip move right commands if result is not zero
 ROTR     R6, 1		  ; rotate right 1 bit
 MOVBAMEM @R3, R6     ; write updated paddle pattern R6 to paddle row memory  
 dontMoveRight:
 POP R1
RET