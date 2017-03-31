;-------------------------------------------------------------------------------
;   Program:  linkhll (MASM version)
;
;   Function: find the two largest unsigned values and multiply them,
;             creating a 32 bit unsigned product.
;             That 32 bit product will be returned in the dx:ax register pair.
;
;   Input:    the C/C++ calling sequence is: linkhll (v1, v2, v3, v4),
;             where v1 - v4 are unsigned 16 bit values,
;             the inputs are taken from the stack (these are passed by value).
;
;   Output:   the return value will be the dx:ax pair,
;             which will contain the 32 bit unsigned product of
;             the two largest values of v1, v2, v3, v4.
;
;   Owner:    Xiaohui Z Ellis
;
;   Date:     Changes
;   10/05/16  Original Version
;
;---------------------------------------
         .model    small               ; 64k code and 64k data
         .8086                         ; only allow 8086 instructions
         public    _linkhll            ; allow external programs to call
;---------------------------------------


;---------------------------------------
         .data                         ; start the data segment
;---------------------------------------


;---------------------------------------
         .code                         ; start the code segment
;---------------------------------------
; Save modified registers.
; Find the two largest unsigned values,
; and store them in the ax register and
; bx register.
;---------------------------------------
_linkhll:                              ;
         push      bp                  ; save caller's bp register
         mov       bp,sp               ; init bp so we can get the arguments
         mov       ax,[bp+4]           ; get v1 into ax
         mov       bx,[bp+6]           ; get v2 into bx
         cmp       ax,bx               ; is ax > bx
         ja        third               ; yes, go process third
         xchg      ax,bx               ; no, the values of ax and bx are swapped
third:                                 ;
         mov       cx,[bp+8]           ; get v3 into cx
         cmp       bx,cx               ; is bx > cx
         ja        fourth              ; yes, go process fourth
         xchg      bx,cx               ; no, the values of bx and cx are swapped
         cmp       ax,bx               ; is ax > bx
         ja        fourth              ; yes, go process fourth
         xchg      ax,bx               ; no, the values of ax and bx are swapped
fourth:                                ;
         cmp       bx,[bp+10]          ; is bx > v4
         ja        calc                ; yes, go process calc
         mov       bx,[bp+10]          ; no, get v4 into bx
;---------------------------------------
; Multiply two largest values of passed
; four unsigned words on the stack.
; Ruturn the product in the dx:ax pair.
;---------------------------------------
calc:                                  ;
         mul       bx                  ; multiply two largest values (ax and bx)
                                       ; store the result in the dx:ax pair
;---------------------------------------
; Restore modified registers and return.
;---------------------------------------
         pop       bp                  ; restore bp register
         ret                           ; return
;---------------------------------------
         end                           ;

