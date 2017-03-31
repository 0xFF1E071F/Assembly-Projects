;----------------------------------------------------------------------------------------------
;
;   Program:   dcomp (MASM version)
;
;   Author:    Xiaohui Z Ellis
;
;   Function:  Dcomp decompresses ASCII text.
;
;   Input:
;   - si points to the string of compressed data
;   - di points to the empty list into which the decompressed data is stored
;
;   Output:
;
;   - The compressed data is decompressed into output list
;   - The compressed data is not modified
;   - All registers contain their original value except ax
;     ax = 1...n = size of decompressed data
;
;   Date:      Changes
;   ---------- -------
;   04/13/2016 Basic shell created
;   10/17/2016 Original Version
;
;----------------------------------------------------------------------------------------------


;---------------------------------------
         .model    small               ; 64k code and 64k data
         .8086                         ; only allow 8086 instructions
         public    dcomp               ; allow linker to access  dcomp
         public    getbit              ; allow linker to access  getbit
;---------------------------------------


;---------------------------------------
         .data                         ; start the data segment
;---------------------------------------
; t0xx, t10xxxxx and t11xxxx are lookup
; tables for decoding the compressed
; characters. Each compressed bit code
; value must fall into one of these
; three groups: 0xx, 10xxxxx and 11xxxx.
;
; t0xx is a table with 4 entries
; (0 to 3). It is lookup table for
; group 0xx.
; t10xxxxx is a table with 87 entries
; (0 to 86). It is look up table for
; group 10xxxxx.
; t11xxxx is a table with 64 entries
; (0 to 63). It is look up table for
; group 11xxxx.
;
; Compressed bits code value for each
; compressed characters are used as an
; index into the table to pick up the
; ASCII value.
;---------------------------------------
t0xx     db   ' ETA'                   ; Space, E, T, A
t10xxxxx db   64 dup ('*')             ; B is 64 offset into the table
         db   'BCDFGHIJKLMNOPQRSUVWXYZ'; all other upper case letters
t11xxxx  db   49 dup ('*')             ; 1 is 48 offset into the table
         db   '1234567890'             ; 10 digits
         db   '.'                      ; period
         db   0Dh                      ; CR
         db   0Ah                      ; LF
         db   '*'                      ; EOF is 63 offset into the table
         db   1Ah                      ; EOF
;---------------------------------------
         .code                         ; start the code segment
;---------------------------------------
; Subroutine dcomp scans the input
; compressed data, one bit at a time.
; It places the corresponding
; decompressed 8-bit ASCII character
; into the output buffer.
; It continues until it locates and
; decompressed and stores the EOF
; character in the output buffer.
; It then returns.
; A return code will be passed back in
; ax that is the length, in bytes, of
; the decompressed data string.
;---------------------------------------
dcomp:                                 ; the entry point of subroutine dcomp
         push      si                  ; save register si
         push      di                  ; save register di
         push      dx                  ; save register dx
         push      bx                  ; save register bx
         mov       dx,0                ; set dx to 0
first:                                 ; start process compressed character
         mov       bx,0                ; bx is the offset into the lookup table, set bx to 0
         call      getbit              ; get the first bit of compressed character
         cmp       bx,0                ; if the first bit is 0
         jne       second              ; no, go process second
         call      getbit              ; yes, the character is in group 0xx, get the second bit
         call      getbit              ; get the third bit
         mov       al,[bx+t0xx]        ; store decompressed character in al
         mov       [di],al             ; move decompressed character to output list pointed by di
         inc       di                  ; increment di
         jmp       first               ; go process next compressed character
second:                                ; the character is in group 10xxxxx or 11xxxx
         call      getbit              ; get the second bit
         mov       ax,bx               ; set ax to bx
         and       ax,1                ; set ax to the second bit just got
         cmp       ax,0                ; if the second bit is 0
         jne       third               ; no, go process third
         call      getbit              ; yes, the character is in group 10xxxxx, get the third bit
         call      getbit              ; get the fourth bit
         call      getbit              ; get the fifth bit
         call      getbit              ; get the sixth bit
         call      getbit              ; get the seventh bit
         mov       al,[bx+t10xxxxx]    ; store decompressed character in al
         mov       [di],al             ; move decompressed character to output list pointed by di
         inc       di                  ; increment di
         jmp       first               ; go process next compressed character
third:                                 ; the character is in group 11xxxx
         call      getbit              ; get the third bit
         call      getbit              ; get the fourth bit
         call      getbit              ; get the fifth bit
         call      getbit              ; get the sixth bit
         mov       al,[bx+t11xxxx]     ; store decompressed character in al
         mov       [di],al             ; move decompressed character to output list pointed by di
         inc       di                  ; increment di
         cmp       al,1Ah              ; if decompressed character is EOF character
         jne       first               ; no, go process next compressed character
exit:                                  ; yes
         mov       ax,di               ; set ax to the value in di
         pop       bx                  ; restore register bx
         pop       dx                  ; restore register dx
         pop       di                  ; restore register di
         pop       si                  ; restore register si
         sub       ax,di               ; ax is the length, in bytes, of decompressed data string
         ret                           ; return
;---------------------------------------


;---------------------------------------
; Subroutine getbit returns the next bit
; in the input stream in the last bit of
; bx. Getbit uses two variables stored
; in the dh and dl:
; - dh (number of bits available in
; current compressed data byte)
; - dl (the current byte of compressed
; input data)
;---------------------------------------
         .data                         ; start the data segment
;---------------------------------------


;---------------------------------------
         .code                         ; start the code segment
;---------------------------------------
; If there are no bits available in the
; current data byte, then get the next
; data byte, and store it in dl.
; Else shift left the current input data
; byte (dl) by 1. The carry flag is set
; to the bit shifted out of the current
; byte. Set the last bit of bx to that
; bit. It then returns the bit in the
; last bit of bx.
;---------------------------------------
getbit:                                ; the entry point of subroutine getbit
         cmp       dh,0                ; if no bits are available in the current data byte
         jne       more                ; no, go process more
         mov       dl,[si]             ; yes, get the next data byte, and store it in dl
         mov       dh,8                ; there are now 8 bits available, set dh to 8
         inc       si                  ; increment si
more:                                  ;
         sal       bx,1                ; shift bx left 1 bit
         sal       dl,1                ; shift dl left 1 bit, get the next bit
         adc       bx,0                ; the last bit of bx is the next bit
         dec       dh                  ; decrement dh, the available bits in current data byte
         ret                           ; return
;---------------------------------------
         end                           ;

