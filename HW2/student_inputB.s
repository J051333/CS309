@ HW 2 for CS 309-01
@ Team members:
@ - Coen McDonald
@ - Josi Whitlock
@ - John Raburn
@ - Jonathan Poling
@ - Patrick McCaulley
@ - Grace Dobbs

.global main

main:
    mov r4, #1                @ Initialize counter to 1
    ldr r0, =strInputPrompt
    bl printf

loop:
    @ Print current count
    ldr r0, =strCount
    mov r1, r4
    bl printf

    add r4, r4, #1            @ Increment counter
    cmp r4, #11               @ Check if counter > 10
    blt loop                  @ If not, continue loop

    @ Print "happily finished"
    ldr r0, =strFinished
    bl printf

    @ Exit the program
    mov r7, #0x01
    svc 0

.data
.balign 4
strInputPrompt: .asciz "Starting count from 1 to 10...\n"
strCount: .asciz "Count: %d\n"
strFinished: .asciz "happily finished\n"

.global printf
