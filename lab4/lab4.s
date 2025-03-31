@ File:    lab4.s
@ Author:  Josi Whitlock
@ Purpose: Count and sum from 1 to a user-selected number.
@
@ Use these commands to assemble, link, run and debug the program
@
@  as -o lab4.o lab4.s -g
@  gcc -o lab4 lab4.o
@ ./lab4
@ gdb --args ./lab4

@ Use c's printf
.extern printf

@ Constants
                    .equ SYS_EXIT, 1
                    .equ SYS_READ, 3
                    .equ SYS_WRITE, 4
                    .equ STDIN, 0

                    .equ INPUT_BUFFER_SIZE, 12

.section .data
prompt:             .asciz "Enter an integer between 1 and 100.\n"
even_msg:           .asciz "The even numbers from 1 to %d are:\n"
odd_msg:            .asciz "The odd numbers from 1 to %d are:\n"
newline:            .asciz "\n"
invalid_num_msg:    .asciz "Sorry, that's not a valid number.\n"
number:             .asciz "%d\n"
even_sum_msg:       .asciz "The even sum is %d.\n"
odd_sum_msg:        .asciz "The odd sum is %d.\n"
you_entered_msg:    .asciz "You entered %d.\n"

.section .bss                                   @ BSS to use less storage
.lcomm user_input, INPUT_BUFFER_SIZE            @ Reserve bytes for input
.lcomm odd_sum, 4                               @ Sum of odds
.lcomm even_sum, 4                              @ Sum of evens

.section .text
.global main

@ Entry point
main:
    @ Prologue
    PUSH {ip, lr}                               @ Push lr and ip to keep the stack 8b aligned

    @ Get input
    LDR r0, =prompt                             @ Load the print into r0
    BL printf                                   @ Print the prompt
    BL read                                     @ Read into user_input

    @ Convert input to int, if invalid, it will be 0
    LDR r0, =user_input                         @ Load the buffer into r0
    BL atoi                                     @ Call atoi to convert user_input to an int
    MOV r4, r0                                  @ Store number in r4

    @ Validate input to ensure the number entered is between 1 and 100 (0 if invalid)
    BL validate_int                             @ Call validate_int 
    CMP r0, #0                                  @ Check if the output is 0 (indicating bad value)
    BEQ exit_err                                @ Exit with an error message

    @ Tell what was entered
    LDR r0, =you_entered_msg                    @ Load the you entered message
    MOV r1, r4                                  @ Move the number into r1 as an argument for printf
    BL printf                                   @ Call printf

    @ Sum evens
    LDR r0, =even_msg                           @ Load the even_msg
    MOV r1, r4                                  @ Load the number into r1 again as an arg to printf
    BL printf                                   @ Call printf

    MOV r0, r4                                  @ Load the number into r0 for processing in sum_evens
    BL sum_evens                                @ Call sum_evens

    LDR r0, =even_sum_msg                       @ Load the addr even_sum_msg into r0
    LDR r2, =even_sum                           @ load the addr of even_sum into r2
    LDR r1, [r2]                                @ Load the value of even_sum into r1 as an arg for printf
    BL printf                                   @ Call printf

    @ Sum odds
    LDR r0, =odd_msg                            @ Load the odd_msg
    MOV r1, r4                                  @ Load the same number into r1 as an arg for printf
    BL printf                                   @ Call printf

    MOV r0, r4                                  @ Move the same number into r0 for processing in sum_odds
    BL sum_odds                                 @ Call sum_odds

    LDR r0, =odd_sum_msg                        @ Load the odd_sum_msg
    LDR r2, =odd_sum                            @ Load the addr of odd_sum
    LDR r1, [r2]                                @ Load the value of odd_sum into r1 as an arg for, you guessed it, printf
    BL printf                                   @ Call printf

    B exit                                      @ Exit the program

@ Sums and prints evens
@ Input: r0 = number to sum to
@ Output: even_sum = Sum of evens
sum_evens:
    PUSH {r4, r5, r6, lr}                       @ Push registers we're going to use
    MOV r4, r0                                  @ Store the limit
    MOV r5, #1                                  @ Initialize counter to 1
    LDR r6, =even_sum                           @ Pull the addr of even_sum into r4

@ Loop portion of the sum_evens function
sum_evens_loop:
    @ Check if num is even
    AND r1, r5, #1                              @ Get the least significant bit of r1
    CMP r1, #0                                  @ Check if that bit is 0

    @ If even, print
    LDREQ r0, =number                           @ If it is 0, load the number string into r0
    MOVEQ r1, r5                                @ and move the number to print into r1
    BLEQ printf                                 @ and call printf

    @ Add to even_sum
    LDREQ r3, [r6]                              @ Get current sum of evens, if 0
    ADDEQ r3, r3, r5                            @ Add current number to sum, if 0
    STREQ r3, [r6]                              @ Update sum, if 0

    @ Check if we're at the limit
    CMP r5, r4                                  @ Compare the limit and the current count
    BGE sum_evens_end                           @ If theyre the same or we've passed it, exit the function

    @ Increment counter
    ADD r5, r5, #1                              @ Add one to the counter

    B sum_evens_loop                            @ Loop back around for the next iteration

@ End portion of the sum_evens function
sum_evens_end:
    POP {r4, r5, r6, lr}                        @ Restore the registers we used to their last state
    BX lr                                       @ Return

@ Sums and prints odds
@ Input: r0 = number to sum to
@ Output: odd_sum = Sum of odds
sum_odds:
    PUSH {r4, r5, r6, lr}                       @ Push regs we use
    MOV r4, r0                                  @ Store the limit
    MOV r5, #1                                  @ Initialize counter to 1
    LDR r6, =odd_sum                            @ Pull the addr of odd_sum into r4

@ Loop portion of the sum_odds function
sum_odds_loop:
    @ Check if num is odd
    AND r1, r5, #1                              @ Get the least significant bit of r1
    CMP r1, #1                                  @ If that is 1, its odd

    @ If odd, print
    LDREQ r0, =number                           @ If odd, load the addr of the number string into r0
    MOVEQ r1, r5                                @ and move the current count into r1
    BLEQ printf                                 @ aaand call printf

    @ Add to odd_sum
    LDREQ r3, [r6]                              @ Get current sum, if 1
    ADDEQ r3, r3, r5                            @ Add to sum, if 1
    STREQ r3, [r6]                              @ Update sum, if 1

    @ Check if we're at the limit
    CMP r5, r4                                  @ Compare count and limit
    BGE sum_odds_end                            @ We at or over limit? No? Keep going.

    @ Increment counter
    ADD r5, r5, #1                              @ Count++

    B sum_odds_loop                             @ Run the loop again

@ End portion of the sum_odds function
sum_odds_end:
    POP {r4, r5, r6, lr}                        @ Restore them registers we used
    BX lr                                       @ Return :)

@ Ensure an integer falls between 1 and 100
@ Input: r0 = Integer to validate
@ Output: r0 = (0 or 1) if valid
validate_int:
    MOV r1, #1                                  @ Default the validation to true

    CMP r0, #1                                  @ Compare the int to 0
    MOVLT r1, #0                                @ If less than 1, invalidate
    CMP r0, #100                                @ Compare the int to 100
    MOVGT r1, #0                                @ If greater than 100, invalidate

    MOV r0, r1                                  @ Move the result into r0

    @ Return
    BX lr                                       @ Return

@ Reads an int into user_input with a null byte in the last slot
read:
    MOV r7, #SYS_READ                           @ Set the syscall to SYSREAD (3)
    MOV r0, #STDIN                              @ Set the input source to STDIN (0)
    LDR r1, =user_input                         @ Load the user_input buffer
    MOV r2, #INPUT_BUFFER_SIZE                  @ How many bytes to read
    SUB r2, r2, #1                              @ Read one less so we have room for a null byte
    SVC 0                                       @ Sys call!

    ADD r2, r2, #1                              @ Add one back to the length
    MOV r0, #0                                  @ Don't need val in r0, set it to \0
    STRB r0, [r1, r2]                           @ Store null byte in last byte

    BX lr                                       @ Return

@ Converts a string into an int
@ Input: r0 = pointer to null-term string
@ Output r0 = 4 byte int value, 0 if not an int
atoi:
    PUSH {r1-r4, lr}                            @ Save registers we're using
    MOV r1, r0                                  @ Copy string ptr to r1
    MOV r0, #0                                  @ Init int to 0
    MOV r2, #10                                 @ multiply by 10 for advancing digits base 10
    MOV r3, #0                                  @ Default sign flag is pos

    @ Check for sign ('-')
    LDRB r4, [r1], #1                           @ Load first byte
    CMP r4, #'-'                                @ Compare r4 to '-'
    MOVEQ r3, #1                                @ Set negative flag if equal
    LDREQB r4, [r1], #1                         @ Load next byte if '-'

@ Loop portion of the atoi function
atoi_loop:
    @ Is char a digit?
    CMP r4, #'0'                                @ Compare char to '0'
    BLT atoi_done                               @ If less, it's not a digit
    CMP r4, #'9'                                @ Compare char to '9'
    BGT atoi_done                               @ If greater, it's not a digit

    MUL r0, r0, r2                              @ Multiply current total by 10

    @ Convert ASCII to numeric
    SUB r4, r4, #'0'                            @ Subtract the value of '0' from the byte
    ADD r0, r0, r4                              @ Add the numeric value to the total

    @ Load next
    LDRB r4, [r1], #1                           @ Load the next byte and offset++
    B atoi_loop                                 @ Loop!

@ Final checks of atoi before it returns
atoi_done:
    @ Check if valid final byte
    CMP r4, #'\n'                               @ Compare last byte to '\n'
    BEQ atoi_return                             @ If equal, valid terminator, branch to return
    CMP r4, #'\0'                               @ Compare last byte to '\0'
    BEQ atoi_return                             @ If equal, valid terminator, branch to return

    @ If we're here, invalid terminator
    MOV r0, #0                                  @ Invalidate the total because that's a bad terminator

@ Returns the int
atoi_return:
    @ Handle negative number
    @ (should be invalid in this program but)
    CMP r3, #1                                  @ Compare r3 to 1, see if it's true
    RSBEQ r0, r0, #0                            @ Subtract from zero if negative

    @ Restore registers and return
    POP {r1-r4, lr}                             @ Pop those registers back out
    BX lr                                       @ Return

exit_err:
    LDR r0, =invalid_num_msg                    @ Load the invalid number message into r0
    BL printf                                   @ Printf the invalid number message

@ Exit the program
exit:
    POP {ip, lr}                                @ Pop these two back out

    MOV r7, #SYS_EXIT                           @ Set the exit syscall
    MOV r0, #0x0                                @ Exit code 0
    SVC 0                                       @ Return, have a nice day :)
