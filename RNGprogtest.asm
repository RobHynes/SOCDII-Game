; Program demonstrating the use of the SCC random number generator register SFR7
; Fearghal Morgan
main:
  ADDI R0, R0, 7   ; R0=0xF to mask digit 0
  SETBR R0, 3      ; R0 is now 000F
rdRNGRegAndExtractDigit0:
  MOVSFRR R1, SFR7 ; read random number register (SFR7)
  AND R2, R1, R0   ; R2(3:0) is random number, value 0-15, mask out and put this value in R2
  JZ R3, rdRNGRegAndExtractDigit0  ; unconditional branch (R3 always 0, so it always loops)
  END