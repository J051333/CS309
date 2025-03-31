.global _start

.section .text

_start:

	#print message
	mov r7, #0x4
	mov r0, #1
	ldr r1, =message
	mov r2, #8
	swi 0

	# exit
	mov r7, #0x1
	mov r0, #1
	swi 0


.section .data
	message:
	.ascii "HIIIIII\n"
