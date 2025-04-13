@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@ File:    lab5.s
@ Author:  Josi Whitlock
@ Purpose: A fun little board cutting program.
@
@ Use these commands to assemble, link, run and debug the program:
@     as -o lab5.o lab5.s -g
@     gcc -o lab5 lab5.o
@     ./lab5
@     gdb --args ./lab5
@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


@ Use c's printf
.extern printf

@ Constants
                    .equ SYS_EXIT, 1
                    .equ SYS_READ, 3
                    .equ SYS_WRITE, 4
                    .equ STDIN, 0

                    .equ INPUT_BUFFER_SIZE, 12
                    .equ STARTING_INCHES, 144
                    .equ INCHES_IN_FOOT, 12

                    .equ MIN_LEN, 6
                    .equ MAX_LEN, 144

@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.section .data                                  @ Data section for strings and vars

title:              .asciz "Cut-It-Up Saw\n"
boards_so_far:      .asciz "Boards cut so far: %d\n"
length_so_far:      .asciz "Linear length of the boards cut so far: %d inches\n"
invalid_num_msg:    .asciz "Sorry, that's not a valid number.\n"
number:             .asciz "%d\n"
cur_lengths:        .asciz "Current Board Lengths:\n"
cur_one:            .asciz "One:\t%d.\n"
cur_two:            .asciz "Two:\t%d.\n"
cur_three:          .asciz "Three:\t%d.\n"
you_entered_msg:    .asciz "You entered %d.\n"
enter_len:          .asciz "Enter the length of board to cut in inches (at least 6 and no more than 144):\n"
cut_fail:           .asciz "Not enough inventory to perform cut. Enter new smaller length.\n"
waste_msg:          .asciz "Inventory levels have dropped below minimum levels and will now terminate.\nWaste is %d inches.\n"

@ Lengths
one_total:          .word 0                     @ Inches left on one
two_total:          .word 0                     @ Inches left on two
three_total:        .word 0                     @ Inches left on three
total_boards:       .word 0                     @ Number of boards cut off of the initial boards
total_length:       .word 0                     @ Length cut off boards in inches so far

@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.section .bss                                   @ BSS to use less storage
.lcomm user_input, INPUT_BUFFER_SIZE            @ Reserve bytes for input

@ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.section .text
.global main

@ Entry point
main:
    @ Prologue
    PUSH {ip, lr}                               @ Push lr and ip to keep the stack 8b aligned

    @ Init lengths
    LDR r0, =one_total
    MOV r1, #STARTING_INCHES
    STR r1, [r0]                                @ Store 144 in the total

    LDR r0, =two_total
    STR r1, [r0]                                @ Store 144 in the total

    LDR r0, =three_total
    STR r1, [r0]                                @ Store 144 in the total

    LDR r0, =total_boards
    MOV r1, #0
    STR r1, [r0]                                @ Set board total to 0

    LDR r0, =total_length
    STR r1, [r0]                                @ Set total length to 0

    @ Say Hi
    LDR r0, =title                              @ Load the print into r0
    BL printf                                   @ Print the prompt

main_loop:

    @ Print the boards so far
    LDR r0, =boards_so_far                      @ Load the print into r0
    LDR r1, =total_boards
    LDR r1, [r1]
    BL printf                                   @ Print the prompt
 
    @ Print the length so far
    LDR r0, =length_so_far                      @ Load the print into r0
    LDR r1, =total_length
    LDR r1, [r1]
    BL printf                                   @ Print the prompt

    @ Print the current lengths of the boards
    LDR r0, =cur_lengths                        @ Load the print into r0
    BL printf                                   @ Print the prompt

    @ Print one
    LDR r0, =cur_one                            @ Load the print into r0
    LDR r1, =one_total
    LDR r1, [r1]
    BL printf                                   @ Print the prompt

    @ Print two
    LDR r0, =cur_two                            @ Load the print into r0
    LDR r1, =two_total
    LDR r1, [r1]
    BL printf                                   @ Print the prompt

    @ Print three
    LDR r0, =cur_three                          @ Load the print into r0
    LDR r1, =three_total
    LDR r1, [r1]
    BL printf                                   @ Print the prompt


    @ Prompt user for input
    LDR r0, =enter_len
    BL printf

    @ Take their input
    BL read                                     @ Read into user_input

    @ Convert Input to an int
    LDR r0, =user_input
    BL atoi

    @ r0 now contains the input

    @ Make sure the int is within the bounds
    MOV r5, r0                                  @ Store r0
    BL validate_int

    @ If the input wasnt valid, restart loop
    CMP r0, #0 
    BEQ invalid_input

    @ Commence cutting
    MOV r0, r5                                  @ Restore r0
    BL try_cut

    @ Check length
    BL check_lengths
    CMP r0, #0                                  @ Check if we can continue
    BEQ finish                                  @ If we can't, branch to finish

    B main_loop                                 @ Next iteration

@ Inform the user that the input was invalid 
@ and start the next branch iteration
invalid_input:
    LDR r0, =invalid_num_msg
    BL printf                                   @ Print the invalid-number message
    B main_loop                                 @ Loop around again

@ Check if the lengths are still all big enough for another cut
@ Input: none
@ Output: r0 = (0 or 1) Whether or not execution can continue
check_lengths:
    MOV r1, #0                                  @ Default to can't continue

    LDR r0, =one_total
    LDR r0, [r0]
    CMP r0, #MIN_LEN                            @ Check board one
    MOVGT r1, #1                                @ If big enough, set r1 to 1
    BGT check_lengths_end                       @ Branch to return

    LDR r0, =two_total
    LDR r0, [r0]
    CMP r0, #MIN_LEN                            @ Check board two
    MOVGT r1, #1                                @ If big enough, set r1 to 1
    BGT check_lengths_end                       @ Branch to return

    LDR r0, =three_total
    LDR r0, [r0]
    CMP r0, #MIN_LEN                            @ Check board three
    MOVGT r1, #1                                @ If big enough, set r1 to 1
    BGT check_lengths_end                       @ Branch to return

@ Return from check_lengths
check_lengths_end:
    MOV r0, r1
    @ Return
    BX lr

@ Try to cut boards
@ Input: r0 = Integer to cut
@ Output: prints output
try_cut:
    PUSH {ip, lr}

    @ Check one
    LDR r1, =one_total
    LDR r1, [r1]                                @ Load the value of board one

    CMP r0, r1
    BGT try_two                                 @ One is too short, try two

    @ Cut
    LDR r1, =one_total
    BL cut                                      @ Cut the board
    B try_cut_end

try_two:
    @ Check two
    LDR r1, =two_total
    LDR r1, [r1]                                @ Load the value of board two

    CMP r0, r1
    BGT try_three                               @ Two is too short, try three

    @ Cut
    LDR r1, =two_total
    BL cut                                      @ Cut the board
    B try_cut_end

try_three:
    @ Check three
    LDR r1, =three_total
    LDR r1, [r1]                                @ Load the value of board three

    CMP r0, r1
    BGT try_cut_fail                            @ Three is too short, fail

    @ Cut
    LDR r1, =three_total
    BL cut                                      @ Cut the board
    B try_cut_end

try_cut_fail:
    LDR r0, =cut_fail
    BL printf

try_cut_end:
    POP {ip, lr}
    BX lr                                       @ Return

@ Performs the cutting operation
@ Input: r0 = amount to cut, r1 = reference to board to cut
cut:
    PUSH {r5, r6, ip, lr}

    MOV r5, r1
    LDR r5, [r5]                                @ Length of board

    @ Remove the cut from the board
    SUB r5, r5, r0                              @ Remove the specified amount from the board
    STR r5, [r1]                                @ Store the new value back in the board length

    @ Add the used length to the total length
    LDR r6, =total_length
    LDR r5, [r6]
    ADD r5, r0, r5                              @ r5 = r0 + r5
    STR r5, [r6]

    @ Add one to the total cuts performed
    LDR r6, =total_boards
    LDR r5, [r6]
    ADD r5, r5, #1                              @ r5 = r5 + 1
    STR r5, [r6]

    @ Restore registers and return to sender
    POP {r5, r6, ip, lr}
    BX lr                                       @ Return


@ Ensure an integer falls between 6 and 144
@ Input: r0 = Integer to validate
@ Output: r0 = (0 or 1) if valid
validate_int:
    MOV r1, #1                                  @ Default the validation to true

    CMP r0, #6                                  @ Compare the int to 0
    MOVLT r1, #0                                @ If less than 1, invalidate
    CMP r0, #144                                @ Compare the int to 100
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

    MUL r0, r0, r2 @ Multiply current total by 10

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
    B exit

finish:
    MOV r1, #0                                  @ Init waste to 0

    LDR r0, =one_total
    LDR r0, [r0]
    ADD r1, r1, r0                              @ Add leftover of board one

    LDR r0, =two_total
    LDR r0, [r0]
    ADD r1, r1, r0                              @ Add leftover of board two

    LDR r0, =three_total
    LDR r0, [r0]
    ADD r1, r1, r0                              @ Add leftover of board three

    LDR r0, =waste_msg
    BL printf                                   @ Print the waste message

@ Exit the program
exit:
    POP {ip, lr}                                @ Pop these two back out

    MOV r7, #SYS_EXIT                           @ Set the exit syscall
    MOV r0, #0x0                                @ Exit code 0
    SVC 0                                       @ Return, have a nice day :)
