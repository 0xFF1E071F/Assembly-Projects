;--------------------------------------------------------------------
;   Program:  KEY (MASM version)
;
;   Function: This program will read printable characters (20h-7Fh)
;             from the standard input. This can be the keyboard or
;             a redirected ASCII text file.
;
;             It allows the software to examine each character until
;             it finds a '.' (period character (2Eh)).
;
;             The characters are processed one at a time, immediately,
;             as they are read. If the character is an upper case letter
;             (A-Z), the character is then written to the standard output.
;             If the character is a lowercase letter (a-z), the character
;             is then converted to the upper case letter and written to
;             the standard output. If the character is a ' ' (blank
;             character (20h)) or a '.' (period character (2Eh)), the
;             character is then written to the standard output. If the
;             character is anything else, the character is not written to
;             the standard output.
;
;             The program terminates when the character that has been
;             processed is a '.' (period character (2Eh)).
;
;   Notes:    The program only handles the printable characters in the
;             range of 20h-7Fh. And the input must have the terminating
;             period (2Eh) character ('.').
;
;   Owner:    Xiaohui Z Ellis
;
;   Date:     Changes
;   09/13/16  Original Version
;   09/17/16  New Version to Improve Efficiency
;
;---------------------------------------
         .model    small               ; 64k code and 64k data
         .8086                         ; only allow 8086 instructions
         .stack    256                 ; reserve 256 bytes for the stack
;---------------------------------------


;---------------------------------------
         .data                         ; start the data segment
;---------------------------------------
; The program ends when the last
; character processed matches
; variable endc.
;---------------------------------------
endc  db  '.'                          ; termination character ('.')
;---------------------------------------
; tran is a table with 256 entries (0 to 255).
;---------------------------------------
tran  db  32  dup ('*')                ; the 32 chars below ' '
      db  ' '                          ; whitespace character (' ')
      db  13  dup ('*')                ; the 13 chars between ' ' and '.'
      db  '.'                          ; period character ('.')
      db  18  dup ('*')                ; the 18 chars between '.' and 'A'
      db  'ABCDEFGHIJKLMNOPQRSTUVWXYZ' ; A-Z in uppercase
      db  6   dup ('*')                ; the 6 chars between 'Z' and 'a'
      db  'ABCDEFGHIJKLMNOPQRSTUVWXYZ' ; a-z in lowercase
      db  133 dup ('*')                ; the 133 chars above 'z'
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
; Read one character at a time,
; and use xlat to translate the character.
;  - If the character read is lower case
;    letter (a-z), then it is converted to
;    upper case, and written out to the
;    standard output.
;  - If the character read is upper case
;    letter (A-Z) or blank (' '), then it
;    is not changed, and written out to the
;    standard output.
;  - If the character read is anything else,
;    then it is converted to '*', but not
;    written out to the standard output.
;  - If the character read is period character
;    ('.'), then it is not changed, and written
;    out to the standard output. And then
;    the program is done.
;---------------------------------------
initialize_:
         mov       bx, offset tran     ; bx points to the table
repeat_:                               ;
         mov       ah,8                ; code to read without echo
         int       21h                 ; read a character, al=char
         xlat                          ; translate the char
         mov       dl,al               ; save char in dl
         cmp       dl,'*'              ; is dl == '*'
         je        repeat_             ; yes, repeat the process
         mov       ah,2                ; no, code to write character
         int       21h                 ; write the character
         cmp       dl,endc             ; is dl == '.'
         jne       repeat_             ; no, repeat the process
;---------------------------------------
; When the terminating character has
; been processed, return to DOS.
;---------------------------------------
exit:                                  ; yes, the terminating period is processed
         mov       ax,4c00h            ; set correct exit code in ax
         int       21h                 ; int 21 will terminate program
         end       start               ; execution begins at the label start 
;---------------------------------------
