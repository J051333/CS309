.section .text

.global main
main:
	MOV r8, #0x0
	B loop

loop:
	CMP r8, #0xA
	BEQ end
	ADD r8, r8, #0x01
	PUSH {r8} @ Save r8
	BL hello
	POP {r8} @ Restore r8
	BL loop

end: 
	MOV r7, #0x01
	MOV r0, #0x0
	SVC #0x0

hello:
	MOV r7, #0x04
	MOV r0, #0x01
	MOV r2, #0x0C
	LDR r1, =string1
	SVC #0x0
	MOV PC, LR

.section .data
.balign 4
string1: .asciz "Hello World\n" @Length is 12
