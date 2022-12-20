BITS 64
global _start

%include "../common.asm"

section .text

_start:
	mov rdi, [p1input]
	call read_input_file

	sub rsp, 0x40
	mov QWORD [rsp + 0x30], 0               ; 0x30 priority sum
	                                        ; 0x28 second mask
	                                        ; 0x20 first mask
	                                        ; 0x18 second index
	                                        ; 0x10 first index
	mov r12, QWORD [input_file_buffer_size]
	mov QWORD [rsp + 0x8], r12              ; 0x8 input file buffer_size
	mov QWORD [rsp + 0x0], 26               ; 0x0 constant 26

	mov rbp, input_file_buffer
	mov rbx, 0
	line_loop:
	cmp rbx, QWORD [rsp + 0x8]
	jae line_loop_end

	mov r14, rbx
	xor r15, r15
	lookahead:
	cmp rbx, QWORD [rsp + 0x8]
	jae line_loop_end
	; 41-5A, 61-7A
	; 01|0|00001-01|0|11010
	; 01|1|00001-01|1|11010
	movzx r12, BYTE [rbp + rbx]
	mov r13, r12
	and r13, 0x1F
	dec r13
	cmp r13, 0x1A
	setb r13b
	shr r12, 6
	add r12, r13
	cmp r12, 2
	jne lookahead_end
	inc r15
	inc rbx
	jmp lookahead
	lookahead_end:

	shr r15, 1
	add r15, r14 ; halfway point
	mov QWORD [rsp + 0x10], r14
	mov QWORD [rsp + 0x18], r15
	mov QWORD [rsp + 0x20], 0
	mov QWORD [rsp + 0x28], 0
	mask_loop:
	mov r14, QWORD [rsp + 0x18]
	cmp r14, rbx
	jae mask_loop_end

	movzx r12, BYTE [rbp + r14]
	xor r13, r13
	cmp r12, 0x61
	cmovb r13, QWORD [rsp + 0]
	and r12, 0x1F
	dec r12
	add r12b, r13b
	mov r13, 1
	mov cl, r12b
	shl r13, cl
	mov r12, QWORD [rsp + 0x28]
	or r12, r13
	mov QWORD [rsp + 0x28], r12

	inc r14
	mov QWORD [rsp + 0x18], r14

	mov r14, QWORD [rsp + 0x10]
	movzx r12, BYTE [rbp + r14]
	xor r13, r13
	cmp r12, 0x61
	cmovb r13, QWORD [rsp + 0]
	and r12, 0x1F
	dec r12
	add r12b, r13b
	mov r13, 1
	mov cl, r12b
	shl r13, cl
	mov r12, QWORD [rsp + 0x20]
	or r12, r13
	mov QWORD [rsp + 0x20], r12

	inc r14
	mov QWORD [rsp + 0x10], r14
	jmp mask_loop
	mask_loop_end:

	mov r12, QWORD [rsp + 0x20]
	mov r13, QWORD [rsp + 0x28]
	and r12, r13
	bsf r12, r12
	inc r12
	mov r13, QWORD [rsp + 0x30]
	add r13, r12
	mov QWORD [rsp + 0x30], r13

	eat_whitespace:
	cmp rbx, QWORD [rsp + 0x8]
	jae line_loop_end
	xor r14, r14
	movzx r15, BYTE [rbp + rbx]
	sub r15, 0x9               ; map ['\t','\r'], which is [0x9,0xD], to [0x0,0x4], this makes the first 5 nonnegative values all whitespace
	cmp r15, 0x5
	setb r14b
	cmp r15, 0x17              ; ' ', which is 0x20, sub 0x9 is 0x17
	sete r15b
	or r14b, r15b
	cmp r14, 0
	je eat_whitespace_end
	inc rbx
	jmp eat_whitespace
	eat_whitespace_end:
	jmp line_loop
	line_loop_end:

	mov rdi, part_1_colon
	call print
	mov rdi, QWORD [rsp + 0x30]
	call print_u64
	mov rdi, newline_part_2_colon
	call print
	mov rdi, -1
	call print_u64
	mov rdi, newline
	call print

	add rsp, 0x40

	mov rax, 60     ; sys_exit
	mov rdi, 0      ; exit code
	syscall

section .data
	p1in:         db "./p1in.txt",0
	p1in_example: db "./p1in_example.txt",0
	p1input:      dq p1in

	part_1_colon:           db "Part 1: ",0
	newline_part_2_colon:   db 0x0A,"Part 2: ",0
	newline:                db 0x0A,0
section .bss
	scoreboard: resb 8
