;------------------------------------------------------------------------------
;   Program:  EXPR (MASM version)
;
;   Function: This program will read lines of a high level language expression
;             and determins the validity of the expression on each line.
;
;             This program will be able to recognize these elements: active
;             elements and passive elements.
;
;             The active elements are those that would affect the value of the
;             expression, including variable/operand (1 uppercase letter) and
;             operator ('+', '-', or '=').
;
;             The passive elements are those that would not affect the value of
;             the expression, including white space (20h) and end-of-line
;             sequence CR/LF (carriage return (0Dh) and line feed (0Ah)).
;
;             An expression is valid if it conforms to the rules below. All
;             elements are optional except the end-of-line sequence. Valid
;             expressions have this format:
;             [WH] [OPERAND] [WH OPERATOR WH OPERAND] [WH] CR/LF
;
;             Language Rules:
;             - A line may optionally start with white space.
;             - The first active element on a line must be an operand.
;             - Active elements must alternate as follows: operand, operator,
;               operand, operator, operand, etc.
;             - There must be white space between adjacent operands and
;               operators.
;             - The last active element on a line must be an operand.
;             - The last operand on a line may be followed by white space.
;             - All lines will end with CR/LF. White space preceding the CR/LF
;               is optional.
;             - All the rules given in the description of the active and
;               passive elements must be met.
;
;             For each input line, this program will start at the beginning of
;             a line and read and echo each character, one character at a time,
;             until it has read and echoed all characters on the line including
;             the end-of-line sequence (CR/LF). As it reads characters, it
;             verifies that the line format matches the valid format as
;             specified in the Language Rules above. It keeps track of the
;             first error that it encounters on the line. After it has read and
;             echoed the end-of-line sequence (CR/LF) that marks the end of the
;             line, it writes one of the three message shown below to indicate
;             line status. The message will be terminated with a CR/LF pair.
;             After it writes the message, it writes a null line that contains
;             only a CR/LF pair to separate test cases.
;
;             These are the three messages to indicate line status:
;             - Message One: "LINE IS VALID"
;             - Message Two: "INVALID VARIABLE"
;             - Message Three: "INVALID FORMAT"
;
;             When the input line is valid, Message One is written out to
;             indicate line status. When a valid variable is started but later
;             found to contain more than a single uppercase letter, Message Two
;             is written out to indicate line status. When any other error is
;             encountered on a line, Message Three is written out to indicate
;             line status.
;
;             This program terminates when it starts to read a new line, and
;             reads and echoes the DOS end of file character (1Ah).
;
;   Notes:    The input to your program will come from an ASCII text file that
;             is redirected to the standard input. The output from your program
;             will go to an ASCII text file that is redirected to the standard
;             output. These are rules for creating input files:
;             - Files will contain 0 or more lines. There is no limit to the
;               number of characters per line or lines per file.
;             - Data characters will all be in the range of 20h-7Fh. Characters
;               above 7Fh will not be used.
;             - ASCII control characters fall in the range of 00h-1Fh.
;               These are the only control characters that will be used:
;               Line feed (LF) = 0Ah, Carriage return (CR) = 0Dh,
;               DOS end of file (EOF) = 1Ah
;             - All lines will terminate with the DOS carriage return and line
;               feed pair (0Dh 0Ah).
;             - File termination will only occur at the beginning of a new line.
;               Files will terminate with a DOS end of file character (1Ah).
;             - The individual characters CR and LF will never appear separately
;               in the input file by themselves. They will only appear as part
;               of a CR/LF pair.
;
;   Owner:    Xiaohui Z Ellis
;
;   Date:     Changes
;   09/18/16  Original Version
;
;---------------------------------------
         .model    small               ; 64k code and 64k data
         .8086                         ; only allow 8086 instructions
         .stack    256                 ; reserve 256 bytes for the stack
;---------------------------------------


;---------------------------------------
         .data                         ; start the data segment
;---------------------------------------
; msg1, msg2, and msg3 are messages to
; indicate line status.
; tran1 and tran2 is tables with 128
; entries (0 to 127).
;---------------------------------------
msg1     db   10,'LINE IS VALID'       ; Message One to indicate that the input
         db   13,10,13,10,'$'          ; line is valid
msg2     db   10,'INVALID VARIABLE'    ; Message Two to indicate that the variable
         db   13,10,13,10,'$'          ; is not valid
msg3     db   10,'INVALID FORMAT'      ; Message Three to indicate that the format
         db   13,10,13,10,'$'          ; is not valid
tran1    db   13   dup (40h)           ; the 13 chars below 0Dh
         db   30h                      ; carriage return (0Dh)
         db   18   dup (40h)           ; the 18 chars between 0Dh and ' '
         db   10h                      ; whitespace (' ')
         db   10   dup (40h)           ; the 10 chars between ' ' and '+'
         db   20h                      ; addition ('+')
         db   40h                      ; the 1 char between '+' and '-'
         db   20h                      ; subtraction ('-')
         db   15   dup (40h)           ; the 15 chars between '-' and '='
         db   20h                      ; assignment ('=')
         db   3    dup (40h)           ; the 3 chars between '=' and 'A'
         db   26   dup (00h)           ; A-Z in uppercase
         db   37   dup (40h)           ; the 37 chars above 'Z'
tran2    db   2,2,6,5,5,5,6            ; 00h to 06h
         db   9    dup ('*')           ; 07h to 0Fh
         db   0,1,3,3,1,5,6            ; 10h to 16h
         db   9    dup ('*')           ; 17h to 1Fh
         db   5,5,6,4,5,5,6            ; 20h to 26h
         db   9    dup ('*')           ; 27h to 2Fh
         db   7,5,7,7,5,5,6            ; 30h to 36h
         db   9    dup ('*')           ; 37h to 3Fh
         db   5,5,6,5,5,5,6            ; 40h to 46h
         db   57   dup ('*')           ; 47h to 7Fh
state    db   0                        ; current state
;---------------------------------------


;---------------------------------------
         .code                         ; start the code segment
;---------------------------------------
; Establish addressability to the data
; segment.
;---------------------------------------
start:                                 ;
         mov       ax,@data            ; establish addressability to the
         mov       ds,ax               ; data segment for this program

;---------------------------------------
; For each input line, read and echo one
; character at a time until it has read
; and eachoed all characters on the line
; including  the end-of-line sequence
; (CR/LF).
; As it reads characters, it transitions
; from one state to another. Each character
; read is converted into 1 of 5 possible
; coded values using xlat and table tran1.
; Uppercase letter is converted into 00h.
; Whitespace is converted into 10h.
; Operator ('+', '-', and '=') is converted
; into 20h. Carriage return is converted
; into 30h. And others is converted into 40h.
; The sum of the coded value and current
; state is then coverted to new state
; using xlat and table tran2. State 00h is
; start of a line. State 01h is looking for
; a variable. State 02h is started a variable.
; State 03h is looking for an operator. State
; 04h is started an operator. State 05h is
; invalid format. State 06h is invalid variable.
; State 07h is line is valid.
; This program terminates when it starts
; to read a new line, and reads and echoes
; the DOS end of file character (1Ah).
;---------------------------------------
repeat_:                               ;
         mov       ah,8                ; code to read character without echo
         int       21h                 ; read a character, al=char
         mov       dl,al               ; save char in dl
         mov       bx, offset tran1    ; bx points to the table tran1
         xlat                          ; translate the char
         add       [state],al          ; add coded value to current state
         mov       al,[state]          ; save sum in al
         mov       bx, offset tran2    ; bx points to the table tran2
         xlat                          ; translate the sum to new state
         mov       [state],al          ; update current state to new state
         mov       ah,2                ; code to write character
         int       21h                 ; write the character
         cmp       dl,26               ; is dl == 1Ah
         je        exit                ; yes, the program is done
         cmp       dl,13               ; no, is dl == 0Dh
         jne       repeat_             ; no, repeat the process

;---------------------------------------
; After it has read and echoed the
; end-of-line sequence (CR/LF) that marks
; the end of the line, it writes a message
; to indicate line status. The message will
; be terminated with a CR/LF pair. After it
; writes the message, it writes a null line
; that contains only a CR/LF pair to
; separate test cases. And then the program
; goes to the label repeat_ and starts to
; process the new line.
;---------------------------------------
eol:                                   ; yes, there is one more character in line
         mov       ah,8                ; code to read character without echo
         int       21h                 ; read a character, al=char
         cmp       [state],5           ; is state == 05h
         je        invalid_f           ; yes, go process invalid_f
         cmp       [state],6           ; no, is state == 06h
         je        invalid_v           ; yes, go process invalid_v
         mov       dx, offset msg1     ; no, line is valid, dx points to msg1

write_msg:                             ;
         mov       ah,9                ; code to write string
         int       21h                 ; write the string
         mov       [state],0           ; set the current state to 00h
         jmp       repeat_             ; go process the new line

invalid_f:                             ;
         mov       dx, offset msg3     ; dx points to msg3
         jmp       write_msg           ; go process write_msg

invalid_v:                             ;
         mov       dx, offset msg2     ; dx points to msg2
         jmp       write_msg           ; go process write_msg

;---------------------------------------
; When the end of file character (1Ah) has
; been processed, return to DOS and
; terminate program.
;---------------------------------------
exit:                                  ;
         mov       ax,4c00h            ; set correct exit code in ax
         int       21h                 ; int 21 will terminate program
         end       start               ; execution begins at the label start
;---------------------------------------
