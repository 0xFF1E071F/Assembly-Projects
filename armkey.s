;---------------------------------------------------------------------------------------------------
; File:     armkey.s
;
; Function: The program uses ARM Software Interrupts (SWI) to access ASCII files.
;           - It opens an input  file named key.in
;           - It opens an output file named key.out
;           - It reads a line of ASCII text with printable characters and
;             control characters (00h-7Fh) from the file key.in into an input string.
;             The read string ARM SWI will remove any end of line indication or characters
;             and replace them with a single binary 0. If there are no more lines the read
;             string ARM SWI will return a count of zero for the number of bytes read.
;           - It processes the characters in that line.
;             For each character the program performs the following:
;             • If the character is an upper case letter (A-Z)
;               then move it to the output string.
;             • If the character is a lower case letter (a-z)
;               then convert it to upper case and move it to the output string.
;             • If the character is a blank (20h) then move it to the output string.
;             • If the character is a hex zero (00h) then move it to the output string.
;               This also signifies the end of the input string.
;             • If the character is anything else then do not move it to the output string,
;               it just throw the character away. This includes any control characters in the range
;               of 01-1Fh including the DOS end of file character 1Ah.
;           - It writes the output string and a carriage return and line feed to the output file,
;             after processing all characters on the input line.
;           - It continues to read and process input lines until the read string
;             ARM Software Interrupt returns a count of zero for the number of bytes read
;             which is the an end of file indication.
;           - It closes the input and output file and halts.
;
; Author:   Xiaohui Ellis
;
; Changes:  Date        Reason
;           ----------------------------
;           10/20/2016  Original version
;
;---------------------------------------------------------------------------------------------------


;---------------------------------------
; Software Interrupt values
;---------------------------------------
         .equ      SWI_Open,0x66       ; open a file
         .equ      SWI_Close,0x68      ; close a file
         .equ      SWI_PrStr,0x69      ; write a null-ending string
         .equ      SWI_RdStr,0x6a      ; read a string and terminate with null char
         .equ      SWI_Exit,0x11       ; stop execution
;---------------------------------------

         .global   _start
         .text

_start:
;---------------------------------------
; Open output file
; - r0 points to the file name
; - r1 1 for output
; - the open swi is 66h
; - after the open r0 will have the file handle
;---------------------------------------
         ldr       r0,=OutFileName     ; r0 points to the file name
         ldr       r1,=1               ; r1 = 1 specifies the file is output
         swi       SWI_Open            ; open the file, r0 will be the file handle
         ldr       r4,=OutFileHandle   ; r4 points to handle location
         str       r0,[r4]             ; store the file handle
;---------------------------------------


;---------------------------------------
; Open input file
; - r0 points to the file name
; - r1 0 for input
; - the open swi is 66h
; - after the open r0 will have the file handle
;---------------------------------------
         ldr       r0,=InFileName      ; r0 points to the file name
         ldr       r1,=0               ; r1 = 0 specifies the file is input
         swi       SWI_Open            ; open the file, r0 will be the file handle
         ldr       r5,=InFileHandle    ; r5 points to handle location
         str       r0,[r5]             ; store the file handle
;---------------------------------------


;---------------------------------------
; Read a line from the input file
; - r0 contains the file handle
; - r1 points to the input string buffer
; - r2 contains the max number of characters to read
; - the read swi is 6ah
; - the input string will be terminated with 0
;---------------------------------------
_read:                                 ;
         ldr       r0,[r5]             ; r0 has the input file handle
         ldr       r1,=InString        ; r1 points to the input string
         ldr       r2,=80              ; r2 has the max size of the input string
         swi       SWI_RdStr           ; read a string from the input file
         cmp       r0,#0               ; no characters read means EOF
         beq       _exit               ; so close and exit
;---------------------------------------


;---------------------------------------
; Move the input string to the output string
;---------------------------------------
         ldr       r0,=OutString       ; r0 points to the output string
         ldr       r3,=Tran            ; r3 points to the look up table
_loop:                                 ;
         ldrb      r2,[r1],#1          ; get the next input byte
                                       ; then increment the input pointer
         ldrb      r2,[r3,r2]          ; get the value pointed by r3+r2
         cmp       r2,#42              ; was it 42 ('*')
         beq       _loop               ; yes, go process loop
         strb      r2,[r0],#1          ; no, store it in the output buffer
                                       ; then increment the output pointer
         cmp       r2,#0               ; was it the null terminator
         bne       _loop               ; no, go process loop
;---------------------------------------


;---------------------------------------
; Write the output string
;---------------------------------------
_write:                                ; yes, write the output string
         ldr       r0,[r4]             ; r0 has the output file handle
         ldr       r1,=OutString       ; r1 points to the output string
         swi       SWI_PrStr           ; write the null terminated string
         ldr       r1,=CRLF            ; r1 points to the CRLF string
         swi       SWI_PrStr           ; write the null terminated string
         bal       _read               ; read the next line
;---------------------------------------


;---------------------------------------
; Close input and output files
; Terminate the program
;---------------------------------------
_exit:                                 ;
         ldr       r0,[r5]             ; r0 has the input file handle
         swi       SWI_Close           ; close the file
         ldr       r0,[r4]             ; r0 has the output file handle
         swi       SWI_Close           ; close the file
         swi       SWI_Exit            ; terminate the program
;---------------------------------------


         .data
;---------------------------------------
; Tran is a look up table.
;---------------------------------------
Tran:         .byte 0                  ; character 00 (null)
              .byte 42                 ; character 01 is set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 02-06 are all set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 07-11 are all set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 12-16 are all set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 17-21 are all set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 22-26 are all set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 27-31 are all set to 42 ('*')
              .byte 32                 ; character 32 (space)
              .byte 42,42              ; characters 33-34 are all set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 35-39 are all set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 40-44 are all set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 45-49 are all set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 50-54 are all set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 55-59 are all set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 60-64 are all set to 42 ('*')
              .byte 65                 ; upper case letter (A)
              .byte 66,67,68,69,70     ; upper case letters (B-F)
              .byte 71,72,73,74,75     ; upper case letters (G-K)
              .byte 76,77,78,79,80     ; upper case letters (L-P)
              .byte 81,82,83,84,85     ; upper case letters (Q-U)
              .byte 86,87,88,89,90     ; upper case letters (V-Z)
              .byte 42                 ; character 91 is set to 42 ('*')
              .byte 42,42,42,42,42     ; characters 92-96 are all set to 42 ('*')
              .byte 65                 ; lower case letter (a) is converted to upper case (A)
              .byte 66,67,68,69,70     ; lower case letters (b-f) are converted to upper case (B-F)
              .byte 71,72,73,74,75     ; lower case letters (g-k) are converted to upper case (G-K)
              .byte 76,77,78,79,80     ; lower case letters (l-p) are converted to upper case (L-P)
              .byte 81,82,83,84,85     ; lower case letters (q-u) are converted to upper case (Q-U)
              .byte 86,87,88,89,90     ; lower case letters (v-z) are converted to upper case (V-Z)
              .byte 42,42,42,42,42     ; characters 123-127 are all set to 42 ('*')
InFileHandle: .skip 4                  ; 4 byte field to hold the input  file handle
OutFileHandle:.skip 4                  ; 4 byte field to hold the output file handle
OutFileName:  .asciz "KEY.OUT"         ; output file name, null terminated
CRLF:         .byte 13, 10, 0          ; CR LF
InFileName:   .asciz "KEY.IN"          ; input file name, null terminated
InString:     .skip 80                 ; reserve a 80 byte string for input
OutString:    .skip 80                 ; reserve a 80 byte string for output
;---------------------------------------


         .end
