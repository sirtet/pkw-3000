; A Hellorld! Program for the AVAL PKW-3000 EP-ROM Programmer.
; Usage:
; In Terminal Mode, use the Rn Command (Read from Tape to addr. n) to load it to 6080H
; To execute, bend a return address on the stack:
; Use Rn again to load our start Addr. 6080 to the stack addr. 603E
; Upon finishing the Rn command, the CPU jumps to our Code.
; Explanation:
; PKW-3000 does not support running code other than the System ROM.
; But the Rn command, meant to load data to Buffer RAM, can also write to Symtem RAM.
; This seems to be an unintended Effect of the Fact that Rn uses physical adressing.
; 603E/3F is the beginning of the Stack. In Terminal Mode, while a command runs,
; it contains the address of the routine that prints the command prompt.
; Doing this is the last part of every Terminal Command.
; So by overwriting this, we can jump to our code.


; Display Ports are already configured by the System, thanks @AVAL Corp. ;-)
PDIGIT:   EQU    6AH       ; Port to select Digit
PCHAR:    EQU    69H       ; Port to send Char (7-Segment Data)
DIGIT0:   EQU    88H       ; Digit 0 (leftmost)

; LED-Segment definitions for uper- and lowercase Characters
; which casing looks best? I opt for HELL Orld... change to lowercase at "the error"
uH:    EQU    76H
uE:    EQU    79H
uL:    EQU    38H
uO:    EQU    3FH
lR:    EQU    50H
lL:    EQU    30H
lD:    EQU    5EH

ORG       6080H              ; The lowest address where we don't interfere with running code
                             ; while using the "Rn" Tape Read Command, 128 Bytes are usable.
          DI                 ; disable interrupts, or the original code will interfere
start:    LXI    H,STRING    ; Load address of the string
          MVI    C,0         ; Start Digit- counter at 0

LOOP:     MOV    A,C         ; Load the current digit position
          ADI    DIGIT0      ; Calculate digit select value
          OUT    PDIGIT      ; Output digit selection
          MOV    A,M         ; Load the character to display
          OUT    PCHAR       ; Output character to 7-segment
          CALL   DELAY       ; leave time for the digit-selection to settle
          INX    H           ; Increment pointer to next character
          INR    C           ; Increment character count
          MOV    A,C         ; Move counter to accumulator for comparison
          CPI    8           ; Compare character count to 8
          JNZ    LOOP        ; If not all characters are displayed, continue
          JMP    START       ; Otherwise, restart display process

DELAY:    MVI    B,0FFH      ; Load register B with 255
DLY:      DCR    B           ; Decrement register B
          JNZ    DLY         ; If B is not zero, jump back to DLY
          RET

STRING:   DB     uH,uE,uL,uL,uO,lR,lL,lD ; String in forward order