.section .text

.global main
main:
    LDR r0, =string1
    BL string_length            @ will return with r0 as the string's length
    PUSH {r0}                   @ store len
    LDR r1, =buffer             @ load up r1 with the address of the buffer
    BL num_to_asciz             @ will leave buffer with the ASCIZ form of the number
    LDR r1, =buffer             @ load buffer address
    POP {r0}                    @ load the stored len
    MOV r2, r0                  @ move len to r2 where print expects it
    BL print
    LDR r1, =newline
    MOV r2, #1
    BL print
    B exit

@ r0 should hold the string address
.global string_length
string_length:
    MOV r1, #0x0
    PUSH {lr}                   @ save lr

string_loop:
    LDRB r2, [r0, r1]           @ load character into r2
    CMP r2, #0x00               @ is the char \0?
    ADD r1, r1, #0x1            @ increment counter, it now shows number of addrs checked
    BEQ string_end              @ return back to string_length because we've reached \0
    B string_loop               @ else recurse

string_end:
    MOV r0, r1                  @ pass r1 into r0 to return
    POP {lr}
    BX lr 

@ r1 should hold string address
@ r2 should hold number of characters to print
print:
    MOV r7, #0x04               @ write
    MOV r0, #0x01               @ stdout
    SVC 0
    MOV pc, lr

@ r0 should hold number
@ r1 should hold the address of the buffer
num_to_asciz:
    MOV r2, #0xA                @ 10 in dec, divisor
    @MOV r3, #0                 @ digit counter
    @ADD r1, r1, #0xB           @ move pointer to end of buffer (buff+11)
    MOV r5, #0
    STRB r5, [r1]
    PUSH {lr}
    BL num_to_asciz_loop
    POP {lr}
    BX lr

num_to_asciz_loop:
    PUSH {r0, r2, lr}
    BL div                      @ r4 = r0 / 10
    POP {r0, r2, lr}
    MUL r5, r4, r2              @ r5 = (r0 / 10) * 10
    SUB r5, r0, r5              @ r5 = LSD of r0

    ADD r5, r5, #48             @ convert to ASCII ('0' = 48)
    STRB r5, [r1]               @ store the character in the buffer
    SUB r1, r1, #0x1            @ move the pointer back one

    MOV r0, r4                  @ update value of r0
    CMP r0, #0x0                @ is r0 null?
    BNE num_to_asciz_loop       @ if not, recurse

    ADD r1, r1, #1              @ move r1 to start of num
    MOV pc, lr                  @ else, return

@ divide r0 by r2, result in r4
div:
    MOV r4, #0
    PUSH {lr}
    BL div_loop
    POP {lr}
    BX lr

div_loop:
    CMP r0, r2
    MOVLT pc, lr
    SUB r0, r0, r2
    ADD r4, r4, #1
    B div_loop

exit:
    MOV r7, #0x1
    MOV r0, #0x0
    SVC 0

.section .data
.balign 4
string1:    .asciz "Darcy\n"
buffer:     .space 12
newline:    .asciz "\n"
