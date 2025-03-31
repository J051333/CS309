@ Constants
                    .equ SYS_EXIT, 1
                    .equ SYS_READ, 3
                    .equ SYS_WRITE, 4
                    .equ STDIN, 0
                    .equ STDOUT, 1

                    .equ INPUT_BUFFER_SIZE, 12

.section .data
prompt:             .asciz "Enter an integer between 1 and 100: "
even_msg:           .asciz "The even numbers from 1 to "
odd_msg:            .asciz "The odd numbers from 1 to "
newline:            .asciz "\n"
invalid_num_msg:    .asciz "Sorry, that's not a valid number.\n"
even_sum_msg:       .asciz "The even sum is "
odd_sum_msg:        .asciz "The odd sum is "

.section .bss
.lcomm user_input, INPUT_BUFFER_SIZE @ Reserve 4 bytes for input
.lcomm counter, 4
.lcomm odd_sum, 4
.lcomm even_summ, 4

.section .text
.global main

main:
    @ Prologue
    PUSH {ip, lr} @ Push lr and ip to keep the stack 8b aligned

    @ Get input
    LDR r0, =prompt
    BL print_string @ Print the prompt
    BL read @ Read 4 bytes input into user_input

    @ Convert input to int
    LDR r0, =user_input @ Load the buffer into r0
    BL atoi

    @ Validate input
    PUSH {r0, ip} @ Save r0
    BL validate_int
    CMP r0, #0
    BEQ exit_err
    POP {r0, ip} @ Restore r0

    @ Print what was entered
    
    

    B exit

@ Ensure an integer falls between 1 and 100
@ Input: r0 = Integer to validate
@ Output: r0 = (0 or 1) if valid
validate_int:
    PUSH {r1, ip}

    MOV r1, #1 @ Default the validation to true

    CMP r0, #1
    MOVLT r1, #0 @ If less than 1, invalidate
    CMP r0, #100
    MOVGT r1, #0 @ If greater than 100, invalidate

    MOV r0, r1
    POP {r1, ip}

    @ Return
    BX lr

@ Reads an int into user_input with a null byte in the last slot
read:
    MOV r7, #SYS_READ
    MOV r0, #0
    LDR r1, =user_input @ load the section
    MOV r2, #INPUT_BUFFER_SIZE @ How many bytes to read
    SUB r2, r2, #1 @ Read one less so we have room for a null byte
    SVC 0

    ADD r2, r2, #1
    MOV r0, #0 @ Don't need val in r0
    STRB r0, [r1, r2]@ Store null byte in last byte

    BX lr @ Return

@ Converts a string into an int
@ Input: r0 = pointer to null-term string
@ Output r0 = 4 byte int value, 0 if not an int
atoi:
    PUSH {r1-r4, lr}@ Save registers we're using
    MOV r1, r0 @ Copy string ptr to r1
    MOV r0, #0 @ Init int to 0
    MOV r2, #10 @ multiply by 10 for advancing digits base 10
    MOV r3, #0 @ Default sign flag is pos

    @ Check for sign ('-')
    LDRB r4, [r1], #1 @ Load first byte
    CMP r4, #'-'
    MOVEQ r3, #1 @ Set negative flag
    LDREQB r4, [r1], #1 @ Load next byte if '-'

@ Loop portion of the atoi function
atoi_loop:
    @ Is char a digit?
    CMP r4, #'0'
    BLT atoi_done
    CMP r4, #'9'
    BGT atoi_done

    @ Multiply current total by 10
    MUL r0, r0, r2

    @ Convert ASCII to numeric
    SUB r4, r4, #'0' @ Subtract the value of 0 from the byte
    ADD r0, r0, r4 @ Add the numeric value to the total

    @ Load next
    LDRB r4, [r1], #1
    B atoi_loop

@ Final checks of atoi before it returns
atoi_done:
    @ Check if valid final byte
    CMP r4, #'\n'
    BEQ atoi_return
    CMP r4, #'\0'
    BEQ atoi_return

    @ If we're here, invalid terminator
    MOV r0, #0 @ Invalidate the total

@ Returns the int
atoi_return:
    @ Handle negative number
    @ (should be invalid in this program but handle that later)
    CMP r3, #1
    RSBEQ r0, r0, #0 @ Subtract from zero if negative

    @ Restore registers and return
    POP {r1-r4, lr}
    BX lr

@ String to print should be in r0
print_string:
    PUSH {r0, lr}
    BL string_length
    MOV r2, r0 @ store the number of chars in r2
    POP {r0, lr}
    MOV r1, r0 @ Move the address of the prompt into r1
    MOV r0, #1 @ stdout
    MOV r7, #SYS_WRITE @  syscall for write
    SVC #0
    BX lr

string_length:
    MOV r1, #0x0
    PUSH {lr}@ save lr

string_loop:
    LDRB r2, [r0, r1]           @ load character into r2
    CMP r2, #0x00               @ is the char \0?
    ADD r1, r1, #0x1            @ increment counter, it now shows number of addrs checked
    BEQ string_end              @ return back to string_length because we've reached \0
    B string_loop               @ else recurse

string_end:
    MOV r0, r1 @ pass r1 into r0 to return
    POP {lr}
    BX lr

exit_err:
    LDR r0, =invalid_num_msg
    BL print_string

@ Exit the program
exit:
    POP {ip, lr}

    MOV r7, #0x1
    MOV r0, #0x0
    SVC 0
