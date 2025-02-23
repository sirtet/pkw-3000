; This is based on the original disassembly by Edgar
; http://matthieu.benoit.free.fr/aval/PKW.ASM
; It has minor Syntax changes, needed to be used in Dirk's Simulator
; https://github.com/ForNextSoftwareDevelopment/8085

; Mainly  more comments to better understand the structure.
; TODO: Better aliases... (started some)
; set tabstop=4 for correct alignment

;-----------------------------------------------------------------------------
;Original Disassembly:
;DIS8080 V1.02 29.10.1983
;Disassembler Invoked by : PKW-3000.bin -O0 -MOD85 
;Reading from PKW-3000.BIN (2000H Bytes), writeing to PKW-3000.ASM
;-----------------------------------------------------------------------------
;RST-FUNCTIONS
;-----------------------------------------------------------------------------
FUN0:    EQU        0            ;RESET, NOT USED
RSTPUT:  EQU        1            ;PUT BYTE
RSTGET:  EQU        2            ;GET BYTE
FUN3:    EQU        3
FUN4:    EQU        4
FUN5:    EQU        5
RSTRX:   EQU        6            ;SERIAL IN
FUN7:    EQU        7
;------------------------------------------------------------------------------
;I/O PORTS
;------------------------------------------------------------------------------
;8155
;------------------------------------------------------------------------------
PIO6CMD:    EQU        068H        ;COMMAND/STATUS
PLEDSEG:    EQU        069H        ;PA         Display Output
PDKSELB:    EQU        06AH        ;PB         Disp.-Nr SELECT / Key-Col SELECT / Beeper
PKROWIN:    EQU        06BH        ;PC 0..5    Key-Rows INPUT
PTIMLOW:    EQU        06CH        ;TIMER LOW      set to 70H
PTIMHIG:    EQU        06DH        ;TIMER HIGH            D7H 
;*************************************************
;* PORT 68H (READ-WRITE) COMMAND/STATUS
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |-----|-----|-----|-----|-----|-----|-----|------- 8155 COMMAND/STATUS-REGISTER SEE DATASHEET
;   0     1     0     1     1     0     1     1        set at boot to 05BH
;   |     |     |     |     |     |     |     |
;   |     |     |     |     |     |     |     |------- Port A        : OUT (LEDSEG)
;   |     |     |     |     |     |     |------------- Port B        : OUT (Disp./Key-sel, beep, etc.)
;   |     |     |     |     A-----A------------------- Port C Mode   : ALT4
;   |     |     |     |------------------------------- PA interrupt  : enabled 
;   |     |     |------------------------------------- PB interrupt  : disabled
;   T-----T------------------------------------------- Timer Command : Continuous Square Wave
;   Timer is fed by CPU Clock, so it's a programmable divider to the 6MHz(?) 6Mhz/D770h = 108Hz = 9.25mS ?
;
;*************************************************
;* PORT 69H (READ-WRITE) 7 SEGMENT DATA
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |     |     |     |     |     |     |     |
;   |     |     |     |     |     |     |     |------- SEGMENT A DATA
;   |     |     |     |     |     |     |------------- SEGMENT B DATA
;   |     |     |     |     |     |------------------- SEGMENT C DATA
;   |     |     |     |     |------------------------- SEGMENT D DATA
;   |     |     |     |------------------------------- SEGMENT E DATA
;   |     |     |------------------------------------- SEGMENT F DATA
;   |     |------------------------------------------- SEGMENT G DATA
;   |------------------------------------------------- SEGMENT DP DATA
;   ---a---
;  |       |
;  f       b
;  |       |
;   ---g---
;  |       |
;  e       c
;  |       |
;   ---d---
;           dp (decimal point, normally bottom-right)
; PKW-3000 dp Position varies between digits. See Manual, LED-Test, p.3-25(pdf p.49)
;
;*************************************************
;* PORT 6AH (READ-WRITE) 
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |     |     |     |     |     |     |     |
;   |     |     |     |     |     S-----S-----S------- DISPLAY SELECT 0..7
;   |     |     |     |     |------------------------- DISPLAY SELECT CS_LOW
;   |     |     |     |------------------------------- DISPLAY SELECT CS_HIGH
;   |     |     |------------------------------------- BEEPER
;   |     |------------------------------------------- ENCS, ENABLE DRIVE_A AND DRIVE_B
;   |------------------------------------------------- HDIG, HIGH CURRENT ON DIG2
;*************************************************
;* PORT 6BH (READ) 
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |     |     |     |     |     |     |     |
;   |     |     |     |     R-----R-----R-----R------- KEYBOARD ROW LINE INPUT
;   |-----|-----|-----|------------------------------- UNUSED
;*************************************************
;* PORT 6CH (READ-WRITE) TIMER LOW
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |-----|-----|-----|-----|-----|-----|-----|------- 8155 TIMER LOW REGISTER
;*************************************************
;* PORT 6DH (READ-WRITE) TIMER HIGH
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |-----|-----|-----|-----|-----|-----|-----|------- 8155 TIMER HIGH REGISTER
;------------------------------------------------------------------------------
;DYNAMIC RAM
;------------------------------------------------------------------------------
P80RAM:    EQU        080H        ;
P81RAM:    EQU        081H
P82RAM:    EQU        082H
P83RAM:    EQU        083H
;*************************************************
;* PORT 80H (WRITE)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |     |     |     |     |     |     |     |
;   |     |     |     |     |     |     |     |------- DRAM DATA
;   |     |     |     |     |     |     |------------- DRAM WE    1=READ, 0=WRITE
;   |-----|-----|-----|-----|-----|------------------- X
;*************************************************
;* PORT 81H (WRITE)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |-----|-----|-----|-----|-----|-----|-----|------- DRAM ADDRESS REGISTER LSB
;
;*************************************************
;* PORT 82H (WRITE)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |-----|-----|-----|-----|-----|-----|-----|------- DRAM ADDRESS REGISTER MSB
;*************************************************
;* PORT 83H (READ)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |     |     |     |     |     |     |     |
;   |     |     |     |     |     |     |     |------- DRAM DATA, SINGLE BIT MUST BE EXPANDED
;   |-----|-----|-----|-----|-----|-----|------------- X
;------------------------------------------------------------------------------
;8255
;------------------------------------------------------------------------------
PEPRDAT:    EQU        0A0H
PEPRADR:    EQU        0A1H
PEPRAD2:    EQU        0A2H
PIOACMD:    EQU        0A3H
;*************************************************
;* PORT A0H (READ/WRITE)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |-----|-----|-----|-----|-----|-----|-----|------- EPROM DATA D0..D7
;*************************************************
;* PORT A1H (READ/WRITE)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |-----|-----|-----|-----|-----|-----|-----|------- EPROM ADDRESS A0..A7
;*************************************************
;* PORT A2H (READ/WRITE)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |     |     |     |-----|-----|-----|-----|------- EPROM ADDRESS A8..A12
;   |-----|-----|------------------------------------- ANALOG MUX SELECT
;*************************************************
;* PORT A3H (READ/WRITE)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |-----|-----|-----|-----|-----|-----|-----|------- 8255 COMMAND/STATUS REGISTER
;------------------------------------------------------------------------------
;8255
;------------------------------------------------------------------------------
SWSTAT:    EQU        0C0H
;corrected, from schematic:
;S1 In Down   Position A=1, B=1
;S1 In Middle Position A=0, B=1
;S1 In Upper  Position A=1, B=0

;S2 In Left   Position A=1, B=1
;S2 In Middle Position A=0, B=1
;S2 In Right  Position A=1, B=0


EPCTRL:    EQU        0C1H
RS232:     EQU        0C2H
IOCCMD:    EQU        0C3H
;*************************************************
;* PORT C0H (READ/WRITE)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |     |     |     |     |     |     |-----|------- LEVEL COMPARATOR SATTE
;   |     |     |     |     |-----|------------------- SWITCH S1 STATE ?? S1,2 swapped in Schematic p.2
;   |     |     |-----|------------------------------- SWITCH S2 STATE
;   |-----|------------------------------------------- UNUSED
;*************************************************
;* PORT C1H (READ/WRITE)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |     |     |     |     |     |     |     |------- SIGNAL DA DRIVE
;   |     |     |     |     |     |     |------------- SIGNAL DB DRIVE
;   |     |     |     |     |     |------------------- SIGNAL DA & DB ENABLE
;   |     |     |     |     |------------------------- EPROM DATA PULLUP CONTROL
;   |     |     |-----|------------------------------- VPP VOLTAGE CONTROL
;   |-----|------------------------------------------- VCC VOLTAGE CONTROL
;*************************************************
;* PORT C2H (READ/WRITE)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |     |     |     |     |     |     |     |------- RS232 RXD INPUT
;   |     |     |     |     |     |     |------------- RS232 CTS INPUT
;   |     |     |     |     |     |------------------- RS232 DSR INPUT
;   |     |     |     |     |------------------------- OPTION JUMPER
;   |     |     |     |------------------------------- RS232 DTR TTL OUT
;   |     |     |------------------------------------- RS232 RTS OUT
;   |     |------------------------------------------- RS232 DTR OUT
;   |------------------------------------------------- RS232 TXD OUT
;*************************************************
;* PORT C3H (READ/WRITE)
;*************************************************
;*  7  *  6  *  5  *  4  *  3  *  2  *  1  *  0  *
;*************************************************
;   |-----|-----|-----|-----|-----|-----|-----|------- 8255 COMMAND/STATUS REGISTER
;------------------------------------------------------------------------------
;DATA SEGMENT (256 BYTES OF RAM IN 8155)
;------------------------------------------------------------------------------
          ASEG
          ORG       6000H        ;
D6000:    DS        64           ;
STK       EQU       $            ;Stack from 603F down to 6000
D6040:    DS        1            ;
D6041:    DS        1            ;STRUCT
D6042:    DS        2            ;
D6044:    DS        2            ;
D6046:    DS        2            ;
D6048:    DS        8            ;
ROWDATA:  DS        8            ; 6050H ff... Keyrow0-7 Data (see KEYMAP:)read from Port 6B (PR0374:)
; all set to C0 in a Mem-Dump on the live system
D6058:    DS        1            ;
D6059:    DS        1            ;
D605A:    DS        1            ;
D605B:    DS        1            ;
D605C:    DS        2            ;
D605E:    DS        2            ;
D6060:    DS        1            ;W?
D6061:    DS        1            ;
; Xn - Parameters see Manual p.4-11(pdf p.63)
; -------------------------------------------
RAMSTA:   DS        2            ; X5 default 00 = RAM @ 8000H
TAPFMT:   DS        1            ; X6 default 04 = ASCII Hex Space
D6065:    DS        1            ; ? counts up during key reading?
SETSTA:   DS        1            ; X7 default 00 = see Manual 3-7-7 p.3-21(pdf p.45)
D6067:    DS        1            ; ?loaded in START2
STACOD:   DS        1            ; X8 default 02H = STX
D6069:    DS        1
STOCOD:   DS        1            ; X9 default 03H = ETX
D606B:    DS        1
D606C:    DS        1            ; Selected keyrow/leddigit (PR112A sets this), C8-CF for row 0-7
D606D:    DS        1            ; Port C3 setting, at Boot set to 92H
D606E:    DS        1            ; Port C1 setting, at Boot set to 00H
D606F:    DS        1
D6070:    DS        1
D6071:    DS        1
X6072:    DS        1
D6073:    DS        1
D6074:    DS        1
D6075:    DS        1            ; switchstate, read by PR0174
D6076:    DS        1            ; stored from PR0DD4: accessed from PR0F37:
D6077:    DS        2
D6079:    DS        2
D607B:    DS        2
D607D:    DS        2
          DS        1
D6080:    DS        128
;--------------------------------------------------------------------
; CODE SEGMENT
;--------------------------------------------------------------------
          ORG        0
START:    DI    
          LXI        SP,STK
          JMP        START1
          RST        7
;--------------------------------------------------------------------
; PUT
;--------------------------------------------------------------------
RST1V:    JMP        PR03CE            ;0008=
          RST        7
X000C:    JMP        PR020B            ;000C=
          RST        7
;--------------------------------------------------------------------
; GET
;--------------------------------------------------------------------
RST2V:    JMP        PR0403            ;0010=
          RST        7
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
          JMP        PR0A56            ;0014 =
          RST        7
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
RST3V:    JMP        PR0270            ;0018 = 
          RST        7
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
          JMP        PR0BD0            ;001C = 
          RST        7
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
RST4V:    JMP        RST4            ;0020 =
          RST        7
;--------------------------------------------------------------------
;TRAP INTERRUPT HANDLER
;--------------------------------------------------------------------
          JMP        RST4B            ;0024 =
          RST        7
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
RST5V:    JMP        RST5            ;0028 =
          RST        7
;--------------------------------------------------------------------
;RST 5.5 INTERRUPT
;--------------------------------------------------------------------
          JMP        RST55            ;002C =
          RST        7
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
RST6V:    JMP        RST6            ;0030 =
          RST        7
;--------------------------------------------------------------------
;RST 6.5 INTERRUPT HANDLER
;--------------------------------------------------------------------
          JMP        RST65            ;0034 =
          RST        7
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
RST7V:    JMP        RST7            ;0038 =
          RST        7
;--------------------------------------------------------------------
;RST 7.5 INTERRUPT HANDLER
;  This is triggered by the timer-out pin of the 8155 
;  every 9.25mS (?) (counter set to D770 = 55'152 CPU clockcycles) see PORT 68H description
;  or is it half that speed? double? can't get my head around the datasheet and this video:
;  youtube.com/watch?v=kagzY65Z_Yg
;--------------------------------------------------------------------
L003C:    PUSH      PSW                ;003C =            
          PUSH      H                  ;
          MVI       L,0                ;
          DAD       SP                 ;
          MOV       A,L                ;
          CPI       00EH               ;
          JC        A04                ;
          PUSH      D                  ;
          PUSH      B                  ;
          CALL      PR0311             ;
          POP       B                  ;
          POP       D                  ;
A04:      POP       H                  ;
          POP       PSW                ;
          EI                           ;
          RET                          ;
;--------------------------------------------------------------------
; Populate Parameter default values
;--------------------------------------------------------------------
START1:   CALL      PR0084             ; configure 8155 (Timer)
          LXI       H,TAPFMT           ; load addr. of Tape-Format Parameter
;         INR       M                  ; increment from 0 to 1 to set the default? Strange. why not MVI M,01 ?
          MVI       M,004H             ; I want default tape format = 4 ('ASCII Hex Space', better for experimenting)
          MVI       L,LOW(STACOD)      ;
;         MVI       M,002H             ; Set Start-Byte (for 'ASCII Hex Space' tape format) to STX=02H
                                       ; Start/Stop Bytes can be changed by command X8/X9, but are lost on reset.
                                       ; as i can't enter the ASCII Chars [STX]&[ETX] manually, i set it to capital Letters S and X
                                       ; because they are not in Hex E to F and are the first and last chars in the default [STX] and [ETX]
                                       ; This way, playing around with the tape commands is easyer, Tape Data can now be typed in.
          MVI       M,053H             ; changing default to char. 'S'=53H
          INX       H                  ;
          INX       H                  ; move pointer to next parameter
;         MVI       M,003H             ; Set Stop-Byte (for 'ASCII Hex Space' tape format) to ETX=03H
          MVI       M,058H             ; changing default to char. 'X'=58H
START2:   LDA       D6067              ; ? what's in 6067?
          CPI       003H               ;
          JNC       PR115F             ;
          ORA       A                  ;
          JNZ       PR0E2B             ;
START3:   CALL      PR0196             ; 8085 Simulator: 3k clock cycles to here
START4:   LXI       SP,STK             ; 760k ! to here...
          CALL      PR00EE             ;
          PUSH      PSW                ;
          CALL      PR00DD             ;
          POP       PSW                ;
          CALL      PR0D99             ;
          CNZ       PR0181             ;
          JMP       START3             ;
;--------------------------------------------------------------------
; INIT Timer, PORT C, ram? called from START 1
;--------------------------------------------------------------------
PR0084:   MVI       A,05BH             ;
          SIM                          ; Set Interrupt Mask to 5b=0101 1011
          MVI       A,070H             ;
          OUT       PTIMLOW             ;
          MVI       A,0D7H             ;
          OUT       PTIMHIG             ;
          MVI       A,0C3H             ;
          OUT       PIO6CMD             ;
          MVI       A,091H             ;
          OUT       IOCCMD             ;
; 091H Configures the 8255 PPI ports as follows:
; Port A: Input Port B: Output Port C Upper (PC7-PC4): Output Port C Lower (PC3-PC0): Input
          MVI       B,010H             ;
          MVI       A,002H             ; 02H = DRAM read
          OUT       P80RAM             ;
          XRA       A                  ;
A01:      OUT       P81RAM             ;
          OUT       P82RAM             ;
          DCR       B                  ;
          JNZ       A01                ;
          MVI       B,040H             ; 
          LXI       H,D6040            ;
;--------------------------------------------------------------------
; Also called from PR019A...
;--------------------------------------------------------------------
PR00AB:   XRA       A                  ;
          CALL      PR00E7             ; ? Fill M to M+B with A
          MVI       A,0C8H             ;
          CALL      PR112A             ;
          MVI       A,020H             ;
          OUT       RS232              ; set RTS
          MVI       A,080H             ;
          STA       D6073              ;
          LDA       D606D              ; ?last port A command
          ORA       A                  ;
          JZ        A02                ;
          CPI       092H               ; compare if default
          JZ        A03                ;
          RST       FUN4               ;
          DB        2                  ;
          CALL      PR113B             ;
A02:      MVI       A,092H             ;
          CALL      PR1113             ;
A03:      XRA       A                  ;
          CALL      PR0856             ;
          LXI       H,1                ;
          SHLD      D6070              ;
;--------------------------------------------------------------------
; ? fill 7 bytes from 6041H with 10H
;--------------------------------------------------------------------
PR00DD:   LXI       H,D6040            ;
          MVI       M,011H             ;
          INX       H                  ;
          MVI       B,007H             ;
          MVI       A,010H             ;
;--------------------------------------------------------------------
; ? Fill M to M+B with A
;--------------------------------------------------------------------
PR00E7:   MOV       M,A                ;
          INX       H                  ;
          DCR       B                  ;
          JNZ       PR00E7             ;
          RET                          ;
;--------------------------------------------------------------------
; ? wait for input... disp. out?
;--------------------------------------------------------------------
PR00EE:   CALL      PR0DD4             ;
          CALL      PR0138             ;
          LDA       D6071              ;
          ORA       A                  ;
          JZ        PR00EE             ;
          RST       FUN7               ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR00FC:   PUSH     PSW                 ;
          CALL     PR0DD4              ;
          LDA      D6069               ;
          CPI      008H                ;
          JNC      A05                 ;
          POP      PSW                 ;
          RET                          ;
A05:      POP      PSW                 ;
          XRA      A                   ;
          RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR010D:   LDA      D6071               ;
          ORA      A                   ;
          RZ                           ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
RST7:   PUSH     B                   ;
          PUSH     H                   ;
          LXI      H,D6071             ;
          XRA      A                   ;
          MOV      B,A                 ;
A10:      ORA      M                   ;WAIT FOR EVENT
          JZ       A10                 ;
          MOV      M,B                 ;
          INX      H                   ;
          MOV      C,M                 ;
          LXI      H,KEYMAP            ;
          DAD      B                   ;
          CALL     PR01A7              ;
          MOV      A,M                 ;
          POP      H                   ;
          POP      B                   ;
          CPI      012H                ;
          RZ                           ;
          CPI      017H                ;
          CMC                          ;
          RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0131:   CALL     PR0174              ;
          RZ                           ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0135:   CALL     PR0DD4              ;
;--------------------------------------------------------------------
; ? Write Display Data (used Ports)
;   first called in Bootup after 761k cycles
;--------------------------------------------------------------------
PR0138:   PUSH     D                   ;
          PUSH     H                   ;
          LHLD     D6069               ;
          MVI      H,000H              ;
          INR      L                   ;
          MOV      A,L                 ;
          CPI      009H                ;
          PUSH     PSW                 ;
          LDA      D6067               ;
          ORA      A                   ;
          JPE      A13                 ;
          POP      PSW                 ;
          JNZ      A11                 ;
          XRA      A                   ;
          JMP      A12                 ;
A11:      LXI      D,LEDMAP            ;
          DAD      D                   ;
          LDA      D606C               ; read which digit was last selected?
          ANI      077H                ; mask out bit 4 and 7
          OUT      PDKSELB             ;
          MOV      A,M                 ;
A12:      OUT      PLEDSEG             ;
          POP      H                   ;
          POP      D                   ;
          RET                          ;
A13:      POP      PSW                 ;
          JNZ      A14                 ;
          MVI      A,010H              ;
          JMP      A15                 ;
A14:      MOV      A,L                 ;
A15:      STA      D6041               ;
          POP      H                   ;
          POP      D                   ;
          RET                          ;
;--------------------------------------------------------------------
; read eprom-type switch-states
;   first called after 761k cycles
;--------------------------------------------------------------------
PR0174:   LXI      H,D6075             ;
          MOV      A,M                 ; read last state from 6075?
          PUSH     PSW                 ;
          IN       SWSTAT              ; Port C0H
          ANI      03CH                ; mask out unrelated bits 0,1,6,7
          MOV      M,A                 ; write current state to 6075?
          POP      PSW                 ;
          CMP      M                   ;
          RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0181:   CALL     PR00DD
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0184:   LXI      B,A0305             ;
A16:      PUSH     B                   ;
          CALL     PR01C1              ;
          POP      B                   ;
          PUSH     B                   ;
          CALL     PR01A9              ;
          POP      B                   ;
          DCR      B                   ;
          JNZ      A16                 ;
          RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0196:   XRA      A                   ;
;--------------------------------------------------------------------
; only call is in PR 115F
;--------------------------------------------------------------------
PR0197:   STA      D6067               ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR019A:   MVI       B,008H             ;
          LXI       H,D6058            ;
          CALL      PR00AB             ;
          MVI       C,01EH             ;
          JMP       PR01A9             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR01A7:   MVI       C,005H             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR01A9:   EI                           ;
A17:      MVI       B,010H             ;
A18:      LDA       D606C              ; ? Main Loop in standalone Mode? looping every 1576 steps...
          CALL      PR01CF             ;
          ORI       020H               ; set bit 7 = beeper
; how would unset look like? ANI 0DFH would do it, i think. No, can't find 0DFH anywhere
          CALL      PR01CF             ;
          DCR       B                  ;
          JNZ       A18                ;
          DCR       C                  ;
          JNZ       A17                ;
          EI                           ;
          RET                          ;
;--------------------------------------------------------------------
; ? Display Output (used Ports)
;--------------------------------------------------------------------
PR01C1:   MVI       B,030H             ;
A19:      CALL      PR01D1             ;
          DCR       B                  ;
          JNZ       A19                ;
          DCR       C                  ;
          JNZ       PR01C1             ;
          RET                          ;
;--------------------------------------------------------------------
; only called from PR01A9 (twice)
;--------------------------------------------------------------------
PR01CF:   OUT       PDKSELB             ;
;--------------------------------------------------------------------
; ? get key row readings (?? reads only 3 rows (at a time?))
;--------------------------------------------------------------------
PR01D1:   DI                           ;
          PUSH      PSW                ;
          CALL      PR0374             ; row C8 > stored to ROWDATA
          CALL      PR0374             ; C9 to 6051
          CALL      PR0374             ; CA to 6052
          XRA       A                  ;
          OUT       PLEDSEG             ; why blank led segments?
          POP       PSW                ;
          RET                          ;
;2nd pass 5D > 6053 5C > 6054 ...
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR01E1:   MOV       A,H                ;
          CALL      PR01E6             ;
          MOV       A,L                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR01E6:   PUSH      PSW                ;
          LDA       TAPFMT              ;
          CPI       005H               ;
          JNZ       A19X               ;!!    
          POP       PSW                ;
          CALL      PR0C00             ;
          JMP       PR01FB             ;
A19X:     POP       PSW                ;
          PUSH      PSW                ;
          ADD       C                  ;
          MOV       C,A                ;
          POP       PSW                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR01FB:   PUSH      PSW                ;
          CALL      PR09FA             ;
          CALL      PR0203             ;
          POP       PSW                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0203:   ANI       00FH               ;
          ADI       090H               ;
          DAA                          ;
          ACI       040H               ;
          DAA                          ;
;--------------------------------------------------------------------
;Read Keys (It reads from PKROWIN... )
; Specifically read in Terminal Mode? (It does R/W to PORTC=RS232)
;--------------------------------------------------------------------
PR020B:   PUSH      B                  ;
          PUSH      D                  ;
          PUSH      H                  ;
          PUSH      PSW                ;
          MOV       E,A                ;
          MVI       D,009H             ;
          DI                           ;
          XRA       A                  ; Clear Display
          OUT       PLEDSEG             ;
          LDA       D606C              ;
          ANI       0E0H               ; Mask out bits 0-4
          OUT       PDKSELB             ;
          ORI       009H               ;
          OUT       PDKSELB             ;
          LXI       B,0105H            ;
          CALL      PR02F0             ;DELAY?
          IN        PKROWIN             ;
          ANI       004H               ;
          JNZ       START2             ;
          CALL      PR0961             ;
          JNZ       A20                ;
          IN        RS232              ;
          ANI       001H               ;
          JNZ       START2             ;
A20:      IN        RS232              ;
          ANI       004H               ;
          JNZ       PR0F26             ;
          IN        RS232              ;
          ANI       002H               ;
          JNZ       A20                ;
          MVI       A,0A0H             ;
A21:      OUT       RS232              ;
          NOP                          ;
          CALL      PR02E5             ;
          MOV       A,E                ;
          RRC                          ;
          MOV       E,A                ;
          CMA                          ;
          ANI       080H               ;
          ORI       020H               ;
          DCR       D                  ;
          JNZ       A21                ;
          MVI       A,020H             ;
          OUT       RS232              ;
          CALL      PR02E5             ;
          CALL      PR02E5             ;
A0267:    CALL      PR02E5             ;
          POP       PSW                ;
          POP       H                  ;
          POP       D                  ;
          POP       B                  ;
          ORA       A                  ;
          RET                          ;
;--------------------------------------------------------------------
; ? read serial
;--------------------------------------------------------------------
PR0270:   PUSH      B                  ;
          PUSH      D                  ;
          PUSH      H                  ;
          LXI       D,K0800            ;
          DI                           ;
          XRA       A                  ;
          OUT       PLEDSEG             ; clear Display
          LDA       D6067              ;
          CPI       002H               ;
          JNC       A23                ;
          LDA       D6058              ;
          ORA       A                  ;
          MVI       A,000H             ;
          JZ        A24                ;
A23:      XRA       A                  ;
          ORI       010H               ;
A24:      PUSH      PSW                ;
          LDA       D6074              ;
          ORA       A                  ;
          JZ        A26                ;
          CALL      PR0135             ;
          POP       PSW                ;
          OUT       RS232              ;
A25:      IN        RS232              ;
          ANI       004H               ;
          JNZ       PR0F26             ;
          CALL      PR0131             ;
          IN        RS232              ;
          ANI       001H               ;
          JZ        A25                ;
          JMP       A28                ;
A26:      POP       PSW                ;
          OUT       RS232              ;
A27:      IN        RS232              ;
          ANI       004H               ;
          JNZ       PR0F26             ;
          IN        RS232              ;
          ANI       001H               ;
          JZ        A27                ;
A28:      XRA       A                  ;
          OUT       RS232              ;
          LXI       B,A0305            ;
          CALL      PR02E8             ;
A29:      IN        RS232              ;
          RRC                          ;
          CMA                          ;
          ANI       080H               ;
          ORA       E                  ;
          DCR       D                  ;
          JZ        A30                ;
          RRC                          ;
          MOV       E,A                ;
          CALL      PR02E5             ;
          JMP       A29                ;
A30:      PUSH      PSW                ;
          MVI       A,020H             ;
          OUT       RS232              ;
          JMP       A0267              ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR02E5:   LXI       B,A02F9            ;
;--------------------------------------------------------------------
;?bitzeit
;--------------------------------------------------------------------
PR02E8:   LHLD      D6060              ;
          DAD       H                  ;
          DAD       B                  ;
          MOV       C,M                ;
          INX       H                  ;
          MOV       B,M                ;
;-------------------------------------------------------------------
; Delay ?          
;-------------------------------------------------------------------
PR02F0:   DCR       C                  ;
          JNZ       PR02F0             ;
          DCR       B                  ;
          JNZ       PR02F0             ;
          RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
A02F9:    DW        0122H              ;
          DW        014FH              ;
          DW        01A8H              ;
          DW        025AH              ;
          DW        03BEH              ;
          DW        088CH              ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
A0305:    DW        013AH              ;
          DW        017DH              ;
          DW        0100H              ;
          DW        030DH              ;
          DW        0523H              ;
          DW        0C58H              ;
;--------------------------------------------------------------------
; only called from Interrupt 7.5
;--------------------------------------------------------------------
PR0311:   CALL      PR0374             ; ?read 1 Key row?
          RNZ                          ;
          EI                           ;
          CALL      PR0347             ;
          LDA       D6067              ;
          CPI       004H               ;
          RZ                           ;
;--------------------------------------------------------------------
; ? Disp. related (LED MAP)
;--------------------------------------------------------------------
PR031F:   LXI       D,D6040            ;
          MVI       B,008H             ;
          LXI       H,8                ;
          DAD       D                  ;
          PUSH      H                  ;
          XCHG                         ;
          MVI       D,000H             ;
A31:      MOV       A,M                ;
          ANI       080H               ;
          MOV       C,A                ;
          MOV       A,M                ;
          ANI       07FH               ;
          MOV       E,A                ;
          PUSH      H                  ;
          LXI       H,LEDMAP           ;
          DAD       D                  ;
          MOV       A,M                ;
          ORA       C                  ;
          POP       H                  ;
          XTHL                         ;!!    pass argument to func.
                                       ;      https://stackoverflow.com/a/35489629/1331544
          MOV       M,A                ;
          INX       H                  ;
          XTHL                         ;
          INX       H                  ;
          DCR       B                  ;
          JNZ       A31                ;
          POP       H                  ;
          RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0347:   XRA       A                  ;
          LXI       H,ROWDATA          ;
          LXI       D,07FFH            ;
          PUSH      PSW                ;
A32:      MVI       B,004H             ;
A33:      INR       E                  ;
          MOV       A,M                ;
          RRC                          ;
          MOV       M,A                ;
          JNC       A34                ;
          POP       PSW                ;
          INR       A                  ;
          PUSH      PSW                ;
          MOV       C,E                ;
A34:      DCR       B                  ;
          JNZ       A33                ;
          INX       H                  ;
          DCR       D                  ;
          JNZ       A32                ;
          POP       PSW                ;
          MVI       L,LOW(D6070)       ;!!
          MOV       B,M                ;
          MOV       M,A                ;
          DCR       A                  ;
          RNZ                          ;
          ORA       B                  ;
          RNZ                          ;
          INX       H                  ;
          MVI       M,0FFH             ;
          INX       H                  ;
          MOV       M,C                ;
          RET                          ;
;--------------------------------------------------------------------
; Read single Key Row in Normal-mode (Mode after Boot)? 
;   It reads from PORTB... 
;   ... After setting the Key COL to read (OUT PDKSELB) see also PR020B
;   In Simulator, this is for a long time called every ~230 cycles after boot.
;--------------------------------------------------------------------
PR0374:   PUSH      B                  ;
          PUSH      H                  ;
          LXI       H,D6065            ;
          XRA       A                  ;
          MOV       B,A                ;
          OUT       PLEDSEG             ; clear display
          MOV       A,M                ;
          INR       M                  ;
          ANI       007H               ;
          MOV       C,A                ;
          MVI       L,LOW(D606C)       ;
          ORA       M                  ;
          OUT       PDKSELB             ; select LED Digit?
          MVI       L,LOW(D6048)       ;
          DAD       B                  ;
          MOV       A,M                ;
          OUT       PLEDSEG             ; set display (A not empty)
          MVI       L,LOW(ROWDATA)       ;
          DAD       B                  ;
          IN        PKROWIN             ;
          MOV       M,A                ;
          MOV       A,C                ;
          CPI       006H               ;
          POP       H                  ;
          POP       B                  ;
          RET                          ;
;--------------------------------------------------------------------
; 7-Segment Display Character Table
;   accessed from PR0138-A11 and PR031F-A31
;   never on bootup, so the dash-display on bootup is hardcoded?
;--------------------------------------------------------------------

LEDMAP:   DB        03FH,006H,05BH,04FH     ; 0 1 2 3
          DB        066H,06DH,07DH,027H     ; 4 5 6 7
          DB        07FH,067H,077H,07CH     ; 8 9 A b
          DB        039H,05EH,079H,071H     ; C d E F
          DB        000H,040H,05CH,073H     ;   - o P (blank,dash...)
          DB        038H,079H,039H,01EH     ; L E C J
          DB        077H                    ; A
;--------------------------------------------------------------------
;   ---a---
;  |       |
;  f       b
;  |       |
;   ---g---
;  |       |
;  e       c
;  |       |
;   ---d---
;           --
;          |dp| (decimal point, normally bottom-right)
;           -- 
;--------------------------------------------------------------------
;LED Segment Bitmap
;--------------------------------------------------------------------
;d
;p
; gfedcba
;--------------------------------------------------------------------
;00111111    0       3F
;00000110    1       06
;01011011    2       5B
;01001111    3       4F
;01100110    4       66
;01101101    5       6D
;01111101    6       7D
;00100111    7       27
;01111111    8       7F
;01100111    9       67
;01110111    A       77
;00000000    [blank] 00
;01000000    -       40
;01011100    o       5C     (used in tests)
;            P       73
;            L       38
;            J       1E
;-------------------------------------------
;missing for writing "Hellorld!" on Display:
;01110110    H       76
;01010000    r       50
;-------------------------------------------
; F7H should be the character "°A" (A with dp in upper-left), see Manual page 1-9
; (It can be triggered by pressing the "-" key in normal mode)
; but it's not in the source, must be coded differently?


;--------------------------------------------------------------------
; Map of Keycodes, see manual Page 3-26 (pdf p.50), Schematic Pages 4 & 11
;   (RST Key is hard-wired to CPU-Reset)
;   Keypresses (<>Keycodes!) are being read from Port 06BH, written to Memory 
;--------------------------------------------------------------------
;                  Electrical Key Layout
;                    R      R      R      R
;                    o      o      o      o
;                    w      w      w      w
;           
;                    0      1      2      3
;--------------------------------------------------------------------
; Port 6B values:    1      2      4      8
;--------------------------------------------------------------------
;                    5 ,    B ,   PRG,   SET
KEYMAP:  DB        005H,  00BH,  013H,  012H    ; Col 0 & 8 (Set = Col 8)

;                    9 ,    F ,   JOB,    -    
         DB        009H,  00FH,  017H,  011H    ; Col 1 & 7 (- = Col 7)
        
;                    D ,    2 ,   CMP
         DB        00DH,  002H,  016H,  0FFH    ; Col 2
        
;                    0 ,    6 ,   ERS
         DB        000H,  006H,  015H,  0FFH    ; Col 3
        
;                    4 ,    A ,   LOD
         DB        004H,  00AH,  014H,  0FFH    ; Col 4
        
;                    8 ,    E ,    3
         DB        008H,  00EH,  003H,  0FFH    ; Col 5
        
;                    C ,    1 ,    7
         DB        00CH,  001H,  007H,  0FFH    ; Col 6
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR03CE:  PUSH      PSW                ;
         MOV       A,H                ;
         CPI       080H               ;
         JC        A36                ;
         CPI       0A0H               ;
         JNC       A36                ;
         POP       PSW                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR03DB:  PUSH      B                  ;
         PUSH      H                  ;
         DAD       H                  ;
         DAD       H                  ;
         DAD       H                  ;
         MOV       B,A                ;
         MVI       C,008H             ;
         DI                           ;
A35:     ANI       001H               ;
         OUT       P80RAM             ;
         MOV       A,L                ;
         OUT       P81RAM             ;
         MOV       A,H                ;
         OUT       P82RAM             ;
         MOV       A,B                ;
         RRC                          ;
         MOV       B,A                ;
         INX       H                  ;
         DCR       C                  ;
         JNZ       A35                ;
         JMP       A39                ;
A36:     CPI       061H               ;
         JC        A37                ;
         POP       PSW                ;
         RET                          ;
A37:     POP       PSW                ;
         MOV       M,A                ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0403:  MOV       A,H                ;
         CPI       080H               ;
         JC        A41                ;
         CPI       0A0H               ;
         JNC       A41                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR040E:  PUSH      B                  ;
         PUSH      H                  ;
         DAD       H                  ;
         DAD       H                  ;
         DAD       H                  ;
         LXI       B,8                ;
         MVI       A,002H             ;
         OUT       P80RAM             ;
         DI                           ;
A38:     MOV       A,L                ;
         OUT       P81RAM             ;
         MOV       A,H                ;
         OUT       P82RAM             ;
         IN        P83RAM             ;
         ANI       001H               ;
         ORA       B                  ;
         RRC                          ;
         MOV       B,A                ;
         INX       H                  ;
         DCR       C                  ;
         JNZ       A38                ;
A39:     LDA       D6058              ;
         ORA       A                  ;
         JNZ       A40                ;
         EI                           ;
A40:     XRA       A                  ;
         MOV       A,B                ;
         POP       H                  ;
         POP       B                  ;
         RET                          ;
A41:     CPI       061H               ;
         JC        A42                ;
         XRA       A                  ;
         RET                          ;
A42:     XRA       A                  ;
         MOV       A,M                ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0444:  POP       B                  ;
         MOV       C,A                ;
         MVI       B,000H             ;
         LXI       H,D6060            ;
         DAD       B                  ;
         DAD       B                  ;
         CALL      PR0746             ;
         XCHG                         ;
         RST       FUN7               ;
         RZ                           ;
         CALL      PR0641             ;
         RC                           ;
         RNZ                          ;
         XCHG                         ;
         MOV       M,E                ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR045B:  ADI       002H               ;
         STA       D605A              ;
         CALL      PR0615             ;
         LXI       D,K8000            ;
         PUSH      PSW                ;
         DAD       D                  ;
         POP       PSW                ;
         XCHG                         ;
A43:     RC                           ;
         ADI       0EFH               ;
         JZ        A44                ;
         DCR       A                  ;
         RNZ                          ;
         LDA       D6042+1            ;
         CPI       010H               ;
         JZ        A45                ;
         MOV       A,L                ;
         CALL      PR10B0             ;
         XRA       A                  ;
A44:     MVI       A,00EH             ;
         RAR                          ;
         XCHG                         ;
         CALL      PR0654             ;
         XCHG                         ;
A45:     CALL      PR105F             ;
         CALL      PR074C             ;
         CNZ       PR0184             ;
         RST       FUN7               ;
         RC                           ;
         JZ        A44                ;
         CALL      PR0641             ;
         JMP       A43                ;
;--------------------------------------------------------------------
;PARA?
;--------------------------------------------------------------------
PR049B:  POP       H                  ;
         LXI       D,K8000            ;
         DAD       D                  ;
         SHLD      D607D              ;
         POP       H                  ;
         LXI       D,K8000            ;
         DAD       D                  ;
         SHLD      D607B              ;
         POP       H                  ;
         LXI       D,K8000            ;
         DAD       D                  ;
         SHLD      D6079              ;
         XCHG                         ;
         LHLD      D607B              ;
         XCHG                         ;
         CALL      PR085D             ;CMP
         RC                           ;
         CALL      PR04C7             ;
         RC                           ;
         LHLD      D607D              ;
         XCHG                         ;
         JMP       PR052B             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR04C7:  LHLD      D6079              ;
         CALL      PR04D8             ;
         RC                           ;
         LHLD      D607B              ;
         CALL      PR04D8             ;
         RC                           ;
         LHLD      D607D              ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR04D8:  LXI       D,K8000            ;
         DAD       D                  ;
         MOV       A,H                ;
         CPI       020H               ;
         JZ        A46                ;
         CMC                          ;
         RET                          ;
A46:     MVI       A,001H             ;
         ANA       A                  ;
         STC                          ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR04E9:  INR       A                  ;
         JNZ       PR045B             ;
         CALL      PR05D5             ;
         RC                           ;
         RNZ                          ;
         SHLD      D6079              ;
         LXI       H,K1010            ;
         SHLD      D6044              ;
         SHLD      D6046              ;
         CALL      PR05D5             ;
         RC                           ;
         RNZ                          ;
         SHLD      D607B              ;
         LXI       H,K1010            ;
         SHLD      D6044              ;
         SHLD      D6046              ;
         LHLD      D607B              ;
         XCHG                         ;
         LHLD      D6079              ;
         MOV       A,H                ;
         CMP       D                  ;
         JC        A47                ;
         RNZ                          ;
         MOV       A,L                ;
         CMP       E                  ;
         JC        A47                ;
         RNZ                          ;
A47:     CALL      PR05D5             ;
         RC                           ;
         RNZ                          ;
         SHLD      D607D              ;
         XCHG                         ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR052B:  LHLD      D6079              ;
         MOV       A,D                ;
         CMP       H                  ;
         JC        A48                ;
         JNZ       A49                ;
         MOV       A,E                ;
         CMP       L                  ;
         JC        A48                ;
         JNZ       A49                ;
A48:     LHLD      D607B              ;
         MOV       B,H                ;
         MOV       C,L                ;
         LHLD      D607D              ;
         XCHG                         ;
         LHLD      D6079              ;
         XRA       A                  ;
         STA       D607B              ;
         CALL      PR059A             ;
         RET                          ;
A49:     LHLD      D607B              ;
         MOV       A,H                ;
         CMP       D                  ;
         JC        A48                ;
         JNZ       A50                ;
         MOV       A,L                ;
         CMP       E                  ;
         JC        A48                ;
A50:     LHLD      D6079              ;
         XCHG                         ;
         LHLD      D607D              ;
         XRA       A                  ;
         MOV       A,L                ;
         SBB       E                  ;
         MOV       E,A                ;
         MOV       A,H                ;
         SBB       D                  ;
         MOV       D,A                ;
         LHLD      D607B              ;
         DAD       D                  ;
         PUSH      H                  ;
         LHLD      D607D              ;
         MOV       B,H                ;
         MOV       C,L                ;
         POP       H                  ;
         XCHG                         ;
         LHLD      D607B              ;
         MVI       A,001H             ;
         STA       D607B              ;
         CALL      PR059A             ;
         LHLD      D607D              ;
         XCHG                         ;
         DCX       D                  ;
         MOV       B,D                ;
         MOV       C,E                ;
         INX       D                  ;
         LHLD      D6079              ;
         XRA       A                  ;
         STA       D607B              ;
         CALL      PR059A             ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR059A:  MOV       A,H                ;
         CPI       080H               ;
         JC        A52                ;
         CPI       0A0H               ;
         JNC       A52                ;
         CALL      PR040E             ;
         PUSH      PSW                ;
         XCHG                         ;
         MOV       A,H                ;
         CPI       080H               ;
         JC        A51                ;
         CPI       0A0H               ;
         JNC       A51                ;
         POP       PSW                ;
         PUSH      PSW                ;
         CALL      PR03DB             ;
A51:     POP       PSW                ;
         XCHG                         ;
A52:     MOV       A,H                ;
         CMP       B                  ;
         JNZ       A53                ;
         MOV       A,L                ;
         CMP       C                  ;
         RZ                           ;
A53:     LDA       D607B              ;
         ANA       A                  ;
         JNZ       A54                ;
         INX       H                  ;
         INX       D                  ;
         JMP       PR059A             ;
A54:     DCX       H                  ;
         DCX       D                  ;
         JMP       PR059A             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR05D5:  CALL      PR0615             ;
         RC                           ;
         RNZ                          ;
         LXI       D,K8000            ;
         DAD       D                  ;
         MOV       A,H                ;
         CPI       080H               ;
         JC        A55                ;
         CPI       0A0H               ;
         JNC       A55                ;
         XRA       A                  ;
         RET                          ;
A55:     MVI       A,001H             ;
         ANA       A                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR05EF:  CALL      PR1059             ;
         RNZ                          ;
         LDA       D6067              ;
         DCR       A                  ;
         JZ        PR0A3C             ;
         XRA       A                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR05FC:  MVI       C,0FFH             ;
         JMP       A56                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0601:  MVI       C,000H             ;
A56:     MOV       A,C                ;
         ORA       A                  ;
         JNZ       A57                ;
         RST       RSTGET             ;
         CMA                          ;
A57:     RST       RSTPUT             ;
         INX       D                  ;
         INX       H                  ;
         MOV       A,D                ;
         CMP       B                  ;
         JC        A56                ;
         JMP       PR05EF             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0615:  MVI       A,003H             ;
         STA       D6059              ;
         LXI       H,0                ;
A58:     RST       FUN7               ;
A59:     RZ                           ;
         CPI       010H               ;
         RNC                          ;
         MOV       C,A                ;
         MVI       B,000H             ;
         DAD       H                  ;
         DAD       H                  ;
         DAD       H                  ;
         DAD       H                  ;
         DAD       B                  ;
         PUSH      H                  ;
         LHLD      D6059              ;
         MOV       C,L                ;
         LXI       H,D6041            ;
         DAD       B                  ;
A60:     INX       H                  ;
         MOV       B,M                ;
         DCX       H                  ;
         MOV       M,B                ;
         INX       H                  ;
         DCR       C                  ;
         JNZ       A60                ;
         MOV       M,A                ;
         POP       H                  ;
         JMP       A58                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0641:  PUSH      PSW                ;
         LXI       H,K1010            ;
         SHLD      D6042              ;
         XRA       A                  ;
         MOV       L,A                ;
         INR       A                  ;
         STA       D6059              ;
         POP       PSW                ;
         JMP       A59                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------    
PR0652:  MVI       A,007H             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0654:  PUSH      B                  ;
         PUSH      H                  ;
         PUSH      PSW                ;
         ANI       00FH               ;
         MOV       C,A                ;
         MVI       B,000H             ;
         LXI       H,D6040            ;
         DAD       B                  ;
         MVI       B,004H             ;
A61:     POP       PSW                ;
         PUSH      PSW                ;
         RLC                          ;
         MOV       A,M                ;
         JC        A62                ;
         INR       A                  ;
         ANI       00FH               ;
         JMP       A63                ;
A62:     DCR       A                  ;
         ANI       00FH               ;
         CPI       00FH               ;
A63:     MOV       M,A                ;
         JNZ       A64                ;
         DCX       H                  ;
         DCR       B                  ;
         JNZ       A61                ;
A64:     POP       PSW                ;
         POP       H                  ;
         POP       B                  ;
         INX       H                  ;
         RLC                          ;
         RNC                          ;
         DCX       H                  ;
         DCX       H                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0686:  STA       D6073              ;
         LDA       D606B              ;
         ORA       A                  ;
         CNZ       PR0835             ;
         CALL      PR00DD             ;
         DCX       H                  ;
         MOV       M,B                ;??
         MOV       L,B                ;
         MOV       H,B                ;
         SHLD      D605C              ;
         CALL      PR0718             ;
         CALL      PR02F0             ;
         JMP       PR0DCC             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR06A3:  PUSH      B                  ;
         MOV       B,A                ;
         LDA       D6067              ;
         ORA       A                  ;
         JNZ       A65                ;
         CALL      PR0184             ;
         POP       B                  ;
         LDA       D6059              ;
         ORA       A                  ;
         CNZ       PR06FB             ;
         RST       FUN7               ;
         RET                          ;
A65:     CALL      PR06FB             ;
         DCR       A                  ;
         JZ        A66                ;
         POP       B                  ;
         RET                          ;
A66:     PUSH      H                  ;
         PUSH      D                  ;
         MOV       D,A                ;
         CALL      PR0CD2             ;
         LDA       D6073              ;
         ANI       0C0H               ;
         CALL      PR09FA             ;
         MOV       E,A                ;
         LXI       H,A0730            ;
         DAD       D                  ;
         CALL      PR07E4             ;!!PRINT
         RST       FUN5               ;
         DB        'V',' '+80H        ;
         POP       H                  ;
         CALL      PR07CC             ;
         XCHG                         ;
         POP       H                  ;
         RST       RSTGET             ;
         MOV       C,A                ;
         LDA       D605A              ;
         ORA       A                  ;
         JNZ       A67                ;
         DCR       B                  ;
         MVI       C,0FFH             ;
A67:     CALL      PR07D7             ;
         CALL      PR0705             ;
         RST       FUN5               ;
         DB        '*'+80H            ;
         MOV       A,C                ;
         CALL      PR01FB             ;
         POP       B                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR06FB:  PUSH      H                  ;
         LHLD      D605E              ;
         INX       H                  ;
         SHLD      D605E              ;
         POP       H                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0705:  LDA       D6041              ;
         CPI       011H               ;
         MOV       A,B                ;
         JNZ       PR01FB             ;
A68:     RST       FUN5               ;
         DB        '-','-'+80H        ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0712:  JZ        PR01FB             ;
         JMP       A68                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0718:  LDA       D6073              ;
         LXI       H,K9010            ;
         SUI       040H               ;
         JC        A69                ;
         LXI       H,K1090            ;
         SUI       040H               ;
         JC        A69                ;
         MOV       L,H                ;
A69:     SHLD      D6042              ;
         RET                          ;
;--------------------------------------------------------------------
; Voltage Margin Check
;--------------------------------------------------------------------
A0730:   DB        '5.2','5'+80H      ;
         DB        '4.7','5'+80H      ;
         DB        '5.0','0'+80H      ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR073C:  CALL      PR106A             ;
         PUSH      D                  ;
         LXI       D,D6040            ;
         JMP       A70                ;
;-------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0746:  RST        RSTGET            ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0747:  PUSH      B                  ;
         MOV       B,A                ;
         XRA       A                  ;
         MOV       A,B                ;
         POP       B                  ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR074C:  PUSH      D                  ;
         LXI       D,D6042            ;
A70:     PUSH      PSW                ;
         CALL      PR0758             ;
         POP       PSW                ;
         POP       D                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
         RST       RSTGET
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0758:  PUSH      PSW                ;
         CALL      PR09FA             ;
         CALL      PR0760             ;
         POP       PSW                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0760:  PUSH      B                  ;
         MVI       B,011H             ;
         JNZ       A71                ;
         ANI       00FH               ;
         MOV       B,A                ;
A71:     LDAX      D                  ;
         ANI       080H               ;
         ORA       B                  ;
         STAX      D                  ;
         INX       D                  ;
         POP       B                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------    
PR0771:  MVI       C,001H             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0773:  LXI       H,0                ;
A72:     MOV       B,A                ;
         CALL      PR0866             ;
         JC        A73                ;
         DAD       H                  ;
         DAD       H                  ;
         DAD       H                  ;
         DAD       H                  ;
         ORA       L                  ;
         MOV       L,A                ;
         MOV       A,B                ;
         CALL      PR020B             ;
         JMP       A75                ;
A73:     XTHL                         ;
         PUSH      H                  ;
         MOV       A,B                ;
         CALL      PR07AA             ;
         JNC       A74                ;
         DCR       C                  ;
         JNZ       ERRMSG             ;
         RET                          ;
A74:     JNZ       ERRMSG             ;
         DCR       C                  ;
         RZ                           ;
         MOV       A,B                ;
         CALL      PR020B             ;
         LXI       H,0                ;
A75:     CALL      RST6               ;
         JMP       A72                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR07AA:  CPI       00AH               ;
         STC                          ;
         RZ                           ;
         CPI       00DH               ;
         STC                          ;
         RZ                           ;
         CPI       020H               ;
         RZ                           ;
         CPI       02CH               ;
         RZ                           ;
         CPI       02FH               ;
         STC                          ;
         CMC                          ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
RST6:    RST       FUN3               ;
         ANI       07FH               ;
         JZ        RST6               ;
         CPI       07FH               ;
         JZ        RST6               ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR07C9:  CALL      PR0CD2             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR07CC:  MOV       A,H                ;
         CALL      PR01FB             ;
         MOV       A,L                ;
         JMP       PR01FB             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR07D4:  CALL      PR07DA             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR07D7:  CALL      PR07DA             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR07DA:  RST       FUN5               ;
         DB        ' '+80H            ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
RST5:    XTHL                         ;
         CALL      PR07E4             ;
         XTHL                         ;
         XRA       A                  ; clear A
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR07E4:  MOV       A,M                ;
         ANI       07FH               ;
         CALL      PR020B             ;
         MOV       A,M                ;
         INX       H                  ;
         RLC                          ;
         JNC       PR07E4             ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR07F1:  PUSH      H                  ;
         LXI       H,K8000            ;
         SHLD      D605C              ;
         POP       H                  ;
         XCHG                         ;
         MOV       H,B                ;
A76:     DAD       D                  ;
         XCHG                         ;
         DCX       D                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR07FF:  LDA       SETSTA             ;
         ANI       010H               ;
         MOV       A,B                ;
         JZ        A77                ;
         DCR       B                  ;
         JZ        A77                ;
         RAL                          ;
A77:     MOV       H,A                ;
         DCR       A                  ;
         STA       D605B              ;
         JMP       A76                ;
;--------------------------------------------------------------------
; ? ASCII Hex Space Tape-Format related? LHLD      D6069   loads the start-byte (X8 Parameter)
;--------------------------------------------------------------------
PR0815:  PUSH      D                  ;
         PUSH      H                  ;
         LHLD      D6069              ;
         MVI       H,000H             ;
         DAD       H                  ;
         DAD       H                  ;
         MOV       E,L                ;
         MOV       D,H                ;
         DAD       H                  ;
         DAD       D                  ;
         LXI       D,A0D45            ;
         DAD       D                  ;
         MOV       E,A                ;
         MVI       D,000H             ;
         DAD       D                  ;
         MOV       A,M                ;
         POP       H                  ;
         POP       D                  ;
         RET                          ;
;--------------------------------------------------------------------
;RST 4 ENTRY POINT
;PICKS BYTE AFTER RST CODE
;--------------------------------------------------------------------
RST4:    XTHL                         ;
         MOV       A,M                ;
         INX       H                  ;
         XTHL                         ;
         STA       D606B              ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0835:  CALL      PR0815             ;
         PUSH      B                  ;
         MOV       C,A                ;
         ANI       030H               ;
         JZ        A78                ;
         MOV       A,C                ;
         ANI       0CFH               ;
         JMP       A79                ;
A78:     LDA       D6073              ;
         RRC                          ;
         RRC                          ;
         CMA                          ;
         ANI       030H               ;
         ORA       C                  ;
A79:     MOV       C,A                ;
         LDA       D606E              ;
         ANI       008H               ;
         ORA       C                  ;
         POP       B                  ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0856:  OUT       EPCTRL             ;
         STA       D606E              ;
         RET                          ;
;------------------------------------------------- ------------------
;                
;-------------------------------------------------- -----------------
PR085C:  INX       H                  ;
;--------------------------------------------------- ----------------
;CMP             
;---------------------------------------------------- ---------------
PR085D:  MOV       A,D                ;
         SUB       H                  ;
         RNZ                          ;
         MOV       A,E                ;
         SUB       L                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0863:  CALL      PR0ADB             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0866:  ADI       0B9H               ;
         RC                           ;
         SUI       0E9H               ;
         RC                           ;
         CPI       00AH               ;
         CMC                          ;
         RNC                          ;
         SUI       007H               ;
         CPI       00AH               ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0875:  POP       D                  ;
         POP       H                  ;
         CALL      PR085D             ;
         JNC       A80                ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR087E:  CALL      PR07F1             ;
A80:     CALL      PR096E             ;
         RNC                          ;    
         CALL      PR088B             ;
         CALL      PR089B             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR088B:  MVI       B,03CH             ;
A81:     XRA       A                  ;
A82:     CALL      PR020B             ;
         DCR       B                  ;
         JNZ       A82                ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0896:  MVI       B,00AH             ;
         JMP       A81                ;
;--------------------------------------------------------------------
; Tape something... (loads tape format)
;--------------------------------------------------------------------
PR089B:  LDA       TAPFMT              ;
         ORA       A                  ;
         JZ        D6080              ;
         DCR       A                  ;
         JZ        PR098E             ;
         DCR       A                  ;
         JZ        PR097E             ;
         DCR       A                  ;
         JZ        PR0911             ;
         DCR       A                  ;
         JZ        PR08F8             ;
         DCR       A                  ;
         JZ        A83                ;
         RNZ                          ;    
A83:     CALL      PR08CA             ;
         RST       FUN5               ;
         DB        '/00000000',0DH,0AH+80H
         CALL      PR088B             ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR08CA:  CALL      PR088B             ;
A84:     CALL      PR085D             ;
         RC                           ;
         RST       FUN5               ;
         DB        '/'+80H            ;
         CALL      PR09D4             ;
         MVI       C,000H             ;
         CALL      PR0C00             ;
         PUSH      PSW                ;
         CALL      PR09C8             ;
         POP       PSW                ;
         PUSH      B                  ;
         CALL      PR01E6             ;
         POP       B                  ;
         MOV       A,C                ;
         CALL      PR01E6             ;
         MVI       C,000H             ;
         CALL      PR09F0             ;
         MOV       A,C                ;
         CALL      PR01E6             ;
         CALL      PR0CD2             ;
         JMP       A84                ;
;--------------------------------------------------------------------
; Tape format 'ascii hex space' related? Loads X8, X9 Parameters
;--------------------------------------------------------------------
PR08F8:  LDA       STACOD              ;
         CALL      PR020B             ;
A84X:    RST       RSTGET             ;!!
         CALL      PR01FB             ;
         CALL      PR07DA             ;
         CALL      PR085C             ;
         JNC       A84X               ;
         LDA       STOCOD              ;
         JMP       PR020B             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0911:  RST       FUN5               ;
         DB        'S','0'+80H        ;
         CALL      PR091D             ;
         CALL      PR0929             ;
         RST       FUN5               ;
         DB        'S','9'+80H        ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR091D:  RST       FUN5               ;
         DB        '030000FC',0DH,0AH+80H
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0929:  CALL      PR085D             ;
         JC        PR0896             ;
         MOV       A,L                ;
         ORA       A                  ;
         CZ        PR0896             ;
         RST       FUN5               ;
         DB        'S','1'+80H        ;
         CALL      PR09D4             ;
         MOV       B,A                ;
         ADI       003H               ;
         CALL      PR01E6             ;
         CALL      PR09C8             ;
         CALL      PR09F0             ;
         MOV       A,C                ;
         CMA                          ;
         CALL      PR01E6             ;
         CALL      PR0CD2             ;
         JMP       PR0929             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0951:  CALL      PR07F1             ;
         CALL      PR096E             ;
         RNC                          ;
         CALL      PR088B             ;
         CALL      PR097E             ;
         JMP       PR088B             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0961:  LDA       D6067              ;
         SUI       002H               ;
         RNZ                          ;
         LDA       SETSTA             ;
         CMA                          ;
         ANI       002H               ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR096E:  CALL      PR0961             ;
         STC                          ;
         RNZ                          ;
A85:     RST       RSTRX              ;
         CPI       013H               ;
         RZ                           ;
         CPI       011H               ;
         JNZ       A85                ;
         STC                          ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR097E:  MVI       A,0FFH             ;
         CALL      PR020B             ;
A86:     RST       RSTGET             ;
         CALL      PR020B             ;
         CALL      PR085C             ;
         JNC       A86                ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR098E:  CALL      PR09A0             ;
         RST       FUN5               ;
         DB        ':00000001FF',0DH,0AH+80H
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR09A0:  CALL      PR085D             ;
         JC        PR0896             ;
         MOV       A,L                ;
         ORA       A                  ;
         CZ        PR0896             ;
         RST       FUN5               ;
         DB        ':'+80H            ;
         CALL      PR09D4             ;
         CALL      PR01E6             ;
         CALL      PR09C8             ;
         XRA       A                  ;
         CALL      PR01E6             ;
         CALL      PR09F0             ;
         XRA       A                  ;
         SUB       C                  ;
         CALL      PR01E6             ;
         CALL      PR0CD2             ;
         JMP       PR09A0             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR09C8:  PUSH      D                  ;
         XCHG                         ;
         LHLD      D605C              ;
         DAD       D                  ;
         CALL      PR01E1             ;
         XCHG                         ;
         POP       D                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR09D4:  LXI       B,K1000            ;
         MOV       A,D                ;
         CMP       H                  ;
         JNZ       A87                ;
         MOV       A,L                ;
         ORI       00FH               ;
         CMP       E                  ;
         JC        A87                ;
         MOV       A,E                ;
         ANI       00FH               ;
         INR       A                  ;
         MOV       B,A                ;
A87:     MOV       A,L                ;
         ANI       00FH               ;
         CMA                          ;
         INR       A                  ;
         ADD       B                  ;
         MOV       B,A                ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR09F0:  RST       RSTGET             ;
         CALL      PR01E6             ;
         INX       H                  ;
         DCR       B                  ;
         JNZ       PR09F0             ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR09FA:  RLC                          ;
         RLC                          ;
         RLC                          ;
         RLC                          ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR09FF:  LXI       H,D605A            ;
         DCR       M                  ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0A03:  POP       H                  ;
         JMP       A88                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0A07:  POP       B                  ;
         INR       A                  ;
         JNZ       PR04E9             ;
         CALL      PR0615             ;
         RC                           ;
         RNZ                          ;
A88:     SHLD      D605C              ;
         MVI       B,001H             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0A16:  XCHG                         ;
         LXI       H,D6058            ;
         INR       M                  ;
         CALL      PR0B36             ;
         CALL      PR0A56             ;
A89:     PUSH      PSW                ;
         CALL      PR0B26             ;
         MVI       A,013H             ;
         CZ        PR020B             ;
         POP       PSW                ;
         RNZ                          ;
         LDA       D6067              ;
         ORA       A                  ;
         JZ        A90                ;
         SUI       002H               ;
         RZ                           ;
         CALL      PR07DA             ;
         CALL      PR07CC             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0A3C:  RST       FUN5               ;
         DB        ' O','K'+80H       ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
A90:     PUSH      H                  ;
         CALL      PR0196             ;
         POP       H                  ;
         LXI       D,D6044            ;
         XRA       A                  ;
         MOV       A,H                ;
         CALL      PR0758             ;
         XRA       A                  ;
         MOV       A,L                ;
         CALL      PR0758             ;
         JMP       START4             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0A56:  LXI       H,0                ;
         DAD       SP                 ;
         SHLD      D605E              ;
         MVI       L,LOW(D6000)       ;
         CALL      PR07FF             ;
         SHLD      D6077              ;
         LDA       TAPFMT             ;
         ORA       A                  ;
         JZ        D6080              ;
         DCR       A                  ;
         JZ        PR0B50             ;
         DCR       A                  ;
         JZ        PR0B3F             ;
         DCR       A                  ;
         JZ        PR0AE6             ;
         DCR       A                  ;
         JZ        PR0AB2             ;
         DCR       A                  ;
         JZ        A91                ;
         RNZ                          ;
A91:     CALL      RST55              ;
         RST       RSTRX              ;
         SUI       02FH               ;
         JNZ       A91                ;
         MOV       C,A                ;
         PUSH      D                  ;
         CALL      PR0B85             ;
         POP       D                  ;
         JC        A91                ;
         CALL      PR0BD0             ;
         CPI       011H               ;
         RNC                          ;
         MOV       B,A                ;
         ORA       A                  ;
         RZ                           ;
         PUSH      B                  ;
         CALL      PR0BD0             ;
         POP       B                  ;
         CMP       C                  ;
         RNZ                          ;
         MVI       C,000H             ;
         CALL      PR0BC5             ;
         PUSH      B                  ;
         CALL      PR0BD0             ;
         POP       B                  ;
         CMP       C                  ;
         RNZ                          ;
         JMP       A91                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0AB2:  LDA       STACOD             ;
         ORA       A                  ;
         JZ        A92                ;
         MOV       B,A                ;
A93:     CALL      PR0ADB             ;
         CMP       B                  ;
         JNZ       A93                ;
A92:     CALL      RST55              ;
         CALL      PR0863             ;
         JC        A92                ;
         CALL      PR09FA             ;
         MOV       C,A                ;
         CALL      PR0863             ;
         JC        PR0BF7             ;
         ORA       C                  ;
         CALL      PR0C11             ;
         JMP       A92                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0ADB:  RST       RSTRX              ;
         PUSH      H                  ;
         LXI       H,STOCOD           ;
         CMP       M                  ;
         POP       H                  ;
         JZ        PR0BF9             ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0AE6:  CALL      RST55              ;
         RST       RSTRX              ;
         CPI       'S'                ;
         JNZ       PR0AE6             ;
         MVI       C,0FFH             ;
         CALL      PR0BF2             ;
         CPI       009H               ;
         RNC                          ;
         DCR       A                  ;
         JNZ       PR0AE6             ;
         CALL      PR0BD0             ;
         MOV       B,A                ;
         PUSH      D                  ;
         CALL      PR0BA0             ;
         POP       D                  ;
         MOV       A,B                ;
         SUI       003H               ;
         RC                           ;
         MOV       B,A                ;
         CNZ       PR0BC5             ;
         CALL      PR0BD0             ;
         MOV       A,C                ;
         ORA       A                  ;
         JZ        PR0AE6             ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0B15:  MVI       A,0FFH             ;
         STA       D6058              ;
         CALL      PR07F1             ;
         CALL      PR0B36             ;
         CALL      PR0B3F             ;
         JMP       A89                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0B26:  LDA       D6067              ;
         ORA       A                  ;
         JZ        A93X               ;
         DCR       A                  ;
         RNZ                          ;
A93X:    LDA       SETSTA             ;!!
         CMA                          ;
         ANI       004H               ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0B36:  CALL      PR0B26             ;
         RNZ                          ;
         MVI       A,011H             ;
         JMP       PR020B             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0B3F:  RST       FUN3               ;
         INR       A                  ;
         JNZ       PR0B3F             ;
A94:     RST       FUN3               ;
         CALL      PR0C11             ;
         CALL      PR085D             ;
         JNC       A94                ;
         XRA       A                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0B50:  CALL      RST55             ;
         RST       RSTRX              ;
         SUI       ':'                ;
         JNZ       PR0B50             ;
         MOV       C,A                ;
         CALL      PR0BD0             ;
         MOV       B,A                ;
         ORA       A                  ;
         RZ                           ;
         PUSH      D                  ;
         CALL      PR0BA0             ;
         POP       D                  ;
         CALL      PR0BD0             ;
         PUSH      PSW                ;
         CALL      PR0BC5             ;
         CALL      PR0BD0             ;
         MOV       A,C                ;
         POP       B                  ;
         ORA       A                  ;
         RNZ                          ;
         ORA       B                  ;
         JZ        PR0B50             ;
         XRA       A                  ;
         RET                          ;
;--------------------------------------------------------------------
;RST 5.5 INTERRUPT HANDLER
;--------------------------------------------------------------------
RST55:   LDA       D605B              ;
         ORA       A                  ;
         RZ                           ;
         CALL      PR085D             ;
         RNC                          ;
         XRA       A                  ;
         POP       B                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0B85:  RST       RSTRX              ;
         CPI       02FH               ;
         JNZ       A96                ;
A95:     RST       RSTRX              ;
         CPI       00DH               ;
         JNZ       A95                ;
         STC                          ;
         RET                          ;
A96:     CALL      PR0B99             ;
         JMP       A97                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0B99:  PUSH      D                  ;
         CALL      PR0BF3             ;
         JMP       A99                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0BA0:  CALL      PR0BD0             ;
A97:     MOV       D,A                ;
         CALL      PR0BD0             ;
         MOV       E,A                ;
;--------------------------------------------------------------------
;TRAP INTERRUPT HANDLER ?
;--------------------------------------------------------------------
RST4B:   XCHG                         ;
         SHLD      D6077              ;
         XCHG                         ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0BAD:  LDA       D605B              ;
         ORA       A                  ;
         JNZ       A98                ;
         LHLD      D605C              ;
         DAD       D                  ;
         XRA       A                  ;
         RET                          ;
A98:     ANA       D                  ;
         ADI       080H               ;
         LXI       H,RAMSTA           ;
         ADD       M                  ;
         MOV       H,A                ;
         MOV       L,E                ;
         XRA       A                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0BC5:  CALL      PR0BD0             ;
         CALL      PR0C11             ;
         DCR       B                  ;
         JNZ       PR0BC5             ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0BD0:  PUSH      D                  ;
         CALL      PR0BF2             ;
A99:     CALL      PR09FA             ;
         MOV       D,A                ;
         CALL      PR0BF2             ;
         ORA       D                  ;
         MOV       D,A                ;
         LDA       TAPFMT             ;
         CPI       005H               ;
         JNZ       B00                ;
         MOV       A,D                ;
         CALL      PR0C00             ;
         JMP       B01                ;
B00:     MOV       A,C                ;
         SUB       D                  ;
         MOV       C,A                ;
B01:     MOV       A,D                ;
         POP       D                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0BF2:  RST       RSTRX              ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0BF3:  CALL      PR0866             ;
         RNC                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------        
PR0BF7:  ORI       0FFH               ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0BF9:  XCHG                         ;
         LHLD      D605E              ;
         SPHL                         ;
         XCHG                         ;
         RET                          ;
;--------------------------------------------------------------------
;!!
;--------------------------------------------------------------------
PR0C00:  PUSH      PSW                ;
         ANI       00FH               ;
         ADD       C                  ;
         MOV       C,A                ;
         POP       PSW                ;
         PUSH      PSW                ;
         RRC                          ;
         RRC                          ;
         RRC                          ;
         RRC                          ;
         ANI       00FH               ;
         ADD       C                  ;
         MOV       C,A                ;
         POP       PSW                ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0C11:  PUSH      H                  ;
         CALL      PR0C18             ;
         POP       H                  ;
         INX       H                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0C18:  PUSH      PSW                ;
         PUSH      B                  ;
         LDA       SETSTA             ;
         MOV       B,A                ;
         ANI       010H               ;
         JZ        B04                ;
         PUSH      D                  ;
         LHLD      D6077              ;
         MOV       D,H                ;
         MOV       E,L                ;
         INX       H                  ;
         SHLD      D6077              ;
         MOV       L,E                ;
         ORA       A                  ;
         MOV       A,D                ;
         RAR                          ;
         MOV       D,A                ;
         MOV       A,E                ;
         RAR                          ;
         MOV       E,A                ;
         MOV       A,B                ;
         ANI       020H               ;
         MOV       A,L                ;
         RRC                          ;
         JNZ       B02                ;
         JC        B07                ;
         CNC       PR0BAD             ;
         JMP       B03                ;
B02:     JNC       B07                ;
         CC        PR0BAD             ;
B03:     POP       D                  ;
B04:     POP       B                  ;
         POP       PSW                ;
;--------------------------------------------------------------------
;RST 6.5 INTERRUPT HANDLER
;--------------------------------------------------------------------
RST65:  PUSH      B                  ;
         MOV       C,A                ;
         LDA       D605A              ;
         ORA       A                  ;
         JNZ       B06                ;
         MOV       A,C                ;
         RST       RSTPUT             ;
B05:     POP       B                  ;
         RET                          ;
B06:     RST       RSTGET             ;
         CMP       C                  ;
         JZ        B05                ;
         MOV       B,A                ;
         CALL      PR07C9             ;
         JMP       A67                ;
B07:     POP       D                  ;
         POP       B                  ;
         POP       PSW                ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0C6C:  POP       D                  ;
         POP       H                  ;
         CALL      PR085D             ;
         JNC       B08                ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0C75:  CALL      PR07F1             ;
B08:     XRA       A                  ;
B09:     CZ        PR0CB8             ;
         PUSH      D                  ;
         XCHG                         ;
         LHLD      D605C              ;
         DAD       D                  ;
         MOV       A,L                ;
         ANI       0F0H               ;
         MOV       L,A                ;
         CALL      PR07DA             ;
         CALL      PR07CC             ;
         RST       FUN5               ;
         DB        ' ',':'+80H        ;
         XCHG                         ;
         POP       D                  ;
         MOV       A,L                ;
         ANI       00FH               ;
B10:     DCR       A                  ;
         PUSH      PSW                ;
         CP        PR07D7             ;
         POP       PSW                ;
         JP        B10                ;
B11:     CALL      PR07D7             ;
         RST       RSTGET             ;
         CALL      PR01FB             ;
         CALL      PR085C             ;
         JC        PR0CD2             ;
         MOV       A,L                ;
         ANI       00FH               ;
         JNZ       B11                ;
         CALL      PR0CD2             ;
         MOV       A,L                ;
         ORA       L                  ;
         JMP       B09                ;
;--------------------------------------------------------------------
; D Command (Dump) Header-Output ? 
;         'ADDR. ' String fits it. It is repeated every 16 Bytes
;--------------------------------------------------------------------
PR0CB8:  RST       FUN5               ;
         DB        0DH,0AH,'ADDR. ',':'+80h
         MVI       B,0F0H             ;
B12:     CALL      PR07D4             ;
         MOV       A,B                ;
         CALL      PR0203             ;
         INR       B                  ;
         JNZ       B12                ;
         CALL      PR0CD2             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0CD2:  RST       FUN5               ;
         DB        0DH,0AH+80H        ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0CD6:  LXI       H,D605A            ;
         DCR       M                  ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0CDA:  POP       D                  ;
         LXI       H,K8000            ;
         DAD       D                  ;
         XCHG                         ;
B13:     LXI       H,K8000            ;
         DAD       D                  ;
         CALL      PR07C9             ;
         CALL      PR07D7             ;
         CALL      PR105F             ;
         PUSH      PSW                ;
         CNZ       PR0184             ;
         POP       PSW                ;
         CALL      PR0712             ;
         CALL      PR07D7             ;
         CALL      RST6               ;
         CALL      PR07AA             ;
         RC                           ;
         MOV       B,A                ;
         JZ        B14                ;
         CALL      PR0771             ;
         POP       H                  ;
         MOV       A,L                ;
         PUSH      PSW                ;
         CALL      PR10B0             ;
         POP       PSW                ;
         RC                           ;
B14:     MOV       A,B                ;
         CPI       02FH               ;
         DCX       D                  ;
         JZ        B13                ;
         INX       D                  ;
         INX       D                  ;
         JMP       B13                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0D1A:  XRA       A                  ;
         POP       H                  ;
         LXI       B,-10              ;
         DAD       B                  ;
         INR       A                  ;
         RC                           ;
         LXI       B,6                ;
         DAD       B                  ;
         RNC                          ;
         LXI       B,D6060            ;
         DAD       H                  ;
         DAD       B                  ;
         CALL      PR07D4             ;
         MOV       A,M                ;
         CALL      PR01FB             ;
         CALL      PR07D7             ;
         CALL      RST6             ;
         CALL      PR07AA             ;
         RZ                           ;
         XCHG                         ;
         CALL      PR0771             ;
         POP       H                  ;
         MOV       A,L                ;
         STAX      D                  ;
         RET                          ;
;--------------------------------------------------------------------
; accessed only from PR0815 which seems ASCII Tape format related...
;--------------------------------------------------------------------
A0D45:   DB        020H,000H,083H,083H
         DB        085H,043H,045H,043H
         DB        042H,083H,083H,083H
         DB        020H,000H,082H,082H
         DB        084H,082H,084H,0C2H
         DB        0C0H,082H,082H,082H
         DB        010H,000H,002H,002H
         DB        004H,002H,004H,0C2H
         DB        0C0H,002H,002H,002H
         DB        010H,000H,082H,082H
         DB        084H,082H,084H,0C2H
         DB        0C0H,082H,082H,082H
         DB        010H,000H,002H,002H
         DB        004H,002H,004H,042H
         DB        040H,002H,002H,002H
         DB        008H,000H,081H,081H
         DB        084H,0C1H,0C4H,0C1H
         DB        0C3H,081H,081H,081H
         DB        008H,0B0H,081H,081H
         DB        084H,0C1H,0C4H,0C1H
         DB        0C3H,0C1H,0C0H,0C2H
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0D99:  CALL      PR0DD4             ;
         LXI       H,D6040            ;
         CPI       011H               ;
         JNZ       B15                ;
         MVI       M,098H             ;
         RST       FUN7               ;
         CPI       013H               ;
         RNZ                          ;
         ORI       080H               ;
         STA       D6059              ;
B15:     MOV       M,A                ;
         ANI       07FH               ;
         SUI       013H               ;
         RC                           ;
         MOV       L,A                ;
         CPI       004H               ;
         CZ        PR0E00             ;
         RNC                          ;    
         RST       FUN7               ;
         RC                           ;
         RNZ                          ;
         MVI       H,000H             ;
         DAD       H                  ;
         DAD       H                  ;
         LXI       B,CMDMAP+2         ;
         DAD       B                  ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0DC7:  MOV       E,M                ;
         INX       H                  ;
         MOV       D,M                ;
         PUSH      D                  ;
         EI                           ;
PR0DCC:  LXI       D,K8000            ;
         LHLD      D6061              ;
         DAD       D                  ;
         MOV       D,L                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0DD4:  PUSH      PSW                ;
         PUSH      H                  ;
         PUSH      D                  ;
         CALL      PR0174             ;
         RRC                          ;
         RRC                          ;
         SUI       005H               ;
         LXI       H,A0DF5            ;
         MOV       E,A                ;
         MVI       D,000H             ;
         DAD       D                  ;
         MOV       A,M                ;
         STA       D6069              ;
         XRA       A                  ;
         CALL      PR0815             ;
         STA       D6076              ;
         MOV       B,A                ;
         POP       D                  ;
         POP       H                  ;
         POP       PSW                ;
         RET                          ;
;--------------------------------------------------------------------
; accessed only from PR0DD4
;--------------------------------------------------------------------
A0DF5:   DB        005H,002H,000H,008H
         DB        008H,003H,001H,008H
         DB        006H,004H,008H
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0E00:  RST       FUN7               ;
         STA       D6041              ;
         CMC                          ;
         RNC                          ;
         SUI       004H               ;
         JC        PR0A07             ;
         CPI       006H               ;
         JC        PR0444             ;
         ADI       004H               ;
         MOV       L,A                ;
         CPI       012H               ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0E16:  MVI       A,002H             ;
         JMP       B16                ;
;--------------------------------------------------------------------
; Terminal-Mode startup message
;--------------------------------------------------------------------
PR0E1B:  RST       FUN5               ;
         DB        0DH,0AH,'Hellorld!',0DH,0AH,
		 DB        'X6=4(ASCII Hex Space) X8=53(S), X9=58(X',')'+80H
         MVI       A,001H             ;
B16:     STA       D6067              ;
;--------------------------------------------------------------------
; Send Command Prompt (*)
;--------------------------------------------------------------------
PR0E2B:  LXI       SP,STK             ;
         RST       FUN5               ;
         DB        0DH,0AH,'*'+80H    ;
         CALL      PR019A             ;
         LXI       H,D6074            ;
         DCR       M                  ;
         CALL      RST6             ;
         CALL      PR020B             ;
         INR       M                  ;
         CALL      PR00FC             ;
         LXI       H,CMDMAP-3         ;
B17:     INX       H                  ;
         INX       H                  ;
         INX       H                  ;
         INR       M                  ;
         JZ        ERRMSG             ;
         CMP       M                  ;
         INX       H                  ;
         JNZ       B17                ;
         CALL      RST6             ;
         CALL      PR07AA             ;
         JNC       PR0E6A             ;            
         INX       H                  ;
         CALL      PR0DC7             ;
;--------------------------------------------------------------------
; Check Command-Error
;--------------------------------------------------------------------
PR0E5F:  JZ        PR0E2B             ; Mem.Location is 0E60h (one address higher than original because the hellorld string is one byte longer than the orig. PKW-...). It is the first entry on the Stack when in Command Mode.
;--------------------------------------------------------------------
; Send Command-Error Message (?) 
;--------------------------------------------------------------------
ERRMSG:  CALL      PR0181             ;
         RST       FUN5               ;
         DB        '?'+80H            ;
         JMP       PR0E2B             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0E6A:  MOV       B,A                ;
         MOV       A,M                ;
         DCR       A                  ;
         JM        ERRMSG             ;
         MOV       E,A                ;
         MVI       D,000H             ;
         LXI       H,A0ED0            ;
         DAD       D                  ;
         DAD       D                  ;
         DAD       D                  ;
         MOV       C,M                ;
         INX       H                  ;
         XCHG                         ;
         LXI       H,PR0E5F           ;
         PUSH      H                  ;
         MOV       A,B                ;
         CALL      PR0773             ;
         XCHG                         ;
         JMP       PR0DC7             ;
;--------------------------------------------------------------------
; Commands (from Terminal mode?) See Manual A-1 (pdf p.82)
; used in PR0E2B and PR0D99
; what are the numbers? seems (max.?) bytes of argument, not really clear to me...
;--------------------------------------------------------------------
CMDMAP:  DB        'W'                ;
         DB        1                  ;
         DW        PR0EEB             ;

         DB        'L'                ;
         DB         2                 ; Takes 2chars, hex data value
         DW        PR0F89             ;

         DB        'E'                ;
         DB        0                  ;
         DW        PR1012             ;

         DB        'C'                ;
         DB        3                  ;
         DW        PR0F94             ;

         DB        'D'                ;
         DB        4                  ;
         DW        PR0C75             ;

         DB        'G'                ;
         DB        0                  ;
         DW        PR0951             ;

         DB        'S'                ;
         DB        0                  ;
         DW        PR0B15             ;

         DB        'A'                ;
         DB        0                  ;
         DW        PR0EE8             ;

         DB        'X'                ;
         DB        7                  ;
         DW        ERRMSG             ;

         DB        'M'                ;
         DB        8                  ;
         DW        ERRMSG             ;

         DB        'B'                ;
         DB        0                  ;
         DW        PR05FC             ;

         DB        'O'                ;
         DB        0                  ;
         DW        PR0601             ;

         DB        'P'                ;
         DB        5                  ;
         DW        PR087E             ;

         DB        'R'                ;
         DB        6                  ;
         DW        PR0A16             ;

         DB        'W'                ;
         DB        0                  ;
         DW        PR0E1B             ;

         DB        'W'                ;
         DB         0                 ;
         DW        PR0E16             ;

         DB        '/'                ; return from Command- to Key- Mode
         DB        0                  ;
         DW        START3             ;

         DB        0FFH               ;
         DB        0                  ;
         DW        PR115F             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------        
A0ED0:   DB        001H               ;
         DW        PR0CD6             ;
         DB        001H               ;
         DW        PR0CDA             ;
         DB        001H               ;
         DW        PR09FF             ;
         DB        002H               ;
         DW        PR0C6C             ;
         DB        002H               ;
         DW        PR0875             ;
         DB        001H               ;
         DW        PR0A03             ;
         DB        001H               ;
         DW        PR0D1A             ;
         DB        003H               ;
         DW        PR049B             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0EE8:  STA       D6059              ;
PR0EEB:  LDA       D6059              ;
         ORA       A                  ;
         JZ        B18                ;
         CALL      PR1012             ;
         RC                           ;
         RNZ                          ;
         MVI       A,080H             ;
         STA       D6073              ;
         CALL      PR00DD             ;
         MVI       A,093H             ;
         STA       D6040              ;
B18:     CALL      PR0F37             ;
         PUSH      H                  ;
         LXI       H,D6058            ;
         DCR       M                  ;
         PUSH      H                  ;
         CALL      PR0F53             ;
         POP       H                  ;
         INR       M                  ;
         EI                           ;
         JC        PR1010             ;
         CALL      PR0F37             ;
         POP       B                  ;
         MOV       A,L                ;
         CMP       C                  ;
         JNZ       B19                ;
         MOV       A,H                ;
         CMP       B                  ;
         JZ        PR0F94             ;
B19:     MVI       D,000H             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0F26:  CALL      PR0184             ;
         CALL      PR010D             ;
         JNC       PR0F26             ;
         MOV       A,D                ;
         ORA       A                  ;
         JNZ       START3             ;
         JMP       START2             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0F37:  CALL      PR0DCC             ;
         PUSH      H                  ;
         LXI       H,0                ;
         XTHL                         ;
B20:     RST       RSTGET             ;
         MOV       C,A                ;
         MVI       B,000H             ;
         XTHL                         ;
         DAD       B                  ;
         XTHL                         ;
         INX       D                  ;
         INX       H                  ;
         LDA       D6076              ;
         MOV       B,A                ;
         MOV       A,D                ;
         CMP       B                  ;
         JC        B20                ;
         POP       H                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0F53:  CALL      PR0DCC             ;
         XRA       A                  ;
         STA       D6040              ;
B21:     CNZ       PR0652             ;
         CALL      PR0746             ;
         MOV       C,A                ;
         CALL      PR073C             ;
         CMP       C                  ;
         JZ        B22                ;
         MOV       A,C                ;
         INR       A                  ;
         JNZ       B23                ;
B22:     LDA       SETSTA              ;
         RRC                          ;
         JC        B24                ;
B23:     CALL      PR10D8             ;
B24:     CALL      PR010D             ;
         JC        PR0F83             ;
         INX       D                  ;
         MOV       A,D                ;
         CMP       B                  ;
         JC        B21                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0F83:  EI                           ;
         PUSH      PSW                ;
         RST       FUN4               ;
         DB        3                  ;
         POP       PSW                ;
         RET                          ;
;--------------------------------------------------------------------
;L-COMMAND (LOAD PROM INTO BUFFER)
;--------------------------------------------------------------------
PR0F89:  CALL      PR106A             ;
         RST       RSTPUT             ;
         INX       D                  ;
         INX       H                  ;
         MOV       A,D                ;
         CMP       B                  ;
         JC        PR0F89             ;
;--------------------------------------------------------------------
;C COMMAND (COMPARE)
;--------------------------------------------------------------------
PR0F94:  LXI       H,D605A            ;
         DCR       M                  ;
         CALL      PR0FF7             ;
B25:     CALL      PR0686             ;
B26:     CNZ       PR0652             ;
         CALL      PR0746             ;
         CALL      PR1003             ;
         CALL      PR073C             ;
         JNZ       B27                ;
         PUSH      B                  ;
         MOV       B,A                ;
         RST       RSTGET             ;
         CMP       B                  ;
         MOV       A,B                ;
         POP       B                  ;
B27:     CNZ       PR06A3             ;
         EI                           ;
         RC                           ;
         INX       D                  ;
         MOV       A,D                ;
         CMP       B                  ;
         JC        B26                ;
         LDA       D6073              ;
         SUI       040H               ;
         JNC       B25                ;
         LHLD      D605C              ;
         LDA       D6067              ;
         ORA       A                  ;
         JZ        B28                ;
         DCR       A                  ;
         JNZ       PR05EF             ;
         CALL      PR07DA             ;
         MOV       A,H                ;
         CALL      PR01FB             ;
         MOV       A,L                ;
         CALL      PR01FB             ;
         JMP       PR05EF             ;
B28:     PUSH      H                  ;
         CALL      PR0196             ;
         POP       H                  ;
         LXI       D,D6044            ;
         XRA       A                  ;
         MOV       A,H                ;
         CALL      PR0758             ;
         XRA       A                  ;
         MOV       A,L                ;
         CALL      PR0758             ;
         JMP       START4             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR0FF7:  LDA       SETSTA              ;
         ANI       008H               ;
         LDA       D6073              ;
         RZ                           ;
         SUI       040H               ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR1003:  PUSH      B                  ;
         PUSH      H                  ;
         MOV       C,A                ;
         MVI       B,000H             ;
         LHLD      D605C              ;
         DAD       B                  ;
         SHLD      D605C              ;
         POP       H                  ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR1010:  POP       B                  ;
         RET                          ;
;--------------------------------------------------------------------
;E COMMAND (ERASE-CHECK)
;--------------------------------------------------------------------        
PR1012:  CALL      PR1130             ;
         LDA       D6069              ;
         CPI       006H               ;
         JNZ       B29                ;
         RST       FUN4               ;
         DB        9                  ;
         RST       FUN4               ;
         DB        0AH                ;
         RST       FUN4               ;
         DB        0BH                ;
         MVI       A,003H             ;
         CALL      PR113F             ;
         RST       FUN4               ;
         DB        0AH                ;
         RST       FUN4               ;
         DB        9                  ;
         CALL      PR0F83             ;
B29:     CALL      PR0FF7             ;
B30:     CALL      PR0686             ;
B31:     CNZ       PR0652             ;
         CALL      PR073C             ;
         JNZ       B32                ;
         INR       A                  ;
B32:     CNZ       PR06A3             ;
         EI                           ;
         RC                           ;
         INX       D                  ;
         MOV       A,D                ;
         CMP       B                  ;
         JC        B31                ;
         LDA       D6073              ;
         SUI       040H               ;
         JNC       B30                ;
         LDA       D6059              ;
         ORA       A                  ;
         JZ        PR05EF             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR1059:  LHLD      D605E              ;
         MOV       A,H                ;
         ORA       L                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR105F:  LDA       D605A              ;
         ORA       A                  ;
         JNZ       PR106A             ;
         XCHG                         ;
         RST       RSTGET             ;
         XCHG                         ;
         RET                          ;
;--------------------------------------------------------------------
; read switches and ...?
;--------------------------------------------------------------------
PR106A:  PUSH      B                  ;
         PUSH      H                  ;
         LDA       D606D              ;
         CPI       090H               ;
         MVI       A,090H             ;
         CNZ       PR110E             ;
         LDA       D606B              ;
         INR       A                  ;
         CALL      PR0835             ;
         CALL      PR114A             ;
         MVI       L,0E0H             ;??
B33:     LDA       D606F              ;
         ORA       L                  ;
         OUT       PEPRAD2             ;
         PUSH      PSW                ;
         POP       PSW                ;
         IN        SWSTAT             ; Port C0H
         ANI       001H               ; isolate bit 0 = level comparator HI
         MOV       C,A                ;
         IN        SWSTAT             ;
         ANI       002H               ; isolate bit 1 = l.comp. LO
         RRC                          ; shift to bit 0
         CMP       C                  ; zero is set if A >= C
         JNZ       B34                ; 
         RRC                          ;
         MOV       A,H                ;
         RAL                          ;
         MOV       H,A                ;
         MOV       A,L                ;
         SUI       020H               ;
         MOV       L,A                ;
         JNC       B33                ;
         XRA       A                  ;
B34:     MOV       A,H                ;
         PUSH      PSW                ;
         LDA       D606B              ;
         CALL      PR0835             ;
         POP       PSW                ;
         POP       H                  ;
         POP       B                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR10B0:  PUSH      B                  ;
         MOV       C,A                ;
         CALL      PR10C1             ;
         CALL      PR105F             ;
         JNZ       B35                ;
         CMP       C                  ;
B35:     CNZ       PR0184             ;
         POP       B                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR10C1:  LDA       D605A              ;
         ORA       A                  ;
         JNZ       B36                ;
         MOV       A,C                ;
         XCHG                         ;
         RST       RSTPUT             ;
         XCHG                         ;
         RET                          ;
B36:     LDA       SETSTA              ;
         RRC                          ;
         RNC                          ;
         CALL      PR10D8             ;
         JMP       PR0F83             ;
;-------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR10D8:  CALL      PR110C             ;
         RST       FUN4               ;
         DB        7                  ;
         MOV       A,C                ;
         CALL      PR114A             ;
         RST       FUN4               ;
         DB        8                  ;
         LDA       D6069              ;
         CPI       006H               ;
         MVI       A,045H             ;
         JZ        B37                ;
         MVI       A,0AEH             ;
B37:     CALL      PR1104             ;
         RST       FUN4               ;
         DB        7                  ;
         RST       FUN4               ;
         DB        5                  ;
         PUSH      B                  ;
         PUSH      D                  ;
         PUSH      H                  ;
         CALL      PR031F             ;
         CALL      PR0347             ;
         POP       H                  ;
         POP       D                  ;
         POP       B                  ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR1102:  MVI       A,006H             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR1104:  CALL      PR01D1             ;
         DCR       A                  ;
         JNZ       PR1104             ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR110C:  MVI       A,080H             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR110E:  PUSH      PSW                ;
         CALL      PR1119             ;
         POP       PSW                ;
;--------------------------------------------------------------------
; Called from PR00AB... with A=92H
;--------------------------------------------------------------------
PR1113:  OUT       PIOACMD             ;
         STA       D606D              ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR1119:  LDA       D606B              ;
         SUI       002H               ;
         RNC                          ;
         CALL      PR1130             ;
         LDA       D606E              ;
         ORI       008H               ;
         JMP       PR0856             ;
;--------------------------------------------------------------------
; select key/led row/digit, write to mem which was selected 
;   only called from PR00AB, why not inline there? 
;   JMP above, RET below, no other way to get here...?
;--------------------------------------------------------------------
PR112A:  OUT       PDKSELB             ;
         STA       D606C              ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR1130:  CALL      PR113B             ;
         RST       FUN4               ;
         DB        2                  ;
         CALL      PR113D             ;
         JMP       PR0F83             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR113B:  RST       FUN4               ;
         DB        1                  ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR113D:  MVI        A,001H            ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR113F:  PUSH      PSW                ;
         XRA       A                  ;
         CALL      PR1104             ;
         POP       PSW                ;
         DCR       A                  ;
         JNZ       PR113F             ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR114A:  OUT       PEPRDAT             ;
         MOV       A,E                ;
         OUT       PEPRADR             ;
         MOV       A,D                ;
         ANI       01FH               ;
         MOV       D,A                ;
         LDA       D606F              ;
         ANI       0E0H               ;
         ORA       D                  ;
         OUT       PEPRAD2             ;
         STA       D606F              ;
         RET                          ;
;--------------------------------------------------------------------
; setup stuff, only called from START 2 (and in command Mode upon detecting FFH? see CMDMAP)
;--------------------------------------------------------------------
PR115F:  LXI       SP,STK             ;
         MVI       A,003H             ;
         CALL      PR0197             ;
         MVI       A,012H             ;
         STA       D6040              ;
         RST       FUN7               ;
         CALL      PR1173             ;
         JMP       PR115F             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR1173:  JC        START3             ;
         CPI       006H               ;
         JNC       PR0181             ;
         STA       D6041              ;
         MOV       E,A                ;
         CALL      PR0DD4             ;
         MVI       D,000H             ;
         LXI       H,A118E            ;
         DAD       D                  ;
         DAD       D                  ;
         MOV       E,M                ;
         INX       H                  ;
         MOV       D,M                ;
         PUSH      D                  ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------        
A118E:   DW        PR119A             ;
         DW        PR11C9             ;
         DW        PR11D5             ;
         DW        PR11E6             ;
         DW        PR11F0             ;
         DW        PR120B             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR119A:  MVI       A,004H             ;
         STA       D6067              ;
         LXI       H,D6048            ;
         MVI       M,001H             ;
         INX       H                  ;
         MVI       B,007H             ;
         XRA       A                  ;
         CALL      PR00E7             ; ? Fill M to M+B with A
B38:     CALL      PR02F0             ;
         CALL      PR010D             ;
         RC                           ;
         CNZ       RST7             ;
         RC                           ;
         LXI       H,D6048            ;
         MVI       B,008H             ;
B39:     MOV       A,M                ;
         RAL                          ;
         MOV       M,A                ;
         INX       H                  ;
         DCR       B                  ;
         JNZ       B39                ;
         JNC       B38                ;
         JMP       PR119A             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------    
PR11C9:  MVI       B,010H             ;
B40:     RST       FUN7               ;
         CMP       B                  ;
         RZ                           ;
         MOV       B,A                ;
         CALL      PR0747             ;
         JMP       B40                ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR11D5:  EI                           ;
         RST       FUN7               ;
         CALL      PR0641             ;
         RC                           ;
         RNZ                          ;
         MOV       A,L                ;
         CALL      PR020B             ;
         CALL      PR1102             ;
         JMP       PR11D5             ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR11E6:  RST       FUN3               ;
         EI                           ;
         CALL      PR0747             ;
         RST       FUN7               ;
         JNC       PR11E6             ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR11F0:  LDA       SETSTA              ;
         ANI       080H               ;
         JZ        PR0181             ;
         LXI       H,K8080            ;
         LXI       D,D6080            ;
         PUSH      D                  ;
         MVI       B,128              ;
B41:     RST       RSTGET             ;
         STAX      D                  ;
         INX       H                  ;
         INX       D                  ;
         DCR       B                  ;
         JNZ       B41                ;
         RET                          ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------        
         RST       FUN7               ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
PR120B:  LDA       SETSTA              ;
         ANI       080H               ;
         JZ        PR0181             ;
         CALL      PR0615             ;
         RC                           ;
         PCHL                         ;
;--------------------------------------------------------------------
;
;--------------------------------------------------------------------
K0800    EQU       00800H
K1000    EQU       01000H
K1010    EQU       01010H
K1090    EQU       01090H
K8000    EQU       08000H
K8080    EQU       08080H
K9010    EQU       09010H
         END
