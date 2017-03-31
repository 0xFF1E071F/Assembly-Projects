;---------------------------------------------------------------------------------------------------
; Program:   nextval subroutine (MASM version)
;
; Function:  Find next mouse move in an array 15 by 30.
;            We can move into a position if its contents is blank (20h).
;
; Input:     Calling sequence is:
;            x    pointer   si
;            y    pointer   di
;            dir  pointer   bx
;            maze pointer   bp
;
; Output:    x,y,dir modified in caller's data segment
;
; Owner:     Xiaohui Z Ellis
;
; Date:      Changes
; 10/03/2016 Original Version
; 10/04/2016 New Version to Improve Efficiency
; 10/05/2016 New Version to Improve Efficiency
;
;--------------------------------------------
         .model    small                    ; 64k code and 64k data
         .8086                              ; only allow 8086 instructions
         public    nextval                  ; allow external programs to call
;--------------------------------------------


;--------------------------------------------
         .data                              ; start the data segment
;--------------------------------------------
; cols is the number of columns of the maze
;--------------------------------------------
cols     db        30                       ; number of columns in the maze
;--------------------------------------------


;--------------------------------------------
         .code                              ; start the code segment
;--------------------------------------------
; Save modified registers.
; Calculate the offset of current location
; into the maze. offset = 30*y+x-31
; Use the dir value to locate corresponding
; routine and jump to it.
; If dir == 1, jump to testn.
; If dir == 2, jump to teste.
; If dir == 3, jump to tests.
; If dir == 4, jump to testw.
;--------------------------------------------
nextval:                                    ; the entry point of subroutine
         push      bp                       ; save register bp
         push      ax                       ; save register ax
         mov       al,[di]                  ; store the y value in al
         mul       cols                     ; multiply the y value by 30, ax = 30*y
         add       bp,ax                    ; add the value 30*y in ax to bp, bp = bp+30*y
         mov       ah,0                     ; clear ah register
         mov       al,[si]                  ; store the x value in al
         add       bp,ax                    ; add the value x in ax to bp, bp = bp+x
         sub       bp,31                    ; bp = bp-31, bp is address of current location
         cmp       byte ptr [bx],1          ; is dir == 1
         je        testn                    ; yes, go process testn
         cmp       byte ptr [bx],2          ; no, is dir == 2
         je        teste                    ; yes, go process teste
         cmp       byte ptr [bx],3          ; no, is dir == 3
         je        tests                    ; yes, go process tests
                                            ; no, go process testw
;--------------------------------------------
; Make 1 move in the maze.
; Set the x and y values in the caller's data
; segment to the next location to which mouse
; is going to move.
; Set the direction (dir) in the caller's
; data segment to the new direction of
; travel.
;--------------------------------------------
testw:                                      ; if dir == 4, try to move west first
         cmp       byte ptr ds:[bp-1],20h   ; is west location blank (20h)
         jne       testn                    ; no, try to move north, go process testn
         dec       byte ptr [si]            ; yes, decrement x
         mov       byte ptr [bx],3          ; set dir to the value 3
         jmp       exit                     ; go process exit
testn:                                      ; if dir == 1, try to move north first
         cmp       byte ptr ds:[bp-30],20h  ; is north location blank (20h)
         jne       teste                    ; no, try to move east, go process teste
         dec       byte ptr [di]            ; yes, decrement y
         mov       byte ptr [bx],4          ; set dir to the value 4
         jmp       exit                     ; go process exit
tests:                                      ; if dir == 3, try to move south first
         cmp       byte ptr ds:[bp+30],20h  ; is south location blank (20h)
         jne       testw                    ; no, try to move west, go process testw
         inc       byte ptr [di]            ; yes, increment y
         mov       byte ptr [bx],2          ; set dir to the value 2
         jmp       exit                     ; go process exit
teste:                                      ; if dir == 2, try to move east first
         cmp       byte ptr ds:[bp+1],20h   ; is east location blank (20h)
         jne       tests                    ; no, try to move south, go process tests
         inc       byte ptr [si]            ; yes, increment x
         mov       byte ptr [bx],1          ; set dir to the value 1
;--------------------------------------------
; Restore modified registers and return.
;--------------------------------------------
exit:                                       ;
         pop       ax                       ; restore register ax
         pop       bp                       ; restore register bp
         ret                                ; return
;--------------------------------------------
         end                                ;

